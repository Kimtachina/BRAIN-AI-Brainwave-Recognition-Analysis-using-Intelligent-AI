-- =========================================================================
-- 015: ปิด "Allow all" แล้วให้แต่ละคนเข้าถึงได้เฉพาะข้อมูลของตัวเอง
-- =========================================================================
-- เดิมทุกตารางเปิดให้ anon key อ่าน/แก้/ลบได้ทุกแถว ซึ่ง key นี้ฝังอยู่ในเว็บให้ทุกคนเห็น
-- หลังรันไฟล์นี้:
--   - ต้องล็อกอินผ่าน Supabase Auth ก่อน ถึงจะเข้าถึงข้อมูลได้
--   - เห็นและแก้ได้เฉพาะแถวที่ user_id เป็นของตัวเอง (users.auth_user_id = auth.uid())
--   - knowledge_base อ่านได้ทุกคน ผู้ที่ล็อกอินแก้ได้เฉพาะคอลัมน์ embedding
--   - สมัครสมาชิกแล้ว trigger สร้างแถวใน users + user_settings ให้เอง
--     (ทำงานได้แม้ยังไม่มี session ตอนเปิดยืนยันอีเมล)
-- รันซ้ำได้
-- =========================================================================


-- -------------------------------------------------------------------------
-- 1. ฟังก์ชันหา users.id ของคนที่ล็อกอินอยู่
--    อยู่ใน schema private ซึ่งไม่เปิดผ่าน API และเป็น SECURITY DEFINER
--    เพื่อให้ policy ของตารางอื่นเรียกได้โดยไม่ติด RLS ของตาราง users
-- -------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE OR REPLACE FUNCTION private.current_app_user_id()
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id FROM public.users WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

REVOKE ALL ON FUNCTION private.current_app_user_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.current_app_user_id() TO authenticated;


-- -------------------------------------------------------------------------
-- 2. สร้างแถว users + user_settings อัตโนมัติเมื่อสมัครสมาชิก
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    meta JSONB := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
    v_birth DATE;
    v_user_id INTEGER;
BEGIN
    BEGIN
        v_birth := NULLIF(meta->>'birth_date', '')::DATE;
    EXCEPTION WHEN OTHERS THEN
        v_birth := NULL;
    END;

    INSERT INTO public.users (
        username, email, full_name, phone, birth_date, avatar_url,
        auth_user_id, auth_provider, email_verified
    )
    VALUES (
        COALESCE(NULLIF(split_part(NEW.email, '@', 1), ''), 'user'),
        NEW.email,
        COALESCE(meta->>'full_name', meta->>'name'),
        NULLIF(meta->>'phone', ''),
        v_birth,
        meta->>'avatar_url',
        NEW.id,
        COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
        NEW.email_confirmed_at IS NOT NULL
    )
    -- อีเมลซ้ำกับแถวเดิมที่ยังไม่ผูกบัญชี: ผูกให้แทนการสร้างใหม่
    ON CONFLICT (email) DO UPDATE
        SET auth_user_id = EXCLUDED.auth_user_id,
            auth_provider = EXCLUDED.auth_provider
        WHERE public.users.auth_user_id IS NULL
    RETURNING id INTO v_user_id;

    IF v_user_id IS NOT NULL THEN
        INSERT INTO public.user_settings (user_id) VALUES (v_user_id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- ห้ามทำให้การสมัครสมาชิกล้ม แอปจะสร้างแถวให้อีกครั้งตอนล็อกอินครั้งแรก
    RAISE WARNING 'handle_new_auth_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION private.handle_new_auth_user();


-- -------------------------------------------------------------------------
-- 3. ลบ policy เดิมทั้งหมดในตารางของแอป
-- -------------------------------------------------------------------------
DO $$
DECLARE
    p RECORD;
BEGIN
    FOR p IN
        SELECT policyname, tablename FROM pg_policies
        WHERE schemaname = 'public' AND tablename IN (
            'users', 'user_settings', 'test_results', 'activities', 'chat_messages',
            'knowledge_base', 'voice_metadata', 'emergency_contacts', 'elderly_profiles',
            'conversations', 'retrieval_logs', 'eeg_devices', 'eeg_sessions',
            'emotion_logs', 'emotion_sessions', 'eeg_assessment_reports'
        )
    LOOP
        EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
    END LOOP;
END $$;


-- -------------------------------------------------------------------------
-- 4. policy ใหม่
-- -------------------------------------------------------------------------

-- users: แถวของตัวเองเท่านั้น
CREATE POLICY "Own row" ON public.users
    FOR ALL TO authenticated
    USING (auth_user_id = (SELECT auth.uid()))
    WITH CHECK (auth_user_id = (SELECT auth.uid()));

-- ตารางที่มีคอลัมน์ user_id
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'user_settings', 'test_results', 'activities', 'chat_messages',
        'emergency_contacts', 'elderly_profiles', 'conversations', 'eeg_devices',
        'eeg_sessions', 'emotion_logs', 'emotion_sessions', 'eeg_assessment_reports'
    ]
    LOOP
        EXECUTE format(
            'CREATE POLICY "Own rows" ON public.%I FOR ALL TO authenticated '
            'USING (user_id = (SELECT private.current_app_user_id())) '
            'WITH CHECK (user_id = (SELECT private.current_app_user_id()))',
            tbl
        );
    END LOOP;
END $$;

-- ตารางที่ผูกกับข้อความแชท (ไม่มี user_id โดยตรง)
CREATE POLICY "Own chat messages" ON public.voice_metadata
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.chat_messages m
        WHERE m.id = message_id AND m.user_id = (SELECT private.current_app_user_id())
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.chat_messages m
        WHERE m.id = message_id AND m.user_id = (SELECT private.current_app_user_id())
    ));

CREATE POLICY "Own chat messages" ON public.retrieval_logs
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.chat_messages m
        WHERE m.id = message_id AND m.user_id = (SELECT private.current_app_user_id())
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.chat_messages m
        WHERE m.id = message_id AND m.user_id = (SELECT private.current_app_user_id())
    ));

-- knowledge_base: อ่านได้ทุกคน, ผู้ล็อกอินอัปเดตได้ (จำกัดคอลัมน์ด้วย GRANT ด้านล่าง)
CREATE POLICY "Public read" ON public.knowledge_base
    FOR SELECT TO anon, authenticated
    USING (true);

CREATE POLICY "Logged-in users update embeddings" ON public.knowledge_base
    FOR UPDATE TO authenticated
    USING (true) WITH CHECK (true);


-- -------------------------------------------------------------------------
-- 5. สิทธิ์ระดับตาราง: anon อ่านได้แค่ knowledge_base
-- -------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
GRANT SELECT ON public.knowledge_base TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- knowledge_base: ผู้ล็อกอินแก้ได้เฉพาะ embedding (เนื้อหาความรู้แก้ไม่ได้)
REVOKE INSERT, UPDATE, DELETE ON public.knowledge_base FROM authenticated;
GRANT UPDATE (embedding) ON public.knowledge_base TO authenticated;

-- get_user_context ใช้ได้เฉพาะผู้ล็อกอิน (ฟังก์ชันรันด้วยสิทธิ์ผู้เรียก จึงเห็นแค่ข้อมูลตัวเอง)
REVOKE EXECUTE ON FUNCTION public.get_user_context(INT, INT) FROM anon;

-- rls_auto_enable() เป็นฟังก์ชัน SECURITY DEFINER ของ Supabase ไม่ใช่ของแอป
-- Postgres ให้สิทธิ์ EXECUTE กับ PUBLIC เป็นค่าเริ่มต้น จึงต้องถอนจาก PUBLIC ด้วย
DO $$
BEGIN
    IF to_regprocedure('public.rls_auto_enable()') IS NOT NULL THEN
        REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
    END IF;
END $$;


-- -------------------------------------------------------------------------
-- 6. Storage: รูปโปรไฟล์
--    ดูได้ทุกคน (bucket เป็น public), อัปโหลด/แก้/ลบได้เฉพาะไฟล์ของตัวเอง
--    ชื่อไฟล์ที่แอปใช้: profiles/user_<users.id>_<เวลา>.<นามสกุล>
-- -------------------------------------------------------------------------
DROP POLICY IF EXISTS "Anyone can upload an avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own avatar" ON storage.objects;

CREATE POLICY "Users upload own avatar" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND name LIKE 'profiles/user\_' || (SELECT private.current_app_user_id()) || '\_%'
    );

CREATE POLICY "Users update own avatar" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'avatars'
        AND name LIKE 'profiles/user\_' || (SELECT private.current_app_user_id()) || '\_%'
    );

CREATE POLICY "Users delete own avatar" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'avatars'
        AND name LIKE 'profiles/user\_' || (SELECT private.current_app_user_id()) || '\_%'
    );

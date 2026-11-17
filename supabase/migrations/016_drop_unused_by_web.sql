    -- ลบสิ่งที่หน้าเว็บไม่ได้ใช้แล้ว (2026-11-17)
    -- ตารางลูกทั้งหมดผูก ON DELETE CASCADE กับ users

    -- 1) ข้อมูลผู้ใช้สำหรับผู้ช่วย AI: อ่านดัชนีคลื่นสมองจาก eeg_assessment_reports แทน emotion_sessions
    CREATE OR REPLACE FUNCTION public.get_user_context(p_user_id integer, context_limit integer DEFAULT 5)
    RETURNS TABLE(topic character varying, summary text, brainwave_avg jsonb, stress_level character varying, recent_activities text[])
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $function$
    BEGIN
        RETURN QUERY
        SELECT
            'user_profile'::VARCHAR(255) AS topic,
            'Profile and health data'::TEXT AS summary,
            (
                SELECT CASE WHEN COUNT(*) = 0 THEN NULL
                ELSE jsonb_build_object('eeg_index', AVG(r.eeg_index), 'reports', COUNT(*))
                END
                FROM eeg_assessment_reports r
                WHERE r.user_id = p_user_id
                AND r.recorded_at > NOW() - INTERVAL '7 days'
            ) AS brainwave_avg,
            (
                SELECT tr.stress_level
                FROM test_results tr
                WHERE tr.user_id = p_user_id
                ORDER BY tr.test_date DESC
                LIMIT 1
            ) AS stress_level,
            (
                SELECT COALESCE(array_agg(a.activity_name::TEXT), ARRAY[]::TEXT[])
                FROM (
                    SELECT activity_name
                    FROM activities
                    WHERE user_id = p_user_id
                    ORDER BY completed_at DESC
                    LIMIT context_limit
                ) a
            ) AS recent_activities
        FROM users u
        WHERE u.id = p_user_id;
    END;
    $function$;

    -- 2) ตารางที่ไม่มีหน้าไหนเขียนหรืออ่านแล้ว
    DROP TABLE IF EXISTS public.emotion_sessions;
    DROP TABLE IF EXISTS public.emotion_logs;

    -- 3) ฟังก์ชันค้นหาที่แอปไม่ได้เรียก (แอปใช้ search_knowledge)
    DROP FUNCTION IF EXISTS public.hybrid_search(vector, text, integer, double precision, double precision);

    -- 4) คอลัมน์การตั้งค่าที่ไม่มีหน้าใช้ (เหลือ daily_reminder, weekly_report, stress_alert)
    ALTER TABLE public.user_settings
        DROP COLUMN IF EXISTS reminder_time,
        DROP COLUMN IF EXISTS dark_mode,
        DROP COLUMN IF EXISTS language,
        DROP COLUMN IF EXISTS notification_prefer,
        DROP COLUMN IF EXISTS sensitivity_level,
        DROP COLUMN IF EXISTS stress_threshold,
        DROP COLUMN IF EXISTS critical_fft,
        DROP COLUMN IF EXISTS brain_mode,
        DROP COLUMN IF EXISTS font_size;

    -- 5) แถวผู้ใช้เก่าที่ไม่ผูกกับบัญชีล็อกอิน (Supabase Auth) แล้ว
    DELETE FROM public.users WHERE auth_user_id IS NULL;

    -- 6) รหัสผ่านอยู่ใน Supabase Auth แล้ว ชื่อใช้ full_name ช่องเดียว
    ALTER TABLE public.users
        DROP COLUMN IF EXISTS password,
        DROP COLUMN IF EXISTS first_name,
        DROP COLUMN IF EXISTS last_name;

-- =========================================================================
-- SmartBrain Care: ตั้งค่าฐานข้อมูลสำหรับโปรเจกต์ Supabase ใหม่ (ไฟล์เดียวจบ)
-- =========================================================================
-- รวม migration 001–014 ให้อยู่ในสภาพสุดท้าย แล้ววางรันใน SQL Editor ครั้งเดียว
-- รันซ้ำได้ ไม่ error และไม่ใส่ข้อมูลความรู้ซ้ำ
--
-- ต่างจากการรัน migration ทีละไฟล์ตรงที่:
--   - ไม่สร้างตารางที่ถูกลบไปแล้ว: schedules, brainwave_data, chat_context, user_knowledge
--   - ข้ามไฟล์ซ่อมบำรุง (003/004 resequence, 004 reset) เพราะฐานข้อมูลใหม่ไม่ต้องใช้
--   - users: เพิ่ม auth_user_id / auth_provider / email_verified ที่โค้ด auth_service ใช้,
--     password เป็น NULL ได้ (ผู้ใช้ Supabase Auth ไม่มีรหัสผ่านในตารางนี้),
--     username ไม่บังคับไม่ซ้ำ (สร้างจากส่วนหน้า @ ของอีเมล จึงชนกันได้)
--   - get_user_context(): เดิมอ่าน brainwave_data ที่ถูกลบแล้วจึงพัง เปลี่ยนไปอ่าน
--     emotion_sessions + eeg_sessions แทน
--   - ดัชนีเวกเตอร์ใช้ HNSW แทน ivfflat (ivfflat lists=100 กับข้อมูลไม่กี่สิบแถวค้นหาแทบไม่เจอ)
--   - knowledge_base.title ไม่ซ้ำ เพื่อให้รันซ้ำแล้วข้อมูลไม่เบิ้ล
-- =========================================================================


-- =========================================================================
-- 0. EXTENSIONS + ฟังก์ชันกลาง
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


-- =========================================================================
-- 1. USERS - ข้อมูลผู้ใช้
-- =========================================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255),
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    birth_date DATE,
    avatar_url VARCHAR(500),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    auth_user_id UUID UNIQUE,                  -- id จาก Supabase Auth (auth.users.id)
    auth_provider VARCHAR(50) DEFAULT 'email', -- email
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

COMMENT ON TABLE users IS 'ตารางเก็บข้อมูลผู้ใช้งาน';
COMMENT ON COLUMN users.role IS 'บทบาทผู้ใช้: user, admin, caretaker';
COMMENT ON COLUMN users.is_active IS 'สถานะการใช้งาน';
COMMENT ON COLUMN users.auth_user_id IS 'ผูกกับ auth.users.id ของ Supabase Auth';


-- =========================================================================
-- 2. USER SETTINGS - การตั้งค่าผู้ใช้
-- =========================================================================
CREATE TABLE IF NOT EXISTS user_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    daily_reminder BOOLEAN DEFAULT TRUE,
    weekly_report BOOLEAN DEFAULT TRUE,
    stress_alert BOOLEAN DEFAULT TRUE,
    reminder_time TIME DEFAULT '09:00:00',
    dark_mode BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'th',
    notification_prefer VARCHAR(100) DEFAULT 'all',
    sensitivity_level VARCHAR(50) DEFAULT 'medium',
    stress_threshold VARCHAR(100) DEFAULT 'moderate',
    critical_fft INTEGER DEFAULT 0,
    brain_mode VARCHAR(50) DEFAULT 'normal',
    font_size INTEGER DEFAULT 16,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_settings IS 'ตารางเก็บการตั้งค่าของผู้ใช้';
COMMENT ON COLUMN user_settings.sensitivity_level IS 'ระดับความไว: low, medium, high';
COMMENT ON COLUMN user_settings.brain_mode IS 'โหมดสมอง: normal, focus, relax, sleep';


-- =========================================================================
-- 3. TEST RESULTS - ผลการทดสอบความเครียด
-- =========================================================================
CREATE TABLE IF NOT EXISTS test_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stress_score INTEGER DEFAULT 0,
    depression_score INTEGER DEFAULT 0,
    stress_level VARCHAR(50) DEFAULT 'normal', -- normal, mild, moderate, severe
    assessment TEXT,
    test_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_test_results_user_id ON test_results(user_id);
CREATE INDEX IF NOT EXISTS idx_test_results_test_date ON test_results(test_date DESC);

COMMENT ON TABLE test_results IS 'ตารางเก็บผลการทดสอบความเครียดและซึมเศร้า';


-- =========================================================================
-- 4. ACTIVITIES - กิจกรรม
-- =========================================================================
CREATE TABLE IF NOT EXISTS activities (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50),
    activity_name VARCHAR(255),
    score INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 0,
    is_auto_tracked BOOLEAN DEFAULT FALSE,
    note_info TEXT,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_completed_at ON activities(completed_at DESC);

COMMENT ON TABLE activities IS 'ตารางเก็บกิจกรรมที่ผู้ใช้ทำ เช่น สมาธิ, หายใจ, เกม';


-- =========================================================================
-- 5. CHAT MESSAGES - ประวัติแชท AI
-- =========================================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT,
    is_bot BOOLEAN DEFAULT FALSE,
    sender_role VARCHAR(50) DEFAULT 'user',
    received_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sent_at ON chat_messages(sent_at);

COMMENT ON TABLE chat_messages IS 'ตารางเก็บประวัติการสนทนากับ AI';


-- =========================================================================
-- 6. KNOWLEDGE BASE - ฐานความรู้ RAG
-- =========================================================================
CREATE TABLE IF NOT EXISTS knowledge_base (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL UNIQUE,
    content TEXT NOT NULL,
    category VARCHAR(100) DEFAULT 'general', -- brainwave, mental_health, meditation, sleep, device, emergency, general
    tags TEXT[],
    embedding extensions.vector(1536),       -- OpenAI text-embedding-3-small
    metadata JSONB DEFAULT '{}',
    importance INTEGER DEFAULT 0,
    has_solution BOOLEAN DEFAULT FALSE,
    added_manual TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_embedding ON knowledge_base
    USING hnsw (embedding extensions.vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_content ON knowledge_base
    USING gin (to_tsvector('simple', content));

COMMENT ON TABLE knowledge_base IS 'ฐานความรู้สำหรับ RAG - เก็บข้อมูลความรู้พร้อม embeddings';


-- =========================================================================
-- 7. VOICE METADATA - ข้อมูลการวิเคราะห์เสียง
-- =========================================================================
CREATE TABLE IF NOT EXISTS voice_metadata (
    voice_id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES chat_messages(id) ON DELETE CASCADE,
    detected_language VARCHAR(50) DEFAULT 'th',
    duration_seconds REAL DEFAULT 0,
    audio_file_url VARCHAR(500),
    content_text TEXT,
    sender_type VARCHAR(50) DEFAULT 'user',
    sentiment_score REAL DEFAULT 0,
    stress_index REAL DEFAULT 0,
    pitch_avg REAL,
    volume_avg REAL,
    speech_rate REAL,
    emotion_detected VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_voice_metadata_message_id ON voice_metadata(message_id);
CREATE INDEX IF NOT EXISTS idx_voice_metadata_created_at ON voice_metadata(created_at DESC);

COMMENT ON TABLE voice_metadata IS 'ข้อมูล metadata จากการวิเคราะห์เสียงพูด';


-- =========================================================================
-- 8. EMERGENCY CONTACTS - ผู้ติดต่อฉุกเฉิน
-- =========================================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
    contact_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100),
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    notify_on_emergency BOOLEAN DEFAULT TRUE,
    notify_on_high_stress BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);

COMMENT ON TABLE emergency_contacts IS 'ผู้ติดต่อฉุกเฉินของผู้ใช้';


-- =========================================================================
-- 9. ELDERLY PROFILES - ข้อมูลผู้สูงอายุ
-- =========================================================================
CREATE TABLE IF NOT EXISTS elderly_profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    nick_name VARCHAR(100),
    age INTEGER,
    date_of_birth DATE,
    gender VARCHAR(20),
    blood_type VARCHAR(5),
    height_cm REAL,
    weight_kg REAL,
    medical_conditions TEXT[],
    allergies TEXT[],
    current_medications TEXT[],
    mobility_status VARCHAR(100),
    cognitive_status VARCHAR(100),
    doctor_name VARCHAR(255),
    doctor_phone VARCHAR(20),
    hospital_name VARCHAR(255),
    insurance_info TEXT,
    special_needs TEXT,
    relationship VARCHAR(100),
    emergency_contact VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE elderly_profiles IS 'ข้อมูลสุขภาพและรายละเอียดผู้สูงอายุ';


-- =========================================================================
-- 10. CONVERSATIONS - Session การสนทนา
-- =========================================================================
CREATE TABLE IF NOT EXISTS conversations (
    conversation_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    topic_summary TEXT,
    sentiment_avg REAL,
    is_active BOOLEAN DEFAULT TRUE,
    message_count INTEGER DEFAULT 0,
    enable_ai BOOLEAN DEFAULT TRUE,
    end_conversation_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_is_active ON conversations(is_active);

COMMENT ON TABLE conversations IS 'Session การสนทนากับ AI';


-- =========================================================================
-- 11. RETRIEVAL LOGS - บันทึกการดึงข้อมูล RAG
-- =========================================================================
CREATE TABLE IF NOT EXISTS retrieval_logs (
    log_id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES chat_messages(id) ON DELETE CASCADE,
    knowledge_id INTEGER REFERENCES knowledge_base(id) ON DELETE SET NULL,
    query_text TEXT,
    similarity_score REAL,
    rank_order INTEGER,
    was_used BOOLEAN DEFAULT FALSE,
    search_method VARCHAR(50) DEFAULT 'vector',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_retrieval_logs_message_id ON retrieval_logs(message_id);
CREATE INDEX IF NOT EXISTS idx_retrieval_logs_knowledge_id ON retrieval_logs(knowledge_id);

COMMENT ON TABLE retrieval_logs IS 'บันทึกการดึงข้อมูลจาก Knowledge Base (RAG)';


-- =========================================================================
-- 12. EEG DEVICES - อุปกรณ์ EEG
-- =========================================================================
CREATE TABLE IF NOT EXISTS eeg_devices (
    device_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    device_name VARCHAR(100) NOT NULL,
    model_name VARCHAR(100),
    serial_number VARCHAR(100) UNIQUE,
    mac_address VARCHAR(50),
    firmware_version VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active',
    is_connected BOOLEAN DEFAULT FALSE,
    last_connected_at TIMESTAMP WITH TIME ZONE,
    battery_level INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eeg_devices_user_id ON eeg_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_eeg_devices_status ON eeg_devices(status);

COMMENT ON TABLE eeg_devices IS 'อุปกรณ์ EEG ที่ลงทะเบียน';


-- =========================================================================
-- 13. EEG SESSIONS - Session การวัดคลื่นสมอง
-- =========================================================================
CREATE TABLE IF NOT EXISTS eeg_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INTEGER REFERENCES eeg_devices(device_id) ON DELETE SET NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    avg_attention_score REAL,
    avg_relaxation_score REAL,
    avg_stress_score REAL,
    data_quality_grade VARCHAR(10),
    session_type VARCHAR(50) DEFAULT 'general',
    status VARCHAR(50) DEFAULT 'active',
    attention_level INTEGER DEFAULT 0,
    alpha_wave REAL DEFAULT 0,
    focus_recommendation TEXT,
    stress_score REAL DEFAULT 0,
    delta_calculated REAL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eeg_sessions_user_id ON eeg_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_eeg_sessions_device_id ON eeg_sessions(device_id);
CREATE INDEX IF NOT EXISTS idx_eeg_sessions_started_at ON eeg_sessions(started_at DESC);

COMMENT ON TABLE eeg_sessions IS 'Session การวัดคลื่นสมอง';
COMMENT ON COLUMN eeg_sessions.focus_recommendation IS 'คำแนะนำเกี่ยวกับสมาธิ';


-- =========================================================================
-- 14. EMOTION LOGS - บันทึกอารมณ์
-- =========================================================================
CREATE TABLE IF NOT EXISTS emotion_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emotion_type VARCHAR(100) NOT NULL,
    trigger_event VARCHAR(500),
    intensity INTEGER DEFAULT 5 CHECK (intensity >= 1 AND intensity <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_emotion_logs_user_id ON emotion_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_emotion_logs_created_at ON emotion_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_emotion_logs_emotion_type ON emotion_logs(emotion_type);

COMMENT ON TABLE emotion_logs IS 'บันทึกอารมณ์ของผู้ใช้ - ประเภท, เหตุการณ์กระตุ้น, ความรุนแรง';
COMMENT ON COLUMN emotion_logs.intensity IS 'ความรุนแรงของอารมณ์ 1-10';


-- =========================================================================
-- 15. EMOTION SESSIONS - session การเก็บข้อมูลอารมณ์
-- =========================================================================
CREATE TABLE IF NOT EXISTS emotion_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_name VARCHAR(255),
    target_emotion VARCHAR(50) NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    samples_collected INTEGER DEFAULT 0,
    avg_alpha REAL DEFAULT 0,
    avg_beta REAL DEFAULT 0,
    avg_theta REAL DEFAULT 0,
    avg_delta REAL DEFAULT 0,
    avg_gamma REAL DEFAULT 0,
    self_report_valence INTEGER,
    self_report_arousal INTEGER,
    notes TEXT,
    is_completed BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_emotion_sessions_user_id ON emotion_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_emotion_sessions_target_emotion ON emotion_sessions(target_emotion);

COMMENT ON TABLE emotion_sessions IS 'session การเก็บข้อมูลอารมณ์ แต่ละ session กำหนดอารมณ์เป้าหมายและกิจกรรมที่ใช้กระตุ้น';


-- =========================================================================
-- 16. EEG ASSESSMENT REPORTS - ใบสรุปประเมินภาวะซึมเศร้า (qEEG)
-- =========================================================================
CREATE TABLE IF NOT EXISTS eeg_assessment_reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    eeg_index REAL NOT NULL DEFAULT 0,
    risk_level VARCHAR(100),
    risk_level_en VARCHAR(100),
    samples_collected INTEGER DEFAULT 0,
    duration_seconds INTEGER DEFAULT 120,
    report_data JSONB NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eeg_reports_user_id ON eeg_assessment_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_eeg_reports_recorded_at ON eeg_assessment_reports(recorded_at DESC);

COMMENT ON TABLE eeg_assessment_reports IS 'ใบสรุปประเมินภาวะซึมเศร้าจาก qEEG';


-- =========================================================================
-- 17. TRIGGERS: อัปเดต updated_at อัตโนมัติ
-- =========================================================================
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_knowledge_base_updated_at ON knowledge_base;
CREATE TRIGGER update_knowledge_base_updated_at
    BEFORE UPDATE ON knowledge_base
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_emergency_contacts_updated_at ON emergency_contacts;
CREATE TRIGGER update_emergency_contacts_updated_at
    BEFORE UPDATE ON emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_elderly_profiles_updated_at ON elderly_profiles;
CREATE TRIGGER update_elderly_profiles_updated_at
    BEFORE UPDATE ON elderly_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- =========================================================================
-- 18. FUNCTIONS สำหรับ RAG
-- =========================================================================

-- ค้นหาความรู้ด้วย vector similarity (เรียกจาก RAGService._vectorSearch)
CREATE OR REPLACE FUNCTION search_knowledge(
    query_embedding extensions.vector(1536),
    match_count INT DEFAULT 5,
    match_threshold FLOAT DEFAULT 0.7
)
RETURNS TABLE (
    id INT,
    title VARCHAR(500),
    content TEXT,
    category VARCHAR(100),
    similarity FLOAT
)
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kb.id,
        kb.title,
        kb.content,
        kb.category,
        (1 - (kb.embedding <=> query_embedding))::FLOAT AS similarity
    FROM knowledge_base kb
    WHERE kb.embedding IS NOT NULL
      AND 1 - (kb.embedding <=> query_embedding) > match_threshold
    ORDER BY kb.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- ค้นหาแบบ hybrid: vector + keyword
CREATE OR REPLACE FUNCTION hybrid_search(
    query_embedding extensions.vector(1536),
    query_text TEXT,
    match_count INT DEFAULT 5,
    vector_weight FLOAT DEFAULT 0.7,
    text_weight FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id INT,
    title VARCHAR(500),
    content TEXT,
    category VARCHAR(100),
    combined_score FLOAT
)
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kb.id,
        kb.title,
        kb.content,
        kb.category,
        (
            vector_weight * (1 - (kb.embedding <=> query_embedding)) +
            text_weight * COALESCE(
                ts_rank(to_tsvector('simple', kb.content), plainto_tsquery('simple', query_text)),
                0
            )
        )::FLOAT AS combined_score
    FROM knowledge_base kb
    WHERE kb.embedding IS NOT NULL
    ORDER BY combined_score DESC
    LIMIT match_count;
END;
$$;

-- บริบทผู้ใช้สำหรับ AI (เรียกจาก RAGService.buildUserContext)
-- คลื่นสมองเฉลี่ย 7 วันมาจาก emotion_sessions, attention/meditation มาจาก eeg_sessions
-- ถ้า 7 วันที่ผ่านมาไม่มี session เลย brainwave_avg จะเป็น NULL (แอปจะข้ามส่วนนี้)
CREATE OR REPLACE FUNCTION get_user_context(
    p_user_id INT,
    context_limit INT DEFAULT 5
)
RETURNS TABLE (
    topic VARCHAR(255),
    summary TEXT,
    brainwave_avg JSONB,
    stress_level VARCHAR(50),
    recent_activities TEXT[]
)
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        'user_profile'::VARCHAR(255) AS topic,
        'Profile and health data'::TEXT AS summary,
        (
            SELECT CASE WHEN w.n_emotion = 0 AND w.n_eeg = 0 THEN NULL
            ELSE jsonb_build_object(
                'alpha', COALESCE(w.alpha, 0),
                'beta', COALESCE(w.beta, 0),
                'theta', COALESCE(w.theta, 0),
                'delta', COALESCE(w.delta, 0),
                'gamma', COALESCE(w.gamma, 0),
                'attention', COALESCE(w.attention, 0),
                'meditation', COALESCE(w.meditation, 0)
            ) END
            FROM (
                SELECT
                    COUNT(*) AS n_emotion,
                    AVG(es.avg_alpha) AS alpha,
                    AVG(es.avg_beta) AS beta,
                    AVG(es.avg_theta) AS theta,
                    AVG(es.avg_delta) AS delta,
                    AVG(es.avg_gamma) AS gamma,
                    (SELECT COUNT(*) FROM eeg_sessions s
                        WHERE s.user_id = p_user_id AND s.started_at > NOW() - INTERVAL '7 days') AS n_eeg,
                    (SELECT AVG(s.avg_attention_score) FROM eeg_sessions s
                        WHERE s.user_id = p_user_id AND s.started_at > NOW() - INTERVAL '7 days') AS attention,
                    (SELECT AVG(s.avg_relaxation_score) FROM eeg_sessions s
                        WHERE s.user_id = p_user_id AND s.started_at > NOW() - INTERVAL '7 days') AS meditation
                FROM emotion_sessions es
                WHERE es.user_id = p_user_id
                  AND es.started_at > NOW() - INTERVAL '7 days'
            ) w
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
$$;

COMMENT ON FUNCTION search_knowledge IS 'ค้นหาความรู้ด้วย vector similarity';
COMMENT ON FUNCTION hybrid_search IS 'ค้นหาแบบ hybrid: vector + keyword';
COMMENT ON FUNCTION get_user_context IS 'ดึงบริบทผู้ใช้สำหรับ personalized AI';


-- =========================================================================
-- 19. ROW LEVEL SECURITY
-- =========================================================================
-- ⚠️ ส่วนนี้ยังเปิด "Allow all" (ใครมี anon key ก็อ่าน/แก้ทุกแถวได้)
-- หลังรันไฟล์นี้ ให้รัน supabase/migrations/015_secure_rls.sql ต่อทันที
-- เพื่อจำกัดให้แต่ละคนเห็นเฉพาะข้อมูลของตัวเอง
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'users', 'user_settings', 'test_results', 'activities', 'chat_messages',
        'voice_metadata', 'emergency_contacts', 'elderly_profiles', 'conversations',
        'retrieval_logs', 'eeg_devices', 'eeg_sessions', 'emotion_logs',
        'emotion_sessions', 'eeg_assessment_reports'
    ]
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'Allow all for ' || tbl, tbl);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR ALL USING (true) WITH CHECK (true)',
            'Allow all for ' || tbl, tbl
        );
    END LOOP;
END $$;

-- knowledge_base: อ่านได้ทุกคน และให้แอปเขียน embedding กลับได้ (RAGService.updateEmbeddings)
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow read for knowledge_base" ON knowledge_base;
CREATE POLICY "Allow read for knowledge_base" ON knowledge_base
    FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow update for knowledge_base" ON knowledge_base;
CREATE POLICY "Allow update for knowledge_base" ON knowledge_base
    FOR UPDATE USING (true) WITH CHECK (true);

-- ให้ API (anon / authenticated) เข้าถึงตาราง, sequence และเฉพาะฟังก์ชันที่แอปเรียก
-- (ไม่ใช้ ALL FUNCTIONS เพราะจะเปิดฟังก์ชัน SECURITY DEFINER ของ Supabase เช่น rls_auto_enable ให้คนนอกเรียกได้)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION
    search_knowledge(extensions.vector, INT, FLOAT),
    hybrid_search(extensions.vector, TEXT, INT, FLOAT, FLOAT),
    get_user_context(INT, INT)
TO anon, authenticated;


-- =========================================================================
-- 20. REALTIME (.stream() ใน Flutter)
-- =========================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'test_results', 'activities', 'chat_messages', 'user_settings', 'eeg_assessment_reports'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = tbl
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        END IF;
    END LOOP;
END $$;


-- =========================================================================
-- 21. STORAGE: bucket รูปโปรไฟล์ (avatars)
-- =========================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Anyone can upload an avatar" ON storage.objects;
CREATE POLICY "Anyone can upload an avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Anyone can update their own avatar" ON storage.objects;
CREATE POLICY "Anyone can update their own avatar"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Anyone can delete their own avatar" ON storage.objects;
CREATE POLICY "Anyone can delete their own avatar"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'avatars');


-- =========================================================================
-- 22. ข้อมูลฐานความรู้ (RAG) - 29 รายการ
-- =========================================================================
-- embedding ยังว่าง ให้แอปเรียก RAGService.updateEmbeddings() หนึ่งครั้งหลัง deploy openai-proxy
-- ระหว่างนั้นแชทยังค้นด้วย keyword ได้ตามปกติ

INSERT INTO knowledge_base (title, content, category, tags, metadata) VALUES

-- ---------- คลื่นสมอง (จาก 002) ----------
('คลื่นสมอง Alpha คืออะไร',
'คลื่น Alpha (8-13 Hz) เป็นคลื่นสมองที่เกิดขึ้นเมื่อเราอยู่ในสภาวะผ่อนคลาย สงบ และตื่นตัว เช่น การทำสมาธิ ปิดตาพักผ่อน หรือมองทิวทัศน์ธรรมชาติ คลื่น Alpha ช่วยลดความเครียด เพิ่มความคิดสร้างสรรค์ และส่งเสริมการเรียนรู้',
'brainwave', ARRAY['alpha', 'relaxation', 'meditation'], '{"frequency": "8-13 Hz", "state": "relaxed alertness"}'),

('คลื่นสมอง Beta และการทำงาน',
'คลื่น Beta (13-30 Hz) เป็นคลื่นที่ครองสมองเมื่อเราตื่นตัว ทำงาน คิดวิเคราะห์ หรือแก้ปัญหา Beta สูงเกินไปอาจทำให้วิตกกังวล เครียด หรือนอนไม่หลับ การฝึกสมาธิช่วยลด Beta ที่มากเกินไปได้',
'brainwave', ARRAY['beta', 'focus', 'work', 'anxiety'], '{"frequency": "13-30 Hz", "state": "active thinking"}'),

('คลื่นสมอง Theta และความคิดสร้างสรรค์',
'คลื่น Theta (4-8 Hz) เกิดขึ้นระหว่างการเคลิ้มหลับ ฝันกลางวัน หรือสมาธิลึก คลื่นนี้เชื่อมโยงกับความคิดสร้างสรรค์ ความจำ และการประมวลผลอารมณ์ การเพิ่ม Theta ช่วยให้จิตใจสงบและเข้าถึงจิตใต้สำนึก',
'brainwave', ARRAY['theta', 'creativity', 'meditation', 'dream'], '{"frequency": "4-8 Hz", "state": "deep relaxation"}'),

('คลื่นสมอง Delta และการนอนหลับ',
'คลื่น Delta (0.5-4 Hz) เกิดในระหว่างการนอนหลับลึก ไม่ฝัน เป็นคลื่นที่สำคัญสำหรับการฟื้นฟูร่างกาย ซ่อมแซมเนื้อเยื่อ และเสริมระบบภูมิคุ้มกัน การนอนไม่พอทำให้ Delta ลดลง',
'brainwave', ARRAY['delta', 'sleep', 'recovery', 'healing'], '{"frequency": "0.5-4 Hz", "state": "deep sleep"}'),

('คลื่นสมอง Gamma และสมาธิสูง',
'คลื่น Gamma (30-100+ Hz) เกี่ยวข้องกับการประมวลผลข้อมูลระดับสูง สติปัญญา และความตระหนักรู้ พบในผู้ทำสมาธิที่ชำนาญ Gamma สูงช่วยเพิ่มความจำ การเรียนรู้ และความสุข',
'brainwave', ARRAY['gamma', 'cognition', 'awareness', 'advanced meditation'], '{"frequency": "30-100+ Hz", "state": "peak mental processing"}'),

-- ---------- สุขภาพจิต (จาก 002) ----------
('ความเครียดคืออะไรและผลกระทบ',
'ความเครียดคือการตอบสนองของร่างกายต่อสถานการณ์ที่ท้าทาย ความเครียดเฉียบพลันช่วยให้ตื่นตัว แต่ความเครียดเรื้อรังทำลายสุขภาพ ทำให้นอนไม่หลับ ปวดหัว ระบบภูมิคุ้มกันอ่อนแอ และเพิ่มความเสี่ยงโรคหัวใจ',
'mental_health', ARRAY['stress', 'health', 'chronic'], '{"type": "educational"}'),

('วิธีจัดการความเครียดอย่างมีประสิทธิภาพ',
'การจัดการความเครียดที่ได้ผล ได้แก่ 1) หายใจลึก 4-7-8: หายใจเข้า 4 วินาที กลั้น 7 วินาที หายใจออก 8 วินาที 2) ออกกำลังกายสม่ำเสมอ 3) นอนหลับให้เพียงพอ 4) ทำสมาธิ 10-20 นาทีต่อวัน 5) พูดคุยกับคนที่ไว้ใจ',
'mental_health', ARRAY['stress', 'management', 'breathing', 'exercise'], '{"type": "practical_advice"}'),

('สัญญาณของภาวะซึมเศร้า',
'สัญญาณซึมเศร้า ได้แก่ เศร้าหมองมากกว่า 2 สัปดาห์ ไม่สนใจสิ่งที่เคยชอบ นอนมากหรือน้อยผิดปกติ เบื่ออาหารหรือกินมาก เหนื่อยล้า รู้สึกไร้ค่า มีปัญหาสมาธิ หากมีหลายอาการ ควรปรึกษาผู้เชี่ยวชาญ',
'mental_health', ARRAY['depression', 'symptoms', 'warning signs'], '{"type": "awareness"}'),

-- ---------- สมาธิ (จาก 002) ----------
('การทำสมาธิเบื้องต้น',
'เริ่มต้นสมาธิง่ายๆ: 1) นั่งสบาย หลับตา 2) หายใจตามธรรมชาติ 3) จดจ่อที่ลมหายใจ 4) เมื่อใจลอย ให้กลับมาที่ลมหายใจ 5) เริ่มจาก 5 นาที ค่อยๆ เพิ่ม การฝึกสม่ำเสมอช่วยเพิ่ม Alpha และ Theta',
'meditation', ARRAY['beginner', 'breathing', 'practice'], '{"difficulty": "beginner", "duration": "5-20 minutes"}'),

('Body Scan Meditation',
'Body Scan คือการสังเกตความรู้สึกทางกายตั้งแต่ศีรษะถึงปลายเท้า ช่วยผ่อนคลายกล้ามเนื้อ ลดความเครียด และเพิ่มการตระหนักรู้ในร่างกาย เหมาะทำก่อนนอนหรือเมื่อเครียด ใช้เวลา 15-30 นาที',
'meditation', ARRAY['body scan', 'relaxation', 'awareness'], '{"difficulty": "intermediate", "duration": "15-30 minutes"}'),

-- ---------- การนอน (จาก 002) ----------
('วิธีนอนหลับให้ดีขึ้น',
'เคล็ดลับนอนหลับดี: 1) นอนและตื่นเวลาเดิมทุกวัน 2) ห้องนอนมืดและเย็น 3) งดหน้าจอ 1 ชั่วโมงก่อนนอน 4) งดคาเฟอีนหลังบ่าย 5) ออกกำลังกายแต่ไม่ใกล้เวลานอน 6) ทำกิจกรรมผ่อนคลายก่อนนอน',
'sleep', ARRAY['sleep hygiene', 'quality', 'tips'], '{"type": "practical_advice"}'),

('ความสัมพันธ์ระหว่างการนอนกับคลื่นสมอง',
'ในการนอนหลับปกติ สมองผ่านหลายระยะ: NREM 1 (Theta), NREM 2 (Sleep Spindles), NREM 3 (Delta ลึก), และ REM (ฝัน, คลื่นหลากหลาย) การนอนครบทุกระยะสำคัญต่อความจำ การเรียนรู้ และสุขภาพกาย',
'sleep', ARRAY['sleep stages', 'brainwave', 'REM', 'NREM'], '{"type": "educational"}'),

-- ---------- อุปกรณ์ Muse (จาก 002) ----------
('วิธีใช้ Muse S สำหรับการทำสมาธิ',
'Muse S คืออุปกรณ์ EEG สำหรับผู้บริโภคที่วัดคลื่นสมองขณะทำสมาธิ วิธีใช้: 1) สวมใส่ให้แน่นพอดี 2) เชื่อมต่อ Bluetooth กับแอป 3) เลือกโปรแกรมสมาธิ 4) ฟังเสียง feedback ที่เปลี่ยนตามสภาวะจิตใจ สมาธิดี = เสียงธรรมชาติสงบ',
'device', ARRAY['muse', 'eeg', 'meditation', 'setup'], '{"device": "Muse S", "type": "tutorial"}'),

('การอ่านค่าคลื่นสมองจาก Muse',
'Muse แสดงข้อมูล: Attention (สมาธิ) และ Meditation (ความสงบ) คะแนน 0-100 คะแนน Attention สูงหมายถึงจิตจดจ่อ คะแนน Meditation สูงหมายถึงจิตสงบผ่อนคลาย การติดตามแนวโน้มช่วยเห็นความก้าวหน้าในการฝึก',
'device', ARRAY['muse', 'metrics', 'attention', 'meditation'], '{"device": "Muse S/Muse 2", "type": "interpretation"}'),

-- ---------- ฉุกเฉิน (จาก 003) ----------
('สัญญาณอันตรายที่ต้องพบแพทย์ทันที',
'หากมีอาการเหล่านี้ควรรีบติดต่อแพทย์หรือสายด่วนทันที:
1. มีความคิดอยากทำร้ายตัวเอง หรือพูดสั่งเสีย เช่น "ฝากดูแลบ้านด้วย" "ไม่อยากอยู่แล้ว"
2. นอนไม่หลับติดต่อกันเกิน 1 สัปดาห์ จนร่างกายอ่อนเพลียมาก
3. หูแว่ว เห็นภาพหลอน หรือมีความหวาดระแวงรุนแรง
4. ซึมเศร้าจนไม่กินข้าว ไม่กินน้ำ ไม่ลุกจากเตียง

⚠️ หากพบอาการเหล่านี้ โปรดโทร 1323 สายด่วนสุขภาพจิต ทันที',
'emergency',
ARRAY['ฉุกเฉิน', 'สัญญาณอันตราย', 'พบแพทย์', 'ทำร้ายตัวเอง', 'ซึมเศร้ารุนแรง'],
'{"priority": "critical", "action": "seek_help_immediately", "source": "กรมสุขภาพจิต"}'),

('สายด่วนสุขภาพจิต 1323',
'สายด่วนสุขภาพจิต 1323 ให้บริการปรึกษาปัญหาสุขภาพจิตฟรี ตลอด 24 ชั่วโมง ทุกวัน
📞 โทร: 1323 (ฟรีทุกเครือข่าย)
⏰ เวลา: 24 ชั่วโมง ทุกวัน
👨‍⚕️ บริการ:
- ปรึกษานักจิตวิทยา
- รับฟังปัญหา
- ให้คำแนะนำเบื้องต้น
- ส่งต่อการรักษา

หากรู้สึกเครียด วิตกกังวล หรือต้องการคนรับฟัง สามารถโทรได้ตลอดเวลา',
'emergency',
ARRAY['1323', 'สายด่วน', 'สุขภาพจิต', 'ปรึกษา', 'ฟรี', '24ชั่วโมง'],
'{"phone": "1323", "service": "mental_health_hotline", "free": true, "24_hours": true, "source": "กรมสุขภาพจิต"}'),

('สายด่วนฉุกเฉิน 1669',
'สายด่วนการแพทย์ฉุกเฉิน 1669 สำหรับเจ็บป่วยฉุกเฉิน ต้องการรถพยาบาล
📞 โทร: 1669
⏰ เวลา: 24 ชั่วโมง ทุกวัน
🚑 บริการ:
- รถพยาบาลฉุกเฉิน
- ปรึกษาแพทย์เบื้องต้น
- ส่งต่อโรงพยาบาล

กรณีเจ็บป่วยรุนแรง หมดสติ อุบัติเหตุ โปรดโทรทันที',
'emergency',
ARRAY['1669', 'ฉุกเฉิน', 'รถพยาบาล', 'เจ็บป่วย', 'อุบัติเหตุ'],
'{"phone": "1669", "service": "emergency_medical", "free": true, "24_hours": true}'),

('สมาคมสะมาริตันส์ The Samaritans of Thailand',
'สมาคมสะมาริตันส์แห่งประเทศไทย (The Samaritans of Thailand) ให้บริการรับฟังเพื่อป้องกันการฆ่าตัวตาย
📞 โทร: 02-113-6789
⏰ เวลา: ทุกวัน 12:00 - 22:00 น.
💚 บริการ:
- รับฟังโดยไม่ตัดสิน
- ให้กำลังใจ
- ป้องกันการฆ่าตัวตาย

หากรู้สึกหมดหวัง ต้องการคนรับฟัง สามารถโทรได้',
'emergency',
ARRAY['สะมาริตันส์', 'Samaritans', 'ป้องกันการฆ่าตัวตาย', 'รับฟัง'],
'{"phone": "02-113-6789", "service": "suicide_prevention", "organization": "The Samaritans of Thailand"}'),

('เมื่อมีความคิดอยากทำร้ายตัวเอง',
'หากคุณหรือคนใกล้ชิดมีความคิดอยากทำร้ายตัวเอง:

🆘 ทำทันที:
1. โทร 1323 สายด่วนสุขภาพจิต (ฟรี 24 ชม.)
2. อยู่กับคนที่ไว้ใจ อย่าอยู่คนเดียว
3. เก็บของมีคม ยา สารเคมี ให้พ้นมือ

💭 สังเกตสัญญาณ:
- พูดว่า "ไม่อยากอยู่แล้ว" "เป็นภาระ"
- สั่งเสียฝากของ
- ถอนตัวจากสังคม
- ให้ของมีค่าคนอื่น

❤️ จำไว้ว่า: ความรู้สึกนี้จะผ่านไป และมีคนพร้อมช่วยเหลือ',
'emergency',
ARRAY['ทำร้ายตัวเอง', 'ฆ่าตัวตาย', 'สัญญาณเตือน', 'ขอความช่วยเหลือ'],
'{"priority": "critical", "action": "call_1323", "source": "กรมสุขภาพจิต"}'),

('อาการหูแว่ว เห็นภาพหลอน',
'อาการหูแว่ว (ได้ยินเสียงที่คนอื่นไม่ได้ยิน) หรือเห็นภาพหลอน อาจเป็นสัญญาณของโรคทางจิตเวชที่ต้องรักษา

🔴 เมื่อไหร่ต้องพบแพทย์ทันที:
- หูแว่วสั่งให้ทำร้ายตัวเอง/คนอื่น
- หวาดระแวงรุนแรง
- ไม่นอนหลายวัน
- พฤติกรรมเปลี่ยนแปลงมาก

📞 โทร 1323 หรือพาไปโรงพยาบาลที่มีแพทย์จิตเวช

💊 อาการนี้รักษาได้ด้วยยาและการบำบัด',
'emergency',
ARRAY['หูแว่ว', 'ภาพหลอน', 'หวาดระแวง', 'โรคจิตเวช'],
'{"priority": "high", "action": "see_psychiatrist", "treatable": true}'),

('นอนไม่หลับรุนแรง เกิน 1 สัปดาห์',
'การนอนไม่หลับติดต่อกันเกิน 7 วัน ถือเป็นภาวะฉุกเฉินที่ต้องได้รับการรักษา

🚨 อันตรายของการนอนไม่หลับเรื้อรัง:
- ร่างกายอ่อนเพลียรุนแรง
- ภูมิคุ้มกันต่ำ
- อารมณ์แปรปรวน หงุดหงิดง่าย
- สมาธิลดลง เสี่ยงอุบัติเหตุ
- อาจเป็นสัญญาณของโรคซึมเศร้า

📞 ควรพบแพทย์หรือโทร 1323
💊 มียาช่วยนอนหลับที่ปลอดภัยภายใต้การดูแลแพทย์',
'emergency',
ARRAY['นอนไม่หลับ', 'insomnia', 'ฉุกเฉิน', 'เรื้อรัง'],
'{"priority": "high", "duration_threshold": "7_days", "action": "see_doctor"}'),

('ซึมเศร้ารุนแรง ไม่กินข้าว ไม่ลุกจากเตียง',
'เมื่อความซึมเศร้ารุนแรงจนไม่กินอาหาร ไม่ดื่มน้ำ ไม่ลุกจากเตียง ถือเป็นภาวะฉุกเฉินทางจิตเวช

🆘 ต้องรีบพาพบแพทย์ทันทีเพราะ:
- ร่างกายอาจขาดสารอาหารและน้ำ
- อาจมีความคิดทำร้ายตัวเอง
- อาการอาจแย่ลงอย่างรวดเร็ว

📞 โทร 1323 หรือ 1669
🏥 พาไปห้องฉุกเฉินโรงพยาบาล

❤️ โรคซึมเศร้ารักษาได้ อย่าปล่อยให้อยู่คนเดียว',
'emergency',
ARRAY['ซึมเศร้า', 'ไม่กินอาหาร', 'ฉุกเฉิน', 'depression', 'severe'],
'{"priority": "critical", "action": "emergency_room", "treatable": true}'),

('วิธีช่วยเหลือคนใกล้ชิดที่มีปัญหาสุขภาพจิต',
'หากพบคนใกล้ชิดมีปัญหาสุขภาพจิต สิ่งที่ควรทำ:

✅ สิ่งที่ควรทำ:
1. รับฟังโดยไม่ตัดสิน
2. แสดงความห่วงใย "ฉันเป็นห่วงนะ"
3. ชวนไปพบแพทย์ด้วยกัน
4. อยู่เป็นเพื่อน ไม่ปล่อยให้อยู่คนเดียว
5. เก็บของอันตรายให้พ้นมือ

❌ สิ่งที่ไม่ควรทำ:
- ตำหนิ "คิดมากไปเอง"
- เปรียบเทียบ "คนอื่นลำบากกว่า"
- บังคับ "หายซึมเศร้าได้สิ"
- ปล่อยให้อยู่คนเดียว

📞 หากไม่แน่ใจ โทรปรึกษา 1323 ได้',
'mental_health',
ARRAY['ช่วยเหลือ', 'คนใกล้ชิด', 'รับฟัง', 'สุขภาพจิต'],
'{"type": "caregiver_guide", "source": "กรมสุขภาพจิต"}'),

('สุขภาพจิตผู้สูงอายุ',
'ผู้สูงอายุมีความเสี่ยงต่อปัญหาสุขภาพจิตได้ง่าย เนื่องจากการเปลี่ยนแปลงทางร่างกายและสังคม

🔍 สัญญาณที่ควรระวัง:
- ซึมเศร้า เก็บตัว ไม่อยากพบใคร
- นอนไม่หลับ ตื่นกลางคืนบ่อย
- ความจำลดลง สับสน หลงลืม
- หงุดหงิดง่าย อารมณ์เปลี่ยนแปลง
- ไม่สนใจดูแลตัวเอง

👨‍👩‍👧‍👦 สิ่งที่ลูกหลานควรทำ:
- เยี่ยมเยียนสม่ำเสมอ
- ชวนทำกิจกรรมด้วยกัน
- ดูแลเรื่องการกินยา
- พาไปพบแพทย์ตามนัด

📞 ปรึกษา 1323 ได้ตลอด 24 ชม.',
'mental_health',
ARRAY['ผู้สูงอายุ', 'สุขภาพจิต', 'ซึมเศร้า', 'ความจำ', 'elderly'],
'{"target_group": "elderly", "source": "กรมสุขภาพจิต"}'),

-- ---------- ข้อมูลโครงการ SmartBrain Care (จาก 011) ----------
('ที่มาและแนวคิดของโครงการ SmartBrain Care',
'ปัญหาความผิดปกติทางระบบประสาทและสภาวะทางจิตใจ โดยเฉพาะโรคสมองเสื่อม ภาวะเครียดสะสม และโรคซึมเศร้า เป็นสาเหตุหลักของการสูญเสียสุขภาวะที่ดีและการลดประสิทธิภาพในการดำเนินชีวิตของประชากรทั่วโลก โดยเฉพาะในสังคมผู้สูงอายุ (WHO, 2022) อุปสรรคสำคัญของการตรวจจับในระยะแรกเริ่มคือ ความแปรปรวนและความซับซ้อนของคลื่นสมองในแต่ละบุคคล ระบบคัดกรองแบบดั้งเดิมที่อาศัยแบบสอบถาม (Subjective) หรือการตรวจ qEEG ราคาแพงและใช้แพทย์เฉพาะทางวิเคราะห์เป็นเวลานาน จึงเกิดแนวคิดการพัฒนา SmartBrain Care ระบบอัจฉริยะที่แปลงสัญญาณคลื่นสมอง (EEG) ดิบลดสัญญาณรบกวน (Artifacts) ให้เป็นภาพโครงสร้างเชิงสเปกตรัมหรือแผนที่ความร้อน (Topographic Map) และประยุกต์ใช้การเรียนรู้แบบถ่ายโอน (Transfer Learning) ร่วมกับปัญญาประดิษฐ์เพื่อการจำแนกสภาวะอารมณ์ความเครียดได้แม่นยำ รวดเร็ว และประหยัดทรัพยากรการประมวลผลบน Edge Devices พร้อมเชื่อมต่อ AI Chatbot และระบบสั่งการด้วยเสียงภาษาไทยเพื่อรองรับผู้สูงอายุอย่างเข้าอกเข้าใจ',
'mental_health',
ARRAY['SmartBrain Care', 'ที่มา', 'แนวคิด', 'คลื่นสมอง', 'ผู้สูงอายุ', 'ความเครียด', 'ซึมเศร้า'],
'{"source": "Higher Education Innovation Awards 2026", "author": "มหาวิทยาลัยวลัยลักษณ์"}'),

('วัตถุประสงค์ของโครงการ SmartBrain Care',
'โครงการ SmartBrain Care ได้รับการพัฒนาภายใต้วัตถุประสงค์หลัก 3 ประการ:
1. เพื่อพัฒนาระบบคัดกรองและประเมินสภาวะสมองอัตโนมัติ (Automated Screening) ที่สามารถตอบสนองต่อความเสี่ยงทางสุขภาพระบบประสาทและจิตใจได้แบบเรียลไทม์ และช่วยลดภาระงานในการแปลผลกราฟคลื่นสมองที่ซับซ้อนของแพทย์
2. เพื่อประยุกต์ใช้เทคโนโลยีปัญญาประดิษฐ์ในการจำแนกสภาวะสมองผ่านข้อมูลเชิงภาพ (Image-based Brain State Classification) โดยการแปลงสัญญาณ EEG เป็นภาพแผนที่ความร้อนวิเคราะห์ความผิดปกติด้วยทรัพยากรต่ำสุดแต่คงความแม่นยำสูงตามมาตรฐานสากล
3. เพื่อยกระดับมาตรฐานการเฝ้าระวังสุขภาพเชิงรุกและสุขภาพจิต สำหรับครอบครัว องค์กร และสถานพยาบาลปฐมภูมิ ด้วยอุปกรณ์สวมใส่แบบแห้ง (Dry Electrodes) ที่สวมใส่ง่าย ไม่รุกล้ำร่างกาย และสามารถติดตามแนวโน้มสภาวะสมองได้อย่างมีประสิทธิภาพ',
'general',
ARRAY['วัตถุประสงค์', 'เป้าหมาย', 'คัดกรอง', 'ปัญญาประดิษฐ์', 'สุขภาพจิตเชิงรุก'],
'{"source": "Higher Education Innovation Awards 2026"}'),

('จุดเด่นและกลไกที่แตกต่างของ SmartBrain Care',
'จุดเด่นที่แตกต่างจากระบบตรวจวัดทั่วไปในตลาดมี 5 ประการ:
1. กลไกวิเคราะห์สภาวะสมองผ่านข้อมูลเชิงภาพ (Spectrogram/Topographic Map): แปลงสัญญาณไฟฟ้าดิบ (Raw EEG) ให้เป็นลวดลายเชิงสเปกตรัมที่บ่งชี้คุณลักษณะเฉพาะทางชีวภาพ (Biomarkers) ช่วยลดผลกระทบจากสัญญาณรบกวนกล้ามเนื้อ
2. การเพิ่มประสิทธิภาพด้วยกลไกเพิ่มข้อมูลแบบน้ำหนักเบา (Lightweight Data Augmentation): จำลองความแปรปรวนของสัญญาณด้วยสมการคณิตศาสตร์และสัญญาณรบกวนต่ำ ช่วยให้ปัญญาประดิษฐ์เรียนรู้ความผิดปกติที่พบลดน้อยได้จากชุดข้อมูลขนาดเล็ก
3. การเรียนรู้แบบถ่ายโอนเพื่อความแม่นยำเชิงลึก (Transfer Learning): ถ่ายโอนทักษะจดจำภาพจากโมเดลสากลระดับโลก (เช่น Xception/ResNet) ทำให้จำแนกสภาวะสมองได้รวดเร็วและประหยัดกำลังเครื่อง
4. โครงสร้างซอฟต์แวร์ที่ยืดหยุ่นและประหยัดทรัพยากร: พัฒนาให้ทำงานประมวลผลสัญญาณและคัดกรองบนอุปกรณ์ปลายทาง (Edge Devices) เช่น สมาร์ตโฟนได้เรียลไทม์โดยไม่หน่วงเครื่อง
5. การเฝ้าระวังเชิงรุกและลดเวลาวินิจฉัย: ทำหน้าที่เป็นปราการด่านแรกประเมินความเสี่ยงได้ในเสี้ยววินาทีเพื่อตอบสนองต่อสภาวะจิตใจเฉียบพลัน',
'general',
ARRAY['จุดเด่น', 'กลไก', 'ความแตกต่าง', 'นวัตกรรม', 'ภาพโครงสร้าง', 'Augmentation'],
'{"source": "Higher Education Innovation Awards 2026"}'),

('หลักการและขั้นตอนการทำงานของนวัตกรรม SmartBrain Care',
'นวัตกรรมทำงานผ่านกระบวนการหลัก 5 ขั้นตอนดังนี้:
ขั้นตอนที่ 1: การรับสัญญาณและการแปลงข้อมูลเชิงภาพ - รับข้อมูล EEG จากอุปกรณ์ Muse 2/Muse S ผ่านสัญญาณบลูทูธ BLE กรองสิ่งปนเปื้อนด้วย Butterworth Bandpass (0.5-45 Hz) และ Notch Filter (50 Hz) แล้วแปลงสัญญาณเป็นภาพสเปกตรัมและแผนที่ความร้อน
ขั้นตอนที่ 2: การขยายขีดความสามารถด้วยการเพิ่มข้อมูลแบบน้ำหนักเบา - ใช้อัลกอริทึมจำลองความหลากหลายของสัญญาณสมอง ช่วยให้ AI มีคลังข้อมูลในการจำจำสัญญาณที่มีความแปรปรวนในแต่ละบุคคลโดยไม่กินหน่วยความจำเครื่อง
ขั้นตอนที่ 3: การวิเคราะห์และจำแนกประเภทเชิงลึก - นำข้อมูลเชิงภาพส่งเข้าสู่โมเดลปัญญาประดิษฐ์เชิงลึก (Deep Learning) ที่ผ่านกระบวนการ Transfer Learning เพื่อจำแนกประเภทสภาวะอารมณ์ 10 ประเภทและคำนวณคะแนนความเครียด
ขั้นตอนที่ 4: การประเมินสภาวะและตัดสินใจ - คำนวณความเชื่อมั่นและประเมินร่วมกับแบบประเมินสุขภาพจิต PHQ-9 พร้อมตั้งค่าระดับความรุนแรง หากคะแนนเกินเกณฑ์จะทำการแจ้งเตือนผู้ใช้หรือผู้ดูแลทันที
ขั้นตอนที่ 5: การแสดงผลและรายงาน - แสดงผลลัพธ์ผ่านหน้าจอ Dashboard และผู้ใช้สามารถส่งออกรายงานประวัติย้อนหลังเป็นไฟล์เอกสาร PDF (EegPdfService) เพื่อใช้ยื่นประกอบการวินิจฉัยกับจิตแพทย์ได้ทันที',
'general',
ARRAY['หลักการ', 'ขั้นตอน', 'ประมวลผล', 'Welch', 'FFT', 'แผนที่ความร้อน'],
'{"source": "Higher Education Innovation Awards 2026"}'),

('ระดับความพร้อม TRL/SRL และความพร้อมทางธุรกิจของ SmartBrain Care',
'ระดับความพร้อมของโครงงานประกอบด้วย:
- ระดับความพร้อมทางเทคโนโลยี (TRL 6): ตัวแบบต้นแบบ (Prototype) ได้ผ่านการทดสอบในสภาพแวดล้อมที่จำลองสภาวะการทำงานของสมองและปนเปื้อนสัญญาณรบกวนใกล้เคียงชีวิตประจำวันแล้ว และกำลังมุ่งสู่ระดับ TRL 7 ที่ทำการทดสอบในสภาวะการใช้งานจริงทางคลินิก
- ระดับความพร้อมทางสังคม (SRL 6): นวัตกรรมผ่านการทดสอบและสาธิตร่วมกับสถานพยาบาลระดับปฐมภูมิ (รพ.สต.) และรับฟังความคิดเห็นเชิงลึกจากนักจิตวิทยาคลินิก เพื่อเตรียมพร้อมขยายสู่ SRL 7 ที่ได้รับการยอมรับด้านจริยธรรมข้อมูลส่วนบุคคล
- สถานภาพทรัพย์สินทางปัญญา: อยู่ระหว่างการจัดเตรียมเอกสารยื่นจดสิทธิบัตรหรืออนุสิทธิบัตรในประเทศไทย เพื่อคุ้มครองลิขสิทธิ์อัลกอริทึมการประมวลผลสัญญาณน้ำหนักเบาร่วมกับ Transfer Learning ของมหาวิทยาลัยวลัยลักษณ์
- รูปแบบธุรกิจ: เน้นโมเดล B2B และ B2B2C ร่วมกับโรงพยาบาลและคลินิกสุขภาพจิต (Hospital Partnership) ในการทำจุดคัดกรองเบื้องต้น OPD (Triage Tool 90 วินาที) และบริการให้เช่าอุปกรณ์สำหรับเฝ้าระวังที่บ้าน (Remote Patient Monitoring)',
'general',
ARRAY['TRL', 'SRL', 'ความพร้อม', 'สิทธิบัตร', 'โมเดลธุรกิจ', 'โรงพยาบาล'],
'{"source": "Higher Education Innovation Awards 2026"}')

ON CONFLICT (title) DO NOTHING;


-- =========================================================================
-- 23. ตรวจผล
-- =========================================================================
SELECT
    (SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS tables_in_public, -- ควรได้ 16
    (SELECT COUNT(*) FROM knowledge_base) AS knowledge_rows,                              -- ควรได้ 29
    (SELECT COUNT(*) FROM storage.buckets WHERE id = 'avatars') AS avatar_bucket;         -- ควรได้ 1

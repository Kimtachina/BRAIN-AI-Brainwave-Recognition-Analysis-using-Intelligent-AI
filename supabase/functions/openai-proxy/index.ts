// openai-proxy: เรียก OpenAI แทนแอป เพื่อไม่ให้ OPENAI_API_KEY อยู่ในตัวแอปหรือเว็บ
//
// Deploy:
//   supabase secrets set OPENAI_API_KEY=sk-...
//   supabase functions deploy openai-proxy
//
// รับเฉพาะผู้ใช้ที่ล็อกอินแล้ว (ตรวจ JWT ของ Supabase Auth) และล็อกโมเดล/ขนาดคำขอไว้ฝั่ง server
//
// คำขอที่รองรับ:
//   POST JSON { action: "chat", messages, max_tokens?, temperature? }  → ผลลัพธ์ของ /v1/chat/completions
//   POST JSON { action: "embedding", input }                          → ผลลัพธ์ของ /v1/embeddings
//   POST multipart/form-data มีฟิลด์ file                              → ผลลัพธ์ของ /v1/audio/transcriptions
//
// ตรรกะทั้งหมดอยู่ใน handler.ts (มี test ที่ supabase/functions/tests/)

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createHandler } from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

async function isAuthenticated(authorization: string): Promise<boolean> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authorization } },
  });
  const { data, error } = await supabase.auth.getUser();
  return !error && !!data.user;
}

Deno.serve(createHandler({
  openaiApiKey: Deno.env.get("OPENAI_API_KEY") ?? "",
  isAuthenticated,
}));

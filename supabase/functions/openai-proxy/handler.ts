// ตัวจัดการคำขอของ openai-proxy แยกออกจาก index.ts เพื่อให้ทดสอบได้
// (ไม่ใช้ Deno หรือ import จาก jsr: ในไฟล์นี้ ผู้เรียกส่งการตรวจผู้ใช้และ fetch เข้ามาเอง)

export const CHAT_MODEL = "gpt-4o-mini";
export const EMBEDDING_MODEL = "text-embedding-3-small";
export const TRANSCRIBE_MODEL = "whisper-1";

export const MAX_CHAT_TOKENS = 1200;
export const MAX_CHAT_MESSAGES = 30;
export const MAX_INPUT_CHARS = 20_000;
export const MAX_AUDIO_BYTES = 10 * 1024 * 1024;

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export interface ProxyDeps {
  openaiApiKey: string;
  /** คืน true ถ้า Authorization header เป็นของผู้ใช้ที่ล็อกอินอยู่ */
  isAuthenticated: (authorization: string) => Promise<boolean>;
  fetch?: typeof fetch;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function error(message: string, status: number): Response {
  return json({ error: { message } }, status);
}

type Forward = (path: string, init: RequestInit) => Promise<Response>;

/** ส่งคำขอต่อไปยัง OpenAI โดยแนบ API key ฝั่งเซิร์ฟเวอร์ แล้วคืนผลลัพธ์พร้อม CORS headers */
function makeForward(deps: ProxyDeps): Forward {
  const fetchImpl = deps.fetch ?? fetch;
  return async (path, init) => {
    const res = await fetchImpl(`https://api.openai.com/v1/${path}`, {
      ...init,
      headers: {
        ...(init.headers as Record<string, string> | undefined ?? {}),
        Authorization: `Bearer ${deps.openaiApiKey}`,
      },
    });
    return new Response(await res.text(), {
      status: res.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  };
}

async function chat(body: Record<string, unknown>, forward: Forward): Promise<Response> {
  const messages = body.messages;
  if (!Array.isArray(messages) || messages.length === 0) {
    return error("messages is required", 400);
  }
  if (messages.length > MAX_CHAT_MESSAGES) {
    return error(`messages must have at most ${MAX_CHAT_MESSAGES} items`, 400);
  }
  const totalChars = messages.reduce(
    (n, m) => n + String((m as { content?: unknown })?.content ?? "").length,
    0,
  );
  if (totalChars > MAX_INPUT_CHARS * 2) return error("messages too long", 413);

  const maxTokens = Math.min(Number(body.max_tokens) || 800, MAX_CHAT_TOKENS);
  const temperature = Math.min(Math.max(Number(body.temperature ?? 0.7), 0), 1.5);

  return forward("chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: CHAT_MODEL, messages, max_tokens: maxTokens, temperature }),
  });
}

async function embedding(body: Record<string, unknown>, forward: Forward): Promise<Response> {
  const input = body.input;
  if (typeof input !== "string" || input.length === 0) return error("input is required", 400);
  if (input.length > MAX_INPUT_CHARS) return error("input too long", 413);

  return forward("embeddings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: EMBEDDING_MODEL, input }),
  });
}

async function transcribe(req: Request, forward: Forward): Promise<Response> {
  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) return error("file is required", 400);
  if (file.size > MAX_AUDIO_BYTES) return error("file too large", 413);

  const out = new FormData();
  out.append("file", file, file.name || "audio.m4a");
  out.append("model", TRANSCRIBE_MODEL);
  out.append("language", String(form.get("language") ?? "th"));
  out.append("response_format", "json");

  return forward("audio/transcriptions", { method: "POST", body: out });
}

/** คืน Response ทันทีถ้าคำขอนี้ไม่ต้องหรือไม่ควรส่งต่อ (preflight, method ผิด, ไม่มี key, ไม่ได้ล็อกอิน) */
async function rejectRequest(req: Request, deps: ProxyDeps): Promise<Response | null> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return error("method not allowed", 405);
  if (!deps.openaiApiKey) return error("OPENAI_API_KEY is not set on the server", 500);

  // ตรวจว่าเป็นผู้ใช้ที่ล็อกอินจริง ไม่ใช่แค่ anon key
  const authorized = await deps.isAuthenticated(req.headers.get("Authorization") ?? "");
  return authorized ? null : error("unauthorized", 401);
}

/** เลือกงานตามชนิดคำขอ: multipart = ถอดเสียง, JSON = ตาม action */
async function route(req: Request, forward: Forward): Promise<Response> {
  const contentType = req.headers.get("content-type") ?? "";
  if (contentType.startsWith("multipart/form-data")) return await transcribe(req, forward);

  const body = await req.json();
  switch (body?.action) {
    case "chat":
      return await chat(body, forward);
    case "embedding":
      return await embedding(body, forward);
    default:
      return error("unknown action", 400);
  }
}

export function createHandler(deps: ProxyDeps): (req: Request) => Promise<Response> {
  const forward = makeForward(deps);

  return async (req: Request): Promise<Response> => {
    const rejected = await rejectRequest(req, deps);
    if (rejected) return rejected;

    try {
      return await route(req, forward);
    } catch (e) {
      return error(`proxy error: ${e instanceof Error ? e.message : String(e)}`, 500);
    }
  };
}

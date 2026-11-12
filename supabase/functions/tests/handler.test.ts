// Test ของ openai-proxy/handler.ts (รันด้วย: bun test supabase/functions)
// จำลองการตรวจผู้ใช้และ fetch ไปยัง OpenAI ทั้งหมด ไม่มีการเรียกเน็ตจริง

import { describe, expect, test } from "bun:test";
import {
  CHAT_MODEL,
  createHandler,
  EMBEDDING_MODEL,
  MAX_AUDIO_BYTES,
  MAX_CHAT_MESSAGES,
  MAX_CHAT_TOKENS,
  TRANSCRIBE_MODEL,
} from "../openai-proxy/handler.ts";

const URL = "https://example.supabase.co/functions/v1/openai-proxy";

type Call = { url: string; init: RequestInit };

function setup(opts: { key?: string; loggedIn?: boolean; reply?: unknown; status?: number } = {}) {
  const calls: Call[] = [];
  const authHeaders: string[] = [];
  const handler = createHandler({
    openaiApiKey: opts.key ?? "sk-test",
    isAuthenticated: async (auth) => {
      authHeaders.push(auth);
      return opts.loggedIn ?? true;
    },
    fetch: (async (url: string, init: RequestInit) => {
      calls.push({ url: String(url), init });
      return new Response(JSON.stringify(opts.reply ?? { ok: true }), { status: opts.status ?? 200 });
    }) as unknown as typeof fetch,
  });
  return { handler, calls, authHeaders };
}

function post(body: unknown, headers: Record<string, string> = {}) {
  return new Request(URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer user-jwt", ...headers },
    body: JSON.stringify(body),
  });
}

async function errorMessage(res: Response) {
  return ((await res.json()) as { error: { message: string } }).error.message;
}

describe("request checks", () => {
  test("OPTIONS returns CORS headers", async () => {
    const { handler } = setup();
    const res = await handler(new Request(URL, { method: "OPTIONS" }));
    expect(res.status).toBe(200);
    expect(res.headers.get("Access-Control-Allow-Origin")).toBe("*");
  });

  test("GET is rejected", async () => {
    const { handler } = setup();
    expect((await handler(new Request(URL))).status).toBe(405);
  });

  test("missing OpenAI key returns 500 before checking the user", async () => {
    const { handler, authHeaders } = setup({ key: "" });
    const res = await handler(post({ action: "chat", messages: [{ role: "user", content: "hi" }] }));
    expect(res.status).toBe(500);
    expect(await errorMessage(res)).toContain("OPENAI_API_KEY");
    expect(authHeaders).toHaveLength(0);
  });

  test("user who is not logged in gets 401 and OpenAI is not called", async () => {
    const { handler, calls, authHeaders } = setup({ loggedIn: false });
    const res = await handler(post({ action: "chat", messages: [{ role: "user", content: "hi" }] }));
    expect(res.status).toBe(401);
    expect(calls).toHaveLength(0);
    expect(authHeaders).toEqual(["Bearer user-jwt"]);
  });

  test("unknown action returns 400", async () => {
    const { handler } = setup();
    expect((await handler(post({ action: "draw" }))).status).toBe(400);
  });

  test("invalid JSON returns 500 proxy error", async () => {
    const { handler } = setup();
    const req = new Request(URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "{not json",
    });
    const res = await handler(req);
    expect(res.status).toBe(500);
    expect(await errorMessage(res)).toContain("proxy error");
  });
});

describe("chat", () => {
  test("forwards with the locked model and the server key", async () => {
    const { handler, calls } = setup({ reply: { choices: [] } });
    const messages = [{ role: "user", content: "สวัสดี" }];
    const res = await handler(post({ action: "chat", messages, model: "gpt-4o", max_tokens: 100 }));

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ choices: [] });
    expect(calls[0].url).toBe("https://api.openai.com/v1/chat/completions");
    const headers = calls[0].init.headers as Record<string, string>;
    expect(headers.Authorization).toBe("Bearer sk-test");
    const sent = JSON.parse(String(calls[0].init.body));
    expect(sent).toEqual({ model: CHAT_MODEL, messages, max_tokens: 100, temperature: 0.7 });
  });

  test("caps max_tokens and clamps temperature", async () => {
    const { handler, calls } = setup();
    await handler(post({
      action: "chat",
      messages: [{ role: "user", content: "hi" }],
      max_tokens: 999_999,
      temperature: 9,
    }));
    const sent = JSON.parse(String(calls[0].init.body));
    expect(sent.max_tokens).toBe(MAX_CHAT_TOKENS);
    expect(sent.temperature).toBe(1.5);
  });

  test("empty messages returns 400", async () => {
    const { handler, calls } = setup();
    expect((await handler(post({ action: "chat", messages: [] }))).status).toBe(400);
    expect(calls).toHaveLength(0);
  });

  test("too many messages returns 400", async () => {
    const { handler } = setup();
    const messages = Array.from({ length: MAX_CHAT_MESSAGES + 1 }, () => ({ role: "user", content: "x" }));
    expect((await handler(post({ action: "chat", messages }))).status).toBe(400);
  });

  test("messages that are too long return 413", async () => {
    const { handler } = setup();
    const messages = [{ role: "user", content: "x".repeat(40_001) }];
    expect((await handler(post({ action: "chat", messages }))).status).toBe(413);
  });

  test("OpenAI error status is passed through", async () => {
    const { handler } = setup({ status: 429, reply: { error: { message: "rate limit" } } });
    const res = await handler(post({ action: "chat", messages: [{ role: "user", content: "hi" }] }));
    expect(res.status).toBe(429);
    expect(await errorMessage(res)).toBe("rate limit");
  });
});

describe("embedding", () => {
  test("forwards input with the embedding model", async () => {
    const { handler, calls } = setup();
    const res = await handler(post({ action: "embedding", input: "คลื่นสมอง" }));
    expect(res.status).toBe(200);
    expect(calls[0].url).toBe("https://api.openai.com/v1/embeddings");
    expect(JSON.parse(String(calls[0].init.body))).toEqual({ model: EMBEDDING_MODEL, input: "คลื่นสมอง" });
  });

  test("missing input returns 400", async () => {
    const { handler } = setup();
    expect((await handler(post({ action: "embedding" }))).status).toBe(400);
  });

  test("input that is too long returns 413", async () => {
    const { handler } = setup();
    expect((await handler(post({ action: "embedding", input: "x".repeat(20_001) }))).status).toBe(413);
  });
});

describe("transcribe", () => {
  function audioRequest(file?: File, language?: string) {
    const form = new FormData();
    if (file) form.append("file", file);
    if (language) form.append("language", language);
    return new Request(URL, { method: "POST", headers: { Authorization: "Bearer user-jwt" }, body: form });
  }

  test("forwards the audio file with whisper and Thai by default", async () => {
    const { handler, calls } = setup({ reply: { text: "สวัสดี" } });
    const res = await handler(audioRequest(new File([new Uint8Array([1, 2, 3])], "voice.m4a")));

    expect(res.status).toBe(200);
    expect(calls[0].url).toBe("https://api.openai.com/v1/audio/transcriptions");
    const sent = calls[0].init.body as FormData;
    expect(sent.get("model")).toBe(TRANSCRIBE_MODEL);
    expect(sent.get("language")).toBe("th");
    expect((sent.get("file") as File).name).toBe("voice.m4a");
  });

  test("uses the requested language", async () => {
    const { handler, calls } = setup();
    await handler(audioRequest(new File([new Uint8Array([1])], "a.m4a"), "en"));
    expect((calls[0].init.body as FormData).get("language")).toBe("en");
  });

  test("missing file returns 400", async () => {
    const { handler } = setup();
    expect((await handler(audioRequest(undefined, "th"))).status).toBe(400);
  });

  test("file over the size limit returns 413", async () => {
    const { handler, calls } = setup();
    const big = new File([new Uint8Array(MAX_AUDIO_BYTES + 1)], "big.m4a");
    expect((await handler(audioRequest(big))).status).toBe(413);
    expect(calls).toHaveLength(0);
  });
});

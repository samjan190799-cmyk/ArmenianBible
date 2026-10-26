// Посредник Luys → ИИ. Приложение присылает вопрос и подписанное Apple подтверждение подписки;
// сервер проверяет подпись и срок, считает дневной лимит и только потом идёт к ИИ со своим ключом.
// Ключ ИИ хранится только как секрет Worker (GEMINI_API_KEY) и в приложение не попадает.

import { verifyAppleJws, checkEntitlement, VerifyError } from './apple.js';
import { generate, GenerateError } from './gemini.js';
import { parseBatch } from './events.js';
import { dashboardHtml } from './dashboard.js';

export { Quota } from './quota.js';
export { Stats } from './stats.js';

const MAX_BODY_BYTES = 24_000;
const MAX_EVENTS_BODY_BYTES = 12_000;
const MAX_PROMPT_CHARS = 8_000;
const MAX_SYSTEM_CHARS = 2_000;

function json(data, status = 200) {
  return Response.json(data, { status });
}

async function counter(env, name, limit, action = '/take') {
  const stub = env.QUOTA.get(env.QUOTA.idFromName(name));
  const res = await stub.fetch(`https://quota${action}`, { method: 'POST', body: JSON.stringify({ limit }) });
  return { ok: res.ok, ...(await res.json()) };
}

async function handleGenerate(request, env, deps) {
  if (!env.GEMINI_API_KEY) return json({ error: 'not_configured' }, 503);
  if (Number(request.headers.get('content-length') || 0) > MAX_BODY_BYTES) return json({ error: 'too_large' }, 413);

  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'bad_json' }, 400);
  }
  const prompt = typeof body.prompt === 'string' ? body.prompt : '';
  const system = typeof body.system === 'string' ? body.system : '';
  if (!prompt.trim() || prompt.length > MAX_PROMPT_CHARS || system.length > MAX_SYSTEM_CHARS) return json({ error: 'bad_request' }, 400);
  const maxTokens = Math.min(Math.max(Number(body.maxTokens) || 1024, 64), 4096);

  let payload;
  try {
    payload = await verifyAppleJws(body.transaction, { rootSha256: env.APPLE_ROOT_SHA256 || undefined });
  } catch (error) {
    return json({ error: 'unauthorized', reason: error instanceof VerifyError ? error.code : 'bad_format' }, 401);
  }
  const reason = checkEntitlement(payload, env, deps.now ? deps.now() : Date.now());
  if (reason) return json({ error: 'no_subscription', reason }, 403);

  const userName = `user:${payload.originalTransactionId}`;
  const userLimit = Number(env.DAILY_LIMIT) || 30;
  const globalLimit = Number(env.GLOBAL_DAILY_LIMIT) || 3000;

  const user = await counter(env, userName, userLimit);
  if (!user.ok) return json({ error: 'quota', used: user.used, limit: user.limit }, 429);
  const all = await counter(env, 'global', globalLimit);
  if (!all.ok) {
    await counter(env, userName, userLimit, '/refund');
    return json({ error: 'busy' }, 503);
  }

  try {
    const { text, model } = await generate(env, { prompt, system, json: body.json === true, maxTokens }, deps.fetch);
    return json({ text, model, remaining: Math.max(0, user.limit - user.used) });
  } catch (error) {
    // ИИ не ответил: вопрос человеку не засчитываем
    await counter(env, userName, userLimit, '/refund');
    await counter(env, 'global', globalLimit, '/refund');
    return json({ error: 'ai_failed', status: error instanceof GenerateError ? error.status : 502 }, 502);
  }
}

// --- Воронка: приём событий от приложения и сводка для владельца

function statsStub(env) {
  return env.STATS.get(env.STATS.idFromName('main'));
}

async function handleEvents(request, env) {
  if (!env.STATS) return json({ error: 'not_configured' }, 503);
  if (Number(request.headers.get('content-length') || 0) > MAX_EVENTS_BODY_BYTES) return json({ error: 'too_large' }, 413);
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'bad_json' }, 400);
  }
  const batch = parseBatch(body);
  if (!batch) return json({ error: 'bad_request' }, 400);
  const day = new Date().toISOString().slice(0, 10);
  const res = await statsStub(env).fetch('https://stats/ingest', { method: 'POST', body: JSON.stringify({ day, ...batch }) });
  const { accepted } = await res.json();
  return json({ ok: true, accepted });
}

/** Сравнение без утечки по времени: сначала хэши одинаковой длины, потом побайтово */
async function sameSecret(given, expected) {
  const hash = async (value) => new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value)));
  const [a, b] = await Promise.all([hash(given), hash(expected)]);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

async function handleStats(request, env, url) {
  if (!env.STATS || !env.STATS_TOKEN) return json({ error: 'not_configured' }, 503);
  const token = (request.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
  if (!token || !(await sameSecret(token, env.STATS_TOKEN))) return json({ error: 'unauthorized' }, 401);
  const days = Number(url.searchParams.get('days')) || 14;
  const res = await statsStub(env).fetch(`https://stats/report?days=${days}`);
  return json(await res.json());
}

export default {
  async fetch(request, env, ctx, deps = {}) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true, service: 'luys-ai', configured: Boolean(env.GEMINI_API_KEY), dailyLimit: Number(env.DAILY_LIMIT) || 30 });
    }
    if (request.method === 'POST' && url.pathname === '/v1/generate') {
      return handleGenerate(request, env, deps);
    }
    if (request.method === 'POST' && url.pathname === '/v1/events') {
      return handleEvents(request, env);
    }
    if (request.method === 'GET' && url.pathname === '/v1/stats') {
      return handleStats(request, env, url);
    }
    if (request.method === 'GET' && url.pathname === '/dashboard') {
      return new Response(dashboardHtml(), { headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store', 'x-robots-tag': 'noindex' } });
    }
    return json({ error: 'not_found' }, 404);
  }
};

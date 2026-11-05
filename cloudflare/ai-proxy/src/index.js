// Посредник Luys → ИИ. Подписчик присылает вопрос и подписанное Apple подтверждение подписки;
// сервер проверяет подпись и срок, считает дневной лимит и только потом идёт к ИИ со своим ключом.
// Бесплатный пользователь присылает вопрос и случайный номер установки: у него малый суточный лимит
// на установку и на сеть, а у всех бесплатных вместе свой потолок расходов.
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

/** Берёт по одному вопросу из каждого счётчика по порядку; если какой-то отказал, взятые возвращает */
async function takeAll(env, list) {
  const taken = [];
  for (const item of list) {
    const result = await counter(env, item.name, item.limit);
    if (!result.ok) {
      await giveBack(env, taken);
      return { ok: false, failed: item, result };
    }
    taken.push({ ...item, result });
  }
  return { ok: true, taken };
}

async function giveBack(env, taken) {
  for (const item of taken) await counter(env, item.name, item.limit, '/refund');
}

/** Сеть человека в счётчике хранится только как хэш с солью дня и секретом сервера: адрес по нему не подобрать перебором */
async function hashed(env, value) {
  const bytes = new TextEncoder().encode(`${new Date().toISOString().slice(0, 10)}|${env.GEMINI_API_KEY}|${value}`);
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return Array.from(digest.slice(0, 12), (b) => b.toString(16).padStart(2, '0')).join('');
}

const INSTALL_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

  const global = { name: 'global', limit: Number(env.GLOBAL_DAILY_LIMIT) || 3000, failure: 'busy' };
  let tier;
  let counters;
  let userLimit;
  let userName;

  if (typeof body.transaction === 'string' && body.transaction) {
    let payload;
    try {
      payload = await verifyAppleJws(body.transaction, { rootSha256: env.APPLE_ROOT_SHA256 || undefined });
    } catch (error) {
      return json({ error: 'unauthorized', reason: error instanceof VerifyError ? error.code : 'bad_format' }, 401);
    }
    const reason = checkEntitlement(payload, env, deps.now ? deps.now() : Date.now());
    if (reason) return json({ error: 'no_subscription', reason }, 403);

    tier = 'premium';
    userName = `user:${payload.originalTransactionId}`;
    userLimit = Number(env.DAILY_LIMIT) || 30;
    counters = [{ name: userName, limit: userLimit, failure: 'quota' }, global];
  } else if (typeof body.installId === 'string' && INSTALL_ID.test(body.installId)) {
    // Бесплатные вопросы: без подписки, поэтому лимит строже и есть отдельный потолок для всех бесплатных
    if (env.ALLOW_FREE === 'false') return json({ error: 'no_subscription', reason: 'free_disabled' }, 403);
    tier = 'free';
    userName = `free:${body.installId.toLowerCase()}`;
    userLimit = Number(env.FREE_DAILY_LIMIT) || 5;
    counters = [];
    const network = request.headers.get('cf-connecting-ip');
    if (network) {
      counters.push({ name: `net:${await hashed(env, network)}`, limit: Number(env.FREE_NET_DAILY_LIMIT) || 15, failure: 'quota' });
    }
    counters.push(
      { name: userName, limit: userLimit, failure: 'quota' },
      { name: 'free-global', limit: Number(env.FREE_GLOBAL_DAILY_LIMIT) || 300, failure: 'busy' },
      global
    );
  } else {
    return json({ error: 'unauthorized', reason: 'bad_format' }, 401);
  }

  const taken = await takeAll(env, counters);
  if (!taken.ok) {
    if (taken.failed.failure === 'quota') {
      return json({ error: 'quota', tier, used: taken.result.used, limit: taken.result.limit }, 429);
    }
    return json({ error: 'busy', tier }, 503);
  }
  const mine = taken.taken.find((item) => item.name === userName);

  try {
    const { text, model } = await generate(env, { prompt, system, json: body.json === true, maxTokens }, deps.fetch);
    return json({ text, model, tier, remaining: Math.max(0, mine.result.limit - mine.result.used) });
  } catch (error) {
    // ИИ не ответил: вопрос человеку не засчитываем
    await giveBack(env, taken.taken);
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

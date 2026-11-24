// Посредник Luys → ИИ. Подписчик присылает вопрос и подписанное Apple подтверждение подписки;
// сервер проверяет подпись и срок, считает дневной лимит и только потом идёт к ИИ со своим ключом.
// Бесплатный пользователь присылает вопрос и случайный номер установки: у него малый суточный лимит
// на установку и на сеть, а у всех бесплатных вместе свой потолок расходов.
// Ключ ИИ хранится только как секрет Worker (GEMINI_API_KEY) и в приложение не попадает.

import { verifyAppleJws, checkEntitlement, checkAppPurchase, appPurchaseId, VerifyError } from './apple.js';
import { generate, GenerateError } from './gemini.js';
import { normalizeTask, geminiEnvFor, taskDailyLimit } from './tasks.js';
import { parseBatch, countryOf } from './events.js';
import { dashboardHtml } from './dashboard.js';
import { giftPageHtml, duelPageHtml, roomPageHtml, PAGE_HEADERS } from './pages.js';
import { validCode } from './duel-room.js';
import { readCatalog } from './models.js';

export { Quota } from './quota.js';
export { Stats } from './stats.js';
export { DuelRoom } from './duel-do.js';

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

/** Какой счётчик отказал, без чужих номеров: свой лимит человека, установка, сеть или общий потолок */
function scopeOf(name) {
  if (name.startsWith('user:') || name.startsWith('early:')) return 'user';
  if (name.startsWith('free:')) return 'install';
  if (name.startsWith('net:')) return 'network';
  if (name.startsWith('task:')) return 'task';
  return name;
}

/** Сколько ждали ИИ, грубо: так видно, упираемся ли мы в таймауты */
function speedBucket(ms) {
  if (ms < 5_000) return 'lt5';
  if (ms < 15_000) return 's5_15';
  if (ms < 30_000) return 's15_30';
  return 's30p';
}

/** Одно слово для счётчика: строчные латиница, цифры и «_ . -», не длиннее 40 знаков */
function cleanNote(value) {
  return String(value ?? '').toLowerCase().replace(/[^a-z0-9_.-]+/g, '_').slice(0, 40);
}

/**
 * Исходы запросов к ИИ в счётчики владельца (страница /dashboard). Ни текста, ни номеров людей: только исход, задача,
 * уровень, причина сбоя и время. Сбой счётчика человеку не мешает; в Worker запись уходит в waitUntil и ответ не задерживает.
 */
async function noteAll(env, ctx, items) {
  if (!env.STATS) return;
  try {
    const clean = items.map(({ name, dims }) => {
      const out = {};
      for (const [key, value] of Object.entries(dims)) {
        const text = cleanNote(value);
        if (text) out[key] = text;
      }
      return { name, dims: out };
    });
    const day = new Date().toISOString().slice(0, 10);
    const work = statsStub(env)
      .fetch('https://stats/note', { method: 'POST', body: JSON.stringify({ day, items: clean }) })
      .then((res) => res.text())
      .catch(() => {});
    if (ctx && typeof ctx.waitUntil === 'function') ctx.waitUntil(work);
    else await work;
  } catch {
    // Счётчик нужен владельцу, а не человеку
  }
}

async function handleGenerate(request, env, deps, ctx) {
  const clock = deps.clock || Date.now;
  let task = 'general';
  let tier = 'none';
  // Исход запроса и попытки моделей уходят в счётчики владельца; ответ человеку от этого не меняется
  const done = async (response, result, extra = {}, attempts = []) => {
    await noteAll(env, ctx, [
      { name: 'ai_server', dims: { result, task, tier, ...extra } },
      ...attempts.map(({ model, kind }) => ({ name: 'ai_attempt', dims: { model, kind, modelkind: `${model}.${kind}` } }))
    ]);
    return response;
  };

  if (!env.GEMINI_API_KEY) return done(json({ error: 'not_configured' }, 503), 'not_configured');
  if (Number(request.headers.get('content-length') || 0) > MAX_BODY_BYTES) return done(json({ error: 'too_large' }, 413), 'too_large');

  let body;
  try {
    body = await request.json();
  } catch {
    return done(json({ error: 'bad_json' }, 400), 'bad_json');
  }
  if (!body || typeof body !== 'object') return done(json({ error: 'bad_json' }, 400), 'bad_json');
  const prompt = typeof body.prompt === 'string' ? body.prompt : '';
  const system = typeof body.system === 'string' ? body.system : '';
  if (!prompt.trim() || prompt.length > MAX_PROMPT_CHARS || system.length > MAX_SYSTEM_CHARS) return done(json({ error: 'bad_request' }, 400), 'bad_request');
  const maxTokens = Math.min(Math.max(Number(body.maxTokens) || 1024, 64), 4096);
  // Для какой задачи запрос: у задачи может быть свой ключ Gemini, свои модели и суточный потолок (см. tasks.js)
  task = normalizeTask(body.task);

  const global = { name: 'global', limit: Number(env.GLOBAL_DAILY_LIMIT) || 3000, failure: 'busy' };
  let counters;
  let userLimit;
  let userName;

  if (typeof body.transaction === 'string' && body.transaction) {
    let payload;
    try {
      payload = await verifyAppleJws(body.transaction, { rootSha256: env.APPLE_ROOT_SHA256 || undefined });
    } catch (error) {
      const why = error instanceof VerifyError ? error.code : 'bad_format';
      return done(json({ error: 'unauthorized', reason: why }, 401), 'unauthorized', { why });
    }
    // Подтверждение бывает двух видов: покупка товара (подписка или пожизненная, есть productId) и покупка самого приложения
    // (AppTransaction: ранний покупатель платной версии 1.x, productId нет, зато есть originalAppVersion)
    const isAppPurchase = payload.productId === undefined && typeof payload.originalAppVersion === 'string';
    const reason = isAppPurchase ? checkAppPurchase(payload, env) : checkEntitlement(payload, env, deps.now ? deps.now() : Date.now());
    if (reason) return done(json({ error: 'no_subscription', reason }, 403), 'no_subscription', { why: reason });

    tier = 'premium';
    userName = isAppPurchase ? `early:${appPurchaseId(payload)}` : `user:${payload.originalTransactionId}`;
    userLimit = Number(env.DAILY_LIMIT) || 30;
    counters = [{ name: userName, limit: userLimit, failure: 'quota' }, global];
  } else if (typeof body.installId === 'string' && INSTALL_ID.test(body.installId)) {
    // Бесплатные вопросы: без подписки, поэтому лимит строже и есть отдельный потолок для всех бесплатных
    // ИИ-викторина только по подписке: задача quiz на бесплатный путь не пускается (классическая офлайн-викторина сервера не требует)
    tier = 'free';
    // ИИ-уровни игры «Собери стих» тоже только по подписке: задача puzzle на бесплатный путь не пускается (классические уровни ИИ не требуют)
    if (task === 'puzzle' && env.PUZZLE_PAID_ONLY !== 'false') return done(json({ error: 'no_subscription', reason: 'puzzle_premium' }, 403), 'no_subscription', { why: 'puzzle_premium' });
    if (task === 'quiz' && env.QUIZ_PAID_ONLY !== 'false') return done(json({ error: 'no_subscription', reason: 'quiz_premium' }, 403), 'no_subscription', { why: 'quiz_premium' });
    if (env.ALLOW_FREE === 'false') return done(json({ error: 'no_subscription', reason: 'free_disabled' }, 403), 'no_subscription', { why: 'free_disabled' });
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
    return done(json({ error: 'unauthorized', reason: 'bad_format' }, 401), 'unauthorized', { why: 'bad_format' });
  }

  const perTaskLimit = taskDailyLimit(env, task);
  if (perTaskLimit > 0) counters.push({ name: `task:${task}`, limit: perTaskLimit, failure: 'busy' });

  const taken = await takeAll(env, counters);
  if (!taken.ok) {
    const scope = scopeOf(taken.failed.name);
    if (taken.failed.failure === 'quota') {
      return done(json({ error: 'quota', tier, used: taken.result.used, limit: taken.result.limit }, 429), 'quota', { why: scope });
    }
    return done(json({ error: 'busy', tier }, 503), 'busy', { why: scope });
  }
  const mine = taken.taken.find((item) => item.name === userName);

  const aiStarted = clock();
  try {
    const { text, model, trail } = await generate(geminiEnvFor(env, task), { prompt, system, json: body.json === true, maxTokens }, deps.fetch, clock);
    const extra = { speed: speedBucket(clock() - aiStarted) };
    if (trail.length > 0) extra.fallback = 'yes';
    return done(
      json({ text, model, tier, remaining: Math.max(0, mine.result.limit - mine.result.used) }),
      'ok',
      extra,
      [...trail, { model, kind: 'ok' }]
    );
  } catch (error) {
    // ИИ не ответил: вопрос человеку не засчитываем
    await giveBack(env, taken.taken);
    const trail = error instanceof GenerateError ? error.trail : [];
    const why = trail.length > 0 ? trail[trail.length - 1].kind : error instanceof GenerateError ? `http_${error.status}` : 'exception';
    return done(
      json({ error: 'ai_failed', status: error instanceof GenerateError ? error.status : 502 }, 502),
      'ai_failed',
      { why, taskwhy: `${task}.${why}`, speed: speedBucket(clock() - aiStarted) },
      trail
    );
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
  const res = await statsStub(env).fetch('https://stats/ingest', { method: 'POST', body: JSON.stringify({ day, country: countryOf(request), ...batch }) });
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

/** null, если токен владельца верный; иначе готовый ответ с отказом */
async function denyUnlessOwner(request, env) {
  if (!env.STATS || !env.STATS_TOKEN) return json({ error: 'not_configured' }, 503);
  const token = (request.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
  if (!token || !(await sameSecret(token, env.STATS_TOKEN))) return json({ error: 'unauthorized' }, 401);
  return null;
}

async function handleStats(request, env, url) {
  const denied = await denyUnlessOwner(request, env);
  if (denied) return denied;
  const days = Number(url.searchParams.get('days')) || 14;
  const res = await statsStub(env).fetch(`https://stats/report?days=${days}`);
  return json(await res.json());
}

async function handleStatsReset(request, env) {
  const denied = await denyUnlessOwner(request, env);
  if (denied) return denied;
  const res = await statsStub(env).fetch('https://stats/reset', { method: 'POST' });
  return json(await res.json());
}

export default {
  async fetch(request, env, ctx, deps = {}) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true, service: 'luys-ai', configured: Boolean(env.GEMINI_API_KEY), dailyLimit: Number(env.DAILY_LIMIT) || 30 });
    }
    if (request.method === 'POST' && url.pathname === '/v1/generate') {
      return handleGenerate(request, env, deps, ctx);
    }
    // Актуальные модели для кнопки «Обновить модели» в приложении. Открытый список: ни ключей, ни данных людей в нём нет
    if (request.method === 'GET' && url.pathname === '/v1/models') {
      return Response.json(readCatalog(env), { headers: { 'cache-control': 'public, max-age=3600' } });
    }
    if (request.method === 'POST' && url.pathname === '/v1/events') {
      return handleEvents(request, env);
    }
    if (request.method === 'GET' && url.pathname === '/v1/stats') {
      return handleStats(request, env, url);
    }
    if (request.method === 'POST' && url.pathname === '/v1/stats/reset') {
      return handleStatsReset(request, env);
    }
    // Страницы ссылок «для двоих»: лист в подарок и вызов на дуэль. Данные в части после «#», сервер их не видит
    const room = /^\/v1\/duel\/([^/]+)$/.exec(url.pathname);
    if (request.method === 'GET' && room) {
      // Дуэль в реальном времени: каждой комнате свой Durable Object, соединение — WebSocket
      if (!validCode(room[1])) return json({ error: 'bad_code' }, 400);
      if (request.headers.get('Upgrade') !== 'websocket') return json({ error: 'websocket_required' }, 426);
      if (!env.DUEL) return json({ error: 'duel_unavailable' }, 503);
      return env.DUEL.get(env.DUEL.idFromName(room[1])).fetch(request);
    }
    if (request.method === 'GET' && url.pathname === '/r') {
      return new Response(roomPageHtml(), { headers: PAGE_HEADERS });
    }
    if (request.method === 'GET' && url.pathname === '/g') {
      return new Response(giftPageHtml(), { headers: PAGE_HEADERS });
    }
    if (request.method === 'GET' && url.pathname === '/d') {
      return new Response(duelPageHtml(), { headers: PAGE_HEADERS });
    }
    if (request.method === 'GET' && url.pathname === '/dashboard') {
      return new Response(dashboardHtml(), { headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store', 'x-robots-tag': 'noindex' } });
    }
    return json({ error: 'not_found' }, 404);
  }
};

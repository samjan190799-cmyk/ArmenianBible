// Причины сбоев ИИ: что видит сервер по каждой модели, общий срок на запрос и счётчики для страницы /dashboard.
// Бесплатный путь (по номеру установки) не требует подписи Apple, поэтому тесты не зависят от openssl.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { Quota } from '../src/quota.js';
import { Stats } from '../src/stats.js';
import { generate, GenerateError } from '../src/gemini.js';
import { DASHBOARD_SCRIPT } from '../src/dashboard.js';

class FakeStorage {
  constructor() {
    this.map = new Map();
  }
  async get(key) {
    return this.map.get(key);
  }
  async put(key, value) {
    this.map.set(key, value);
  }
  async list({ prefix }) {
    return new Map([...this.map].filter(([key]) => key.startsWith(prefix)));
  }
  async deleteAll() {
    this.map.clear();
  }
}

function quotaNamespace() {
  const objects = new Map();
  return {
    idFromName: (name) => name,
    get(id) {
      if (!objects.has(id)) objects.set(id, new Quota({ storage: new FakeStorage() }));
      const object = objects.get(id);
      return { fetch: (url, init) => object.fetch(new Request(url, init)) };
    }
  };
}

function statsNamespace() {
  const stats = new Stats({ storage: new FakeStorage() });
  return { idFromName: (name) => name, get: () => ({ fetch: (url, init) => stats.fetch(new Request(url, init)) }) };
}

function makeEnv(overrides = {}) {
  return {
    GEMINI_API_KEY: 'test-key',
    GLOBAL_DAILY_LIMIT: '100',
    FREE_DAILY_LIMIT: '2',
    FREE_NET_DAILY_LIMIT: '50',
    FREE_GLOBAL_DAILY_LIMIT: '50',
    STATS_TOKEN: 'secret',
    QUOTA: quotaNamespace(),
    STATS: statsNamespace(),
    ...overrides
  };
}

const INSTALL = '00000000-0000-4000-8000-000000000001';
const answer = (text = 'Ответ ИИ') => Response.json({ candidates: [{ content: { parts: [{ text }] } }] });

function ask(env, extra = {}, deps = { fetch: async () => answer() }, ctx = {}) {
  const body = { prompt: 'Что значит «Бог есть любовь»?', installId: INSTALL, ...extra };
  const request = new Request('https://luys.example/v1/generate', { method: 'POST', body: JSON.stringify(body) });
  return worker.fetch(request, env, ctx, deps);
}

async function report(env) {
  const res = await worker.fetch(new Request('https://luys.example/v1/stats?days=1', { headers: { authorization: 'Bearer secret' } }), env, {});
  return (await res.json()).events;
}

// --- gemini.js: что вышло у каждой модели

test('generate: неудачи моделей попадают в trail, ответ берётся у первой ответившей', async () => {
  const replies = [
    () => new Response('overloaded', { status: 503 }),
    () => Response.json({ candidates: [{ finishReason: 'SAFETY' }] }),
    () => answer('Готово')
  ];
  let calls = 0;
  const fetchFn = async () => replies[calls++]();
  const out = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b,m-c' }, { prompt: 'p', maxTokens: 100 }, fetchFn);
  assert.equal(out.text, 'Готово');
  assert.equal(out.model, 'm-c');
  assert.deepEqual(out.trail, [{ model: 'm-a', kind: 'http_503' }, { model: 'm-b', kind: 'empty_safety' }]);
});

test('generate: без неудач trail пустой', async () => {
  const out = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a' }, { prompt: 'p', maxTokens: 100 }, async () => answer());
  assert.deepEqual(out.trail, []);
});

test('generate: блокировка запроса Google и пустой ответ без причины различаются', async () => {
  const replies = [
    () => Response.json({ promptFeedback: { blockReason: 'PROHIBITED_CONTENT' } }),
    () => Response.json({ candidates: [] }),
    () => Response.json({ candidates: [{ finishReason: 'MAX_TOKENS' }] })
  ];
  let calls = 0;
  await assert.rejects(
    generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b,m-c' }, { prompt: 'p', maxTokens: 100 }, async () => replies[calls++]()),
    (error) => {
      assert.ok(error instanceof GenerateError);
      assert.equal(error.status, 502);
      assert.deepEqual(error.trail.map((item) => item.kind), ['blocked_prohibited_content', 'empty', 'empty_max_tokens']);
      return true;
    }
  );
});

test('generate: таймаут, обрыв сети и ошибка Google отличаются в trail', async () => {
  const steps = [
    () => { throw new DOMException('slow', 'TimeoutError'); },
    () => { throw new TypeError('fetch failed'); },
    () => new Response('boom', { status: 500 })
  ];
  let calls = 0;
  await assert.rejects(
    generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b,m-c' }, { prompt: 'p', maxTokens: 100 }, async () => steps[calls++]()),
    (error) => {
      assert.deepEqual(error.trail.map((item) => item.kind), ['timeout', 'net', 'http_500']);
      assert.equal(error.status, 500);
      return true;
    }
  );
});

test('generate: 429 от Google не заканчивает попытки, trail показывает каждую модель', async () => {
  let calls = 0;
  await assert.rejects(
    generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b' }, { prompt: 'p', maxTokens: 100 }, async () => {
      calls += 1;
      return new Response('', { status: 429 });
    }),
    (error) => error.status === 429 && error.trail.length === 2 && error.trail.every((item) => item.kind === 'http_429')
  );
  assert.equal(calls, 2);
});

test('generate: 403 от Google заканчивает попытки сразу, и trail это показывает', async () => {
  let calls = 0;
  await assert.rejects(
    generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b' }, { prompt: 'p', maxTokens: 100 }, async () => {
      calls += 1;
      return new Response('', { status: 403 });
    }),
    (error) => error.status === 403 && error.trail.length === 1 && error.trail[0].kind === 'http_403'
  );
  assert.equal(calls, 1);
});

test('generate: общий срок 45 секунд, когда он вышел, следующая модель не пробуется', async () => {
  let now = 0;
  let calls = 0;
  const fetchFn = async () => {
    calls += 1;
    now += calls === 1 ? 25_000 : 20_500;
    throw new DOMException('slow', 'TimeoutError');
  };
  await assert.rejects(
    generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a,m-b,m-c' }, { prompt: 'p', maxTokens: 100 }, fetchFn, () => now),
    (error) => error.status === 504 && error.trail.length === 2
  );
  assert.equal(calls, 2, 'третья модель уже не успеет, приложение ждёт не больше минуты');
});

test('generate: первая модель пробуется всегда, даже если часы ушли вперёд', async () => {
  let now = 1_000_000;
  const out = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'm-a' }, { prompt: 'p', maxTokens: 100 }, async () => answer(), () => now);
  assert.equal(out.model, 'm-a');
});

// --- Worker: счётчики исходов

test('счётчики: удачный ответ записывается с задачей, уровнем и временем ожидания', async () => {
  const env = makeEnv();
  let t = 0;
  const deps = { fetch: async () => { t += 7_000; return answer(); }, clock: () => t };
  const res = await ask(env, { task: 'chat' }, deps);
  assert.equal(res.status, 200);
  const e = await report(env);
  assert.equal(e.ai_server[''].events, 1);
  assert.equal(e.ai_server['result=ok'].events, 1);
  assert.equal(e.ai_server['task=chat'].events, 1);
  assert.equal(e.ai_server['tier=free'].events, 1);
  assert.equal(e.ai_server['speed=s5_15'].events, 1);
  assert.equal(e.ai_server['fallback=yes'], undefined, 'без запасной модели отметки нет');
  assert.equal(e.ai_attempt['modelkind=gemini-3.5-flash-lite.ok'].events, 1);
});

test('счётчики: ответ запасной модели помечается, неудача первой видна по модели', async () => {
  const env = makeEnv();
  let calls = 0;
  const deps = { fetch: async () => (calls++ === 0 ? new Response('overloaded', { status: 503 }) : answer()) };
  assert.equal((await ask(env, { task: 'explain' }, deps)).status, 200);
  const e = await report(env);
  assert.equal(e.ai_server['result=ok'].events, 1);
  assert.equal(e.ai_server['fallback=yes'].events, 1);
  assert.equal(e.ai_attempt['modelkind=gemini-3.5-flash-lite.http_503'].events, 1);
  assert.equal(e.ai_attempt['modelkind=gemini-3.6-flash.ok'].events, 1);
});

test('счётчики: сбой ИИ записывается с причиной, задачей и моделями, а вопрос человеку не списан', async () => {
  const env = makeEnv({ FREE_DAILY_LIMIT: '1' });
  const failing = { fetch: async () => new Response('overloaded', { status: 503 }) };
  const res = await ask(env, { task: 'consolation' }, failing);
  assert.equal(res.status, 502);
  const e = await report(env);
  assert.equal(e.ai_server['result=ai_failed'].events, 1);
  assert.equal(e.ai_server['why=http_503'].events, 1);
  assert.equal(e.ai_server['taskwhy=consolation.http_503'].events, 1);
  assert.equal(e.ai_attempt[''].events, 3, 'три модели по умолчанию, по записи на каждую');
  assert.equal(e.ai_attempt['modelkind=gemini-3.6-flash.http_503'].events, 1);
  assert.equal((await ask(env)).status, 200, 'лимит 1: вопрос не сгорел');
});

test('счётчики: сбой из-за блокировки Google записывается как причина блокировки', async () => {
  const env = makeEnv();
  const blocked = { fetch: async () => Response.json({ promptFeedback: { blockReason: 'SAFETY' } }) };
  assert.equal((await ask(env, { task: 'consolation' }, blocked)).status, 502);
  const e = await report(env);
  assert.equal(e.ai_server['taskwhy=consolation.blocked_safety'].events, 1);
});

test('счётчики: лимит записывается с тем, что отказало (установка), без номеров', async () => {
  const env = makeEnv({ FREE_DAILY_LIMIT: '1' });
  assert.equal((await ask(env)).status, 200);
  assert.equal((await ask(env)).status, 429);
  const e = await report(env);
  assert.equal(e.ai_server['result=quota'].events, 1);
  assert.equal(e.ai_server['why=install'].events, 1);
  assert.ok(!JSON.stringify(e).includes(INSTALL), 'номера установки в счётчиках нет');
});

test('счётчики: общий потолок бесплатных записывается как free-global', async () => {
  const env = makeEnv({ FREE_GLOBAL_DAILY_LIMIT: '1' });
  assert.equal((await ask(env)).status, 200);
  const other = await ask(env, { installId: '00000000-0000-4000-8000-000000000002' });
  assert.equal(other.status, 503);
  const e = await report(env);
  assert.equal(e.ai_server['result=busy'].events, 1);
  assert.equal(e.ai_server['why=free-global'].events, 1);
});

test('счётчики: ИИ-викторина без подписки и плохой запрос записываются отдельными исходами', async () => {
  const env = makeEnv();
  assert.equal((await ask(env, { task: 'quiz' })).status, 403);
  assert.equal((await ask(env, { prompt: '   ' })).status, 400);
  assert.equal((await ask(env, { installId: 'не-номер' })).status, 401);
  const e = await report(env);
  assert.equal(e.ai_server['result=no_subscription'].events, 1);
  assert.equal(e.ai_server['why=quiz_premium'].events, 1);
  assert.equal(e.ai_server['result=bad_request'].events, 1);
  assert.equal(e.ai_server['result=unauthorized'].events, 1);
  assert.equal(e.ai_server['why=bad_format'].events, 1);
});

test('счётчики: запись уходит в waitUntil и не задерживает ответ', async () => {
  const env = makeEnv();
  const pending = [];
  const res = await ask(env, {}, undefined, { waitUntil: (work) => pending.push(work) });
  assert.equal(res.status, 200);
  assert.equal(pending.length, 1);
  await Promise.all(pending);
  assert.equal((await report(env)).ai_server['result=ok'].events, 1);
});

test('счётчики: сбой самих счётчиков человеку ответ не портит', async () => {
  const broken = { idFromName: (name) => name, get: () => ({ fetch: async () => { throw new Error('счётчики недоступны'); } }) };
  const env = makeEnv({ STATS: broken });
  const res = await ask(env);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).text, 'Ответ ИИ');
});

test('счётчики: без STATS всё работает, как раньше', async () => {
  const res = await ask(makeEnv({ STATS: undefined }));
  assert.equal(res.status, 200);
});

test('Stats.note: чужие имена и плохой день отбрасываются, неправильные ключи не попадают', async () => {
  const stats = new Stats({ storage: new FakeStorage() });
  const send = (body) => stats.fetch(new Request('https://stats/note', { method: 'POST', body: JSON.stringify(body) })).then((res) => res.json());
  const today = new Date().toISOString().slice(0, 10);
  assert.deepEqual(await send({ day: 'вчера', items: [{ name: 'ai_server', dims: { result: 'ok' } }] }), { accepted: 0 });
  assert.deepEqual(await send({ day: today, items: [{ name: 'app_open', dims: {} }, { name: 'ai_server', dims: { 'BAD KEY': 'x', result: 'ok', empty: '' } }] }), { accepted: 1 });
  const report = await (await stats.fetch(new Request('https://stats/report?days=1'))).json();
  assert.equal(report.events.app_open, undefined, 'имя не из списка серверных счётчиков отброшено');
  assert.deepEqual(Object.keys(report.events.ai_server).sort(), ['', 'result=ok'], 'плохой ключ и пустое значение отброшены');
});

test('Worker принимает счётчики только от себя: приложение не может прислать ai_server событием', async () => {
  const env = makeEnv();
  const body = { installId: INSTALL, app: '4.3', build: '1', lang: 'ru', premium: false, events: [{ name: 'ai_server', params: { result: 'ok' } }] };
  const res = await worker.fetch(new Request('https://luys.example/v1/events', { method: 'POST', body: JSON.stringify(body) }), env, {});
  assert.equal(res.status, 400, 'имени нет в белом списке событий приложения');
});

// --- Страница /dashboard

test('страница рисует блок «ИИ на сервере» из счётчиков без ошибок', async () => {
  const makeNode = () => ({
    children: [],
    className: '',
    textContent: '',
    appendChild(child) {
      this.children.push(child);
      return child;
    }
  });
  const app = makeNode();
  const document = { getElementById: () => app, createElement: () => makeNode() };
  const store = new Map([['luys_stats_token', 'secret']]);
  const localStorage = { getItem: (key) => store.get(key) ?? null, setItem: (key, value) => store.set(key, value), removeItem: (key) => store.delete(key) };
  const data = {
    days: ['2026-11-24'],
    daily: [{ day: '2026-11-24', active: 1, newInstalls: 0, paywallShown: 0, purchases: 0 }],
    events: {
      _active: { '': { events: 1, people: 1 } },
      ai_server: {
        '': { events: 4, people: 0 },
        'result=ok': { events: 3, people: 0 },
        'result=ai_failed': { events: 1, people: 0 },
        'task=chat': { events: 4, people: 0 },
        'speed=lt5': { events: 4, people: 0 },
        'taskwhy=chat.http_503': { events: 1, people: 0 }
      },
      ai_attempt: {
        '': { events: 5, people: 0 },
        'modelkind=gemini-3.5-flash-lite.http_503': { events: 1, people: 0 },
        'modelkind=gemini-3.5-flash-lite.ok': { events: 3, people: 0 }
      }
    }
  };
  const fetchFn = async () => ({ status: 200, ok: true, json: async () => data });
  const run = new Function('document', 'localStorage', 'fetch', 'prompt', 'alert', 'confirm', DASHBOARD_SCRIPT);
  run(document, localStorage, fetchFn, () => '', () => {}, () => true);
  await new Promise((resolve) => setTimeout(resolve, 20));

  const texts = [];
  (function walk(node) {
    if (node.textContent) texts.push(node.textContent);
    node.children.forEach(walk);
  })(app);
  const page = texts.join('\n');
  assert.match(page, /ИИ на сервере: исходы запросов \(4\)/);
  assert.match(page, /ответ дан/);
  assert.match(page, /Google не ответил \(502\)/);
  assert.match(page, /chat\.http_503/);
  assert.match(page, /ИИ на сервере: попытки по моделям \(5\)/);
  assert.match(page, /75%/, 'доля удачных ответов 3 из 4');
});

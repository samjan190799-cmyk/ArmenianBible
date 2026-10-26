import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { Stats } from '../src/stats.js';
import { parseBatch } from '../src/events.js';
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
}

function makeEnv(overrides = {}) {
  const stats = new Stats({ storage: new FakeStorage() });
  return {
    STATS_TOKEN: 'secret-token',
    STATS: {
      idFromName: (name) => name,
      get: () => ({ fetch: (url, init) => stats.fetch(new Request(url, init)) })
    },
    ...overrides
  };
}

const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';

function send(env, installId, events, extra = {}) {
  const body = { installId, app: '4.1', build: '436', lang: 'ru', premium: false, events, ...extra };
  return worker.fetch(new Request('https://luys.example/v1/events', { method: 'POST', body: JSON.stringify(body) }), env, {});
}

async function report(env, token = 'secret-token') {
  const res = await worker.fetch(new Request('https://luys.example/v1/stats?days=7', { headers: { authorization: `Bearer ${token}` } }), env, {});
  return { status: res.status, data: await res.json() };
}

test('parseBatch: лишнее отбрасывается, значения приводятся к нижнему регистру', () => {
  const batch = parseBatch({
    installId: A.toUpperCase(),
    lang: 'de',
    app: '4.1',
    events: [
      { name: 'paywall_shown', params: { source: 'AI', trial: 'yes', secret: 'x' } },
      { name: 'constructor', params: {} },
      { name: 'nope', params: {} }
    ]
  });
  assert.equal(batch.installId, A);
  assert.equal(batch.lang, 'xx');
  assert.equal(batch.events.length, 1);
  assert.deepEqual(batch.events[0].dims, { source: 'ai', trial: 'yes' });
});

test('parseBatch: чужой текст в параметрах не принимается', () => {
  const batch = parseBatch({ installId: A, events: [{ name: 'feature_used', params: { feature: 'john@example.com' } }, { name: 'feature_used', params: { feature: 'a b' } }] });
  assert.deepEqual(batch.events.map((e) => e.dims), [{}, {}]);
});

test('parseBatch: плохой идентификатор и пустая пачка отклоняются', () => {
  assert.equal(parseBatch({ installId: 'abc', events: [{ name: 'app_open' }] }), null);
  assert.equal(parseBatch({ installId: A, events: [] }), null);
  assert.equal(parseBatch({ installId: A, events: [{ name: 'nope' }] }), null);
  assert.equal(parseBatch(null), null);
});

test('события принимаются, сводка считает и раз, и разных людей', async () => {
  const env = makeEnv();
  assert.equal((await send(env, A, [{ name: 'app_open', params: { day: 'd0' } }, { name: 'paywall_shown', params: { source: 'ai', trial: 'yes' } }, { name: 'paywall_shown', params: { source: 'ai', trial: 'yes' } }])).status, 200);
  await send(env, B, [{ name: 'app_open', params: { day: 'd1' } }, { name: 'paywall_shown', params: { source: 'candle' } }, { name: 'purchase_result', params: { result: 'success', plan: 'yearly' } }], { premium: true });

  const { status, data } = await report(env);
  assert.equal(status, 200);
  const e = data.events;
  assert.deepEqual(e.app_open[''], { events: 2, people: 2 });
  assert.deepEqual(e.paywall_shown[''], { events: 3, people: 2 });
  assert.deepEqual(e.paywall_shown['source=ai'], { events: 2, people: 1 });
  assert.deepEqual(e.paywall_shown['source=candle'], { events: 1, people: 1 });
  assert.deepEqual(e.purchase_result['result=success'], { events: 1, people: 1 });
  assert.deepEqual(e._active[''], { events: 2, people: 2 });
  assert.equal(e._active['premium=yes'].events, 1);
  assert.equal(e._active['lang=ru'].events, 2);
  assert.equal(data.daily.at(-1).newInstalls, 2);
  assert.equal(data.daily.at(-1).paywallShown, 3);
  assert.equal(data.daily.at(-1).purchases, 1);
});

test('повторный приход того же человека не делает его новым', async () => {
  const env = makeEnv();
  await send(env, A, [{ name: 'app_open' }]);
  await send(env, A, [{ name: 'app_open' }]);
  const { data } = await report(env);
  assert.equal(data.daily.at(-1).newInstalls, 1);
  assert.equal(data.daily.at(-1).active, 1);
  assert.deepEqual(data.events.app_open[''], { events: 2, people: 1 });
});

test('потолок событий в сутки на одну установку', async () => {
  const env = makeEnv();
  const batch = Array.from({ length: 25 }, () => ({ name: 'feature_used', params: { feature: 'quiz' } }));
  let accepted = 0;
  for (let i = 0; i < 20; i++) accepted += (await (await send(env, A, batch)).json()).accepted;
  assert.equal(accepted, 400);
});

test('сводка закрыта токеном', async () => {
  const env = makeEnv();
  assert.equal((await report(env, 'wrong')).status, 401);
  assert.equal((await report(env, '')).status, 401);
  assert.equal((await report(makeEnv({ STATS_TOKEN: '' }))).status, 503);
});

test('плохие запросы к приёму событий', async () => {
  const env = makeEnv();
  assert.equal((await send(env, 'bad-id', [{ name: 'app_open' }])).status, 400);
  const notJson = await worker.fetch(new Request('https://luys.example/v1/events', { method: 'POST', body: 'x' }), env, {});
  assert.equal(notJson.status, 400);
  assert.equal((await worker.fetch(new Request('https://luys.example/v1/events', { method: 'POST', body: '{}' }), makeEnv({ STATS: undefined }), {})).status, 503);
});

test('страница /dashboard отдаётся без секретов, а её скрипт разбирается', async () => {
  const res = await worker.fetch(new Request('https://luys.example/dashboard'), makeEnv(), {});
  const html = await res.text();
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /text\/html/);
  assert.ok(!html.includes('secret-token'));
  assert.doesNotThrow(() => new Function(DASHBOARD_SCRIPT));
});

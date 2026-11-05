import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { Quota } from '../src/quota.js';
import { opensslAvailable, makeChain, makeJws, goodPayload } from './chain.js';

const skip = opensslAvailable() ? false : 'openssl не найден';
let chain;

before(() => {
  if (!skip) chain = makeChain('app-');
});

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
}

function fakeNamespace() {
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

function makeEnv(overrides = {}) {
  return {
    GEMINI_API_KEY: 'test-key',
    BUNDLE_ID: 'com.samvel.armenianbible',
    PRODUCT_IDS: 'com.samvel.armenianbible.subscription.monthly,com.samvel.armenianbible.subscription.yearly',
    DAILY_LIMIT: '2',
    GLOBAL_DAILY_LIMIT: '3',
    ALLOW_SANDBOX: 'true',
    APPLE_ROOT_SHA256: chain.rootSha,
    QUOTA: fakeNamespace(),
    ...overrides
  };
}

const okAi = async () => Response.json({ candidates: [{ content: { parts: [{ text: 'Ответ ИИ' }] } }] });

function ask(env, body, deps = { fetch: okAi }) {
  const request = new Request('https://luys.example/v1/generate', { method: 'POST', body: JSON.stringify(body) });
  return worker.fetch(request, env, {}, deps);
}

const validBody = (extra = {}) => ({ prompt: 'Что значит «Бог есть любовь»?', transaction: makeJws(chain, goodPayload()), ...extra });

test('health показывает, что сервис настроен', { skip }, async () => {
  const res = await worker.fetch(new Request('https://luys.example/health'), makeEnv(), {});
  const data = await res.json();
  assert.equal(res.status, 200);
  assert.equal(data.configured, true);
});

test('неизвестный путь — 404', { skip }, async () => {
  const res = await worker.fetch(new Request('https://luys.example/x'), makeEnv(), {});
  assert.equal(res.status, 404);
});

test('подписчик получает ответ', { skip }, async () => {
  const res = await ask(makeEnv(), validBody());
  const data = await res.json();
  assert.equal(res.status, 200);
  assert.equal(data.text, 'Ответ ИИ');
  assert.equal(data.remaining, 1);
});

test('лимит в сутки: третий вопрос при лимите 2 получает 429', { skip }, async () => {
  const env = makeEnv();
  assert.equal((await ask(env, validBody())).status, 200);
  assert.equal((await ask(env, validBody())).status, 200);
  const third = await ask(env, validBody());
  assert.equal(third.status, 429);
  assert.equal((await third.json()).error, 'quota');
});

test('общий потолок: другой подписчик получает 503, а его вопрос не сгорает', { skip }, async () => {
  const env = makeEnv({ DAILY_LIMIT: '5', GLOBAL_DAILY_LIMIT: '1' });
  assert.equal((await ask(env, validBody())).status, 200);
  const second = await ask(env, { prompt: 'Ещё вопрос', transaction: makeJws(chain, goodPayload({ originalTransactionId: '2000000999' })) });
  assert.equal(second.status, 503);
});

test('просроченная подписка — 403', { skip }, async () => {
  const body = validBody({ transaction: makeJws(chain, goodPayload({ expiresDate: Date.now() - 1000 })) });
  const res = await ask(makeEnv(), body);
  assert.equal(res.status, 403);
  assert.equal((await res.json()).reason, 'expired');
});

test('без подтверждения покупки или с подделкой — 401', { skip }, async () => {
  assert.equal((await ask(makeEnv(), { prompt: 'Привет' })).status, 401);
  assert.equal((await ask(makeEnv(), validBody({ transaction: 'a.b.c' }))).status, 401);
});

test('сбой ИИ: 502, и вопрос человеку не засчитывается', { skip }, async () => {
  const env = makeEnv({ DAILY_LIMIT: '1' });
  const failing = { fetch: async () => new Response('boom', { status: 500 }) };
  const first = await ask(env, validBody(), failing);
  assert.equal(first.status, 502);
  // лимит 1: если бы вопрос сгорел, второй запрос получил бы 429
  assert.equal((await ask(env, validBody())).status, 200);
});

test('плохой запрос: пустой вопрос и не JSON', { skip }, async () => {
  assert.equal((await ask(makeEnv(), validBody({ prompt: '   ' }))).status, 400);
  const res = await worker.fetch(new Request('https://luys.example/v1/generate', { method: 'POST', body: 'не json' }), makeEnv(), {});
  assert.equal(res.status, 400);
});

test('без ключа ИИ в секретах — 503, а не падение', { skip }, async () => {
  assert.equal((await ask(makeEnv({ GEMINI_API_KEY: '' }), validBody())).status, 503);
});

// --- Бесплатные вопросы: без подписки, по случайному номеру установки

const install = (n = 1) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const freeBody = (n = 1, extra = {}) => ({ prompt: 'Что значит «Бог есть любовь»?', installId: install(n), ...extra });

function askFrom(env, body, ip, deps = { fetch: okAi }) {
  const headers = ip ? { 'cf-connecting-ip': ip } : {};
  const request = new Request('https://luys.example/v1/generate', { method: 'POST', headers, body: JSON.stringify(body) });
  return worker.fetch(request, env, {}, deps);
}

test('бесплатный пользователь получает ответ, и ему говорят, сколько осталось', { skip }, async () => {
  const res = await ask(makeEnv({ FREE_DAILY_LIMIT: '3' }), freeBody());
  const data = await res.json();
  assert.equal(res.status, 200);
  assert.equal(data.text, 'Ответ ИИ');
  assert.equal(data.tier, 'free');
  assert.equal(data.remaining, 2);
});

test('бесплатный лимит на установку: сверх лимита 429, а другая установка не страдает', { skip }, async () => {
  const env = makeEnv({ FREE_DAILY_LIMIT: '2', GLOBAL_DAILY_LIMIT: '100' });
  assert.equal((await ask(env, freeBody(1))).status, 200);
  assert.equal((await ask(env, freeBody(1))).status, 200);
  const third = await ask(env, freeBody(1));
  assert.equal(third.status, 429);
  assert.equal((await third.json()).error, 'quota');
  assert.equal((await ask(env, freeBody(2))).status, 200);
});

test('бесплатный лимит на сеть: новые установки с одного адреса не обходят лимит', { skip }, async () => {
  const env = makeEnv({ FREE_NET_DAILY_LIMIT: '2', GLOBAL_DAILY_LIMIT: '100' });
  assert.equal((await askFrom(env, freeBody(1), '203.0.113.7')).status, 200);
  assert.equal((await askFrom(env, freeBody(2), '203.0.113.7')).status, 200);
  assert.equal((await askFrom(env, freeBody(3), '203.0.113.7')).status, 429);
  // другая сеть не затронута
  assert.equal((await askFrom(env, freeBody(4), '198.51.100.9')).status, 200);
});

test('отказ по сети не сжигает вопрос установки', { skip }, async () => {
  const env = makeEnv({ FREE_NET_DAILY_LIMIT: '1', FREE_DAILY_LIMIT: '1', GLOBAL_DAILY_LIMIT: '100' });
  assert.equal((await askFrom(env, freeBody(1), '203.0.113.7')).status, 200);
  // вторая установка с той же сети отказана по сети; её собственный вопрос остался нетронутым
  assert.equal((await askFrom(env, freeBody(2), '203.0.113.7')).status, 429);
  assert.equal((await askFrom(env, freeBody(2), '198.51.100.9')).status, 200);
});

test('общий потолок бесплатных: 503, а подписчик продолжает получать ответы', { skip }, async () => {
  const env = makeEnv({ FREE_GLOBAL_DAILY_LIMIT: '1', GLOBAL_DAILY_LIMIT: '100', DAILY_LIMIT: '5' });
  assert.equal((await ask(env, freeBody(1))).status, 200);
  const second = await ask(env, freeBody(2));
  assert.equal(second.status, 503);
  assert.equal((await second.json()).error, 'busy');
  assert.equal((await ask(env, validBody())).status, 200);
});

test('сбой ИИ у бесплатного: вопрос не списан ни с установки, ни с потолков', { skip }, async () => {
  const env = makeEnv({ FREE_DAILY_LIMIT: '1', FREE_GLOBAL_DAILY_LIMIT: '1', GLOBAL_DAILY_LIMIT: '1' });
  const failing = { fetch: async () => new Response('boom', { status: 500 }) };
  assert.equal((await ask(env, freeBody(1), failing)).status, 502);
  // все три счётчика были бы исчерпаны, если бы вопрос сгорел
  assert.equal((await ask(env, freeBody(1))).status, 200);
});

test('бесплатные вопросы можно выключить, подписчик не затронут', { skip }, async () => {
  const env = makeEnv({ ALLOW_FREE: 'false' });
  const res = await ask(env, freeBody());
  assert.equal(res.status, 403);
  assert.equal((await res.json()).reason, 'free_disabled');
  assert.equal((await ask(env, validBody())).status, 200);
});

test('бесплатный запрос с неверным номером установки — 401', { skip }, async () => {
  assert.equal((await ask(makeEnv(), { prompt: 'Привет', installId: 'не-uuid' })).status, 401);
  assert.equal((await ask(makeEnv(), { prompt: 'Привет', installId: '' })).status, 401);
});

test('сеть в счётчике не хранится в открытом виде', { skip }, async () => {
  const names = [];
  const env = makeEnv();
  const inner = env.QUOTA;
  env.QUOTA = { idFromName: (name) => { names.push(name); return inner.idFromName(name); }, get: (id) => inner.get(id) };
  await askFrom(env, freeBody(1), '203.0.113.7');
  assert.ok(names.some((name) => name.startsWith('net:')));
  assert.ok(!names.some((name) => name.includes('203.0.113.7')));
});

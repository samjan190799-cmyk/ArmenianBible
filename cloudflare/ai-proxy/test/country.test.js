import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { Stats } from '../src/stats.js';
import { countryOf } from '../src/events.js';
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

function makeEnv() {
  const storage = new FakeStorage();
  const stats = new Stats({ storage });
  const env = {
    STATS_TOKEN: 'secret-token',
    STATS: {
      idFromName: (name) => name,
      get: () => ({ fetch: (url, init) => stats.fetch(new Request(url, init)) })
    }
  };
  return { env, storage };
}

const A = '11111111-1111-4111-8111-111111111111';
const B = '22222222-2222-4222-8222-222222222222';
const C = '33333333-3333-4333-8333-333333333333';

/** Запуск приложения от имени человека; country задаёт то, что Cloudflare кладёт в request.cf */
function opened(env, installId, { country, headers } = {}) {
  const body = { installId, app: '4.3', build: '1', lang: 'hy', premium: false, events: [{ name: 'app_open', params: { day: 'd0' } }] };
  const request = new Request('https://luys.example/v1/events', { method: 'POST', body: JSON.stringify(body), headers });
  if (country !== undefined) Object.defineProperty(request, 'cf', { value: { country } });
  return worker.fetch(request, env, {});
}

async function activeReport(env) {
  const res = await worker.fetch(new Request('https://luys.example/v1/stats?days=7', { headers: { authorization: 'Bearer secret-token' } }), env, {});
  assert.equal(res.status, 200);
  return (await res.json()).events._active;
}

test('countryOf: код берётся из соединения, всё непонятное даёт xx', () => {
  assert.equal(countryOf({ cf: { country: 'AM' } }), 'am');
  assert.equal(countryOf({ headers: new Headers({ 'cf-ipcountry': 'RU' }) }), 'ru', 'запасной путь: заголовок Cloudflare');
  assert.equal(countryOf({ cf: { country: 'T1' } }), 't1', 'сеть Tor приходит кодом T1');
  assert.equal(countryOf({ cf: { country: 'Armenia' } }), 'xx');
  assert.equal(countryOf({ cf: { country: '' } }), 'xx');
  assert.equal(countryOf({ cf: { country: 'A M' } }), 'xx');
  assert.equal(countryOf({}), 'xx');
  assert.equal(countryOf(null), 'xx');
  assert.equal(countryOf(undefined), 'xx');
});

test('страны: люди и люди-дни считаются по соединению, повторный запуск в тот же день не удваивает', async () => {
  const { env } = makeEnv();
  assert.equal((await opened(env, A, { country: 'AM' })).status, 200);
  await opened(env, A, { country: 'AM' });
  await opened(env, B, { country: 'AM' });
  await opened(env, C, { country: 'RU' });
  const active = await activeReport(env);
  assert.deepEqual(active['country=am'], { events: 2, people: 2 });
  assert.deepEqual(active['country=ru'], { events: 1, people: 1 });
  assert.deepEqual(active[''], { events: 3, people: 3 });
});

test('страны: нет кода от Cloudflare или он странный, страна «xx»', async () => {
  const { env } = makeEnv();
  await opened(env, A);
  await opened(env, B, { country: 'ARMENIA' });
  const active = await activeReport(env);
  assert.deepEqual(active['country=xx'], { events: 2, people: 2 });
});

test('Stats.ingest: чужое значение страны в счётчики не попадает', async () => {
  const stats = new Stats({ storage: new FakeStorage() });
  const day = new Date().toISOString().slice(0, 10);
  const base = { day, lang: 'ru', app: '4.3', premium: false, events: [{ name: 'app_open', dims: {} }] };
  await stats.ingest({ ...base, installId: A, country: '../../etc' });
  await stats.ingest({ ...base, installId: B, country: 'AM' });
  await stats.ingest({ ...base, installId: C });
  const report = await stats.report(1);
  const countries = Object.keys(report.events._active).filter((dim) => dim.startsWith('country='));
  assert.deepEqual(countries, ['country=xx'], 'Worker присылает только строчные двухбуквенные коды; остальное считается неизвестным');
  assert.equal(report.events._active['country=xx'].people, 3);
});

test('страны: за период человек считается один раз в каждой стране, где его видели', async () => {
  const stats = new Stats({ storage: new FakeStorage() });
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86_400_000).toISOString().slice(0, 10);
  const base = { lang: 'hy', app: '4.3', premium: false, events: [{ name: 'app_open', dims: {} }] };
  await stats.ingest({ ...base, day: yesterday, installId: A, country: 'am' });
  await stats.ingest({ ...base, day: today, installId: A, country: 'am' });
  await stats.ingest({ ...base, day: today, installId: B, country: 'ru' });
  const { events } = await stats.report(7);
  assert.deepEqual(events._active['country=am'], { events: 2, people: 1 }, 'два дня, один человек');
  assert.deepEqual(events._active['country=ru'], { events: 1, people: 1 });
});

test('страны: сетевой адрес нигде не сохраняется', async () => {
  const { env, storage } = makeEnv();
  await opened(env, A, { country: 'AM', headers: { 'cf-connecting-ip': '203.0.113.77', 'x-forwarded-for': '203.0.113.77' } });
  const everything = JSON.stringify([...storage.map]);
  assert.ok(!everything.includes('203.0.113.77'), 'адреса в хранилище нет');
  assert.ok(everything.includes('country=am'), 'а страна есть');
});

// --- Страница /dashboard

async function renderDashboard(data, intl = Intl) {
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
  const fetchFn = async () => ({ status: 200, ok: true, json: async () => data });
  const run = new Function('document', 'localStorage', 'fetch', 'prompt', 'alert', 'confirm', 'Intl', DASHBOARD_SCRIPT);
  run(document, localStorage, fetchFn, () => '', () => {}, () => true, intl);
  await new Promise((resolve) => setTimeout(resolve, 20));
  const texts = [];
  (function walk(node) {
    if (node.textContent) texts.push(node.textContent);
    node.children.forEach(walk);
  })(app);
  return texts.join('\n');
}

const DASHBOARD_DATA = {
  days: ['2026-11-24'],
  daily: [{ day: '2026-11-24', active: 6, newInstalls: 0, paywallShown: 0, purchases: 0 }],
  events: {
    _active: {
      '': { events: 6, people: 5 },
      'country=ru': { events: 2, people: 1 },
      'country=am': { events: 3, people: 3 },
      'country=xx': { events: 1, people: 1 },
      'country=t1': { events: 1, people: 1 }
    }
  }
};

test('страница показывает страны: флаг, название и код, больше людей выше', async () => {
  const page = await renderDashboard(DASHBOARD_DATA);
  assert.match(page, /Страны активных людей/);
  assert.ok(page.includes('\u{1F1E6}\u{1F1F2}'), 'флаг Армении собран из двух букв');
  const armenia = new Intl.DisplayNames(['ru'], { type: 'region' }).of('AM');
  assert.ok(page.includes(armenia), 'название страны по-русски (или сам код, если в системе нет данных)');
  assert.ok(page.includes('не определена'));
  assert.ok(page.includes('сеть Tor'));
  assert.ok(page.indexOf('AM') < page.indexOf('RU'), 'Армения (3 человека) выше России (1 человек)');
});

test('страница без Intl.DisplayNames показывает страну кодом и не падает', async () => {
  const page = await renderDashboard(DASHBOARD_DATA, {});
  assert.ok(page.includes('\u{1F1E6}\u{1F1F2} AM'));
  assert.ok(!page.includes('Армения'));
});

test('страница без стран не рисует пустой блок', async () => {
  const page = await renderDashboard({ ...DASHBOARD_DATA, events: { _active: { '': { events: 1, people: 1 } } } });
  assert.ok(!page.includes('Страны активных людей'));
});

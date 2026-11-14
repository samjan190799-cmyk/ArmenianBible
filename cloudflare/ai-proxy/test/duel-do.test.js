import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import worker from '../src/index.js';
import { DuelRoom } from '../src/duel-do.js';
import { LIMITS } from '../src/duel-room.js';
import { roomPageHtml } from '../src/pages.js';

const A = 'player-aaaaaaaa';
const B = 'player-bbbbbbbb';
const C = 'player-cccccccc';
const CONFIG = { c: 'all', s: 4242, n: 2, m: 90 };

/** Подделка среды Durable Object: хранилище в памяти, сокеты с вложением, будильник */
function makeRoom() {
  const store = new Map();
  const sockets = [];
  const ctx = {
    storage: {
      get: async (k) => (store.has(k) ? structuredClone(store.get(k)) : undefined),
      put: async (k, v) => { store.set(k, structuredClone(v)); },
      delete: async (k) => { store.delete(k); },
      deleteAll: async () => { store.clear(); },
      setAlarm: async (t) => { ctx.alarmAt = t; },
      deleteAlarm: async () => { ctx.alarmAt = null; }
    },
    alarmAt: null,
    getWebSockets: () => sockets.filter((s) => s.readyState === 1),
    acceptWebSocket: (s) => sockets.push(s)
  };
  const room = new DuelRoom(ctx, {});
  return { room, ctx, store, sockets };
}

function socket(env) {
  const ws = {
    readyState: 1,
    sent: [],
    attachment: null,
    send(data) { this.sent.push(JSON.parse(data)); },
    close() { this.readyState = 3; },
    serializeAttachment(v) { this.attachment = v; },
    deserializeAttachment() { return this.attachment; },
    last() { return this.sent[this.sent.length - 1]; }
  };
  env.sockets.push(ws);
  return ws;
}

async function say(env, ws, msg) {
  await env.room.webSocketMessage(ws, JSON.stringify(msg));
}

test('обычный запрос без WebSocket в комнату получает 426', async () => {
  const env = makeRoom();
  const res = await env.room.fetch(new Request('https://luys.example/v1/duel/ABCDE'));
  assert.equal(res.status, 426);
});

test('маршрут Worker: плохой код 400, без апгрейда 426, без привязки 503', async () => {
  const bad = await worker.fetch(new Request('https://luys.example/v1/duel/abc', { headers: { Upgrade: 'websocket' } }), {}, {});
  assert.equal(bad.status, 400);
  const plain = await worker.fetch(new Request('https://luys.example/v1/duel/ABCDE'), {}, {});
  assert.equal(plain.status, 426);
  const unbound = await worker.fetch(new Request('https://luys.example/v1/duel/ABCDE', { headers: { Upgrade: 'websocket' } }), {}, {});
  assert.equal(unbound.status, 503);
});

test('маршрут Worker передаёт запрос объекту комнаты по коду', async () => {
  let name = null;
  const env = {
    DUEL: {
      idFromName: (n) => { name = n; return 'id-' + n; },
      get: (id) => ({ fetch: async () => new Response('ok:' + id) })
    }
  };
  const res = await worker.fetch(new Request('https://luys.example/v1/duel/K7P2Z', { headers: { Upgrade: 'websocket' } }), env, {});
  assert.equal(name, 'K7P2Z');
  assert.equal(await res.text(), 'ok:id-K7P2Z');
});

test('создатель и гость входят, оба получают состояние со своим видом', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'Самвел', config: CONFIG });
  assert.equal(host.last().type, 'state');
  assert.equal(host.last().state.phase, 'lobby');
  assert.equal(host.last().state.isHost, true);
  await say(env, guest, { type: 'join', pid: B, name: 'Ани' });
  assert.equal(guest.last().state.isHost, false);
  assert.equal(host.last().state.players.length, 2, 'создатель видит гостя');
  assert.ok(env.ctx.alarmAt > 0, 'будильник на простой комнаты назначен');
});

test('вход в чужую или несуществующую комнату: ошибка и закрытие', async () => {
  const env = makeRoom();
  const ghost = socket(env);
  await say(env, ghost, { type: 'join', pid: A, name: 'Самвел' });
  assert.deepEqual(ghost.last(), { type: 'error', code: 'not_found' });
  assert.equal(ghost.readyState, 3);
});

test('третий игрок получает full', async () => {
  const env = makeRoom();
  const [host, guest, third] = [socket(env), socket(env), socket(env)];
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'b' });
  await say(env, third, { type: 'join', pid: C, name: 'c' });
  assert.deepEqual(third.last(), { type: 'error', code: 'full' });
});

test('сообщения без входа, мусор и огромные кадры молча игнорируются', async () => {
  const env = makeRoom();
  const ws = socket(env);
  await env.room.webSocketMessage(ws, 'not json');
  await env.room.webSocketMessage(ws, JSON.stringify({ type: 'start' }));
  await env.room.webSocketMessage(ws, 'x'.repeat(5000));
  await env.room.webSocketMessage(ws, new ArrayBuffer(4));
  assert.equal(ws.sent.length, 0);
});

test('полная партия: старт, отсчёт по будильнику, ответы, итог, реванш', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'Самвел', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'Ани' });
  await say(env, host, { type: 'start' });
  assert.equal(host.last().state.phase, 'countdown');

  // будильник на конец отсчёта: сдвигаем часы и вызываем alarm()
  const realNow = Date.now;
  let t = realNow() + LIMITS.countdownMs + 50;
  Date.now = () => t;
  try {
    await env.room.alarm();
    assert.equal(host.last().state.phase, 'playing');

    for (let q = 0; q < CONFIG.n; q += 1) {
      await say(env, host, { type: 'answer', q, correct: true, ms: 900 });
      await say(env, guest, { type: 'answer', q, correct: q === 0, ms: 1500 });
      t += LIMITS.revealMs + 50;
      await env.room.alarm();
    }
    const done = host.last().state;
    assert.equal(done.phase, 'finished');
    assert.equal(done.players.find((p) => p.you).score, 2);
    assert.equal(done.players.find((p) => !p.you).score, 1);

    await say(env, host, { type: 'rematch' });
    await say(env, guest, { type: 'rematch' });
    assert.equal(host.last().state.phase, 'countdown');
    assert.notEqual(host.last().state.config.s, CONFIG.s, 'у реванша новое семя');
  } finally {
    Date.now = realNow;
  }
});

test('запоздалый ответ не ломает партию: клиент получает свежее состояние', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'b' });
  await say(env, host, { type: 'answer', q: 0, correct: true, ms: 1 });
  assert.equal(host.last().type, 'state');
  assert.equal(host.last().state.phase, 'lobby');
});

test('обрыв связи отмечает игрока ушедшим, возвращение с нового сокета снимает отметку', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'b' });
  guest.readyState = 3;
  await env.room.webSocketClose(guest);
  assert.equal(host.last().state.players.find((p) => !p.you).connected, false);

  const back = socket(env);
  await say(env, back, { type: 'join', pid: B, name: 'b' });
  assert.equal(host.last().state.players.find((p) => !p.you).connected, true);
  assert.equal(back.last().state.players.length, 2);
});

test('переподключение: закрытие старого сокета не считается уходом, если новый уже на связи', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'b' });
  const fresh = socket(env);
  await say(env, fresh, { type: 'join', pid: B, name: 'b' });
  assert.equal(guest.readyState, 3, 'старое соединение закрыто');
  await env.room.webSocketClose(guest);
  assert.equal(host.last().state.players.find((p) => !p.you).connected, true);
});

test('сообщение leave закрывает сокет и освобождает место', async () => {
  const env = makeRoom();
  const host = socket(env);
  const guest = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  await say(env, guest, { type: 'join', pid: B, name: 'b' });
  await say(env, guest, { type: 'leave' });
  assert.equal(guest.readyState, 3);
  assert.equal(host.last().state.players.length, 1);
});

test('комната без движения удаляется будильником, код остаётся', async () => {
  const env = makeRoom();
  const host = socket(env);
  await say(env, host, { type: 'join', pid: A, name: 'a', config: CONFIG });
  const realNow = Date.now;
  Date.now = () => realNow() + LIMITS.idleMs + 10;
  try {
    await env.room.alarm();
  } finally {
    Date.now = realNow;
  }
  assert.equal(host.readyState, 3);
  assert.equal(env.store.has('room'), false);
});

/** Запуск скрипта страницы на подделке DOM (как в pages.test.js) */
function run(hash, language = 'ru-RU') {
  const code = /<script>([\s\S]*)<\/script>/.exec(roomPageHtml())[1];
  const card = { children: [], appendChild(node) { this.children.push(node); } };
  const sandbox = {
    document: { getElementById: () => card, createElement: (tag) => ({ tag, className: '', textContent: '', href: '' }) },
    location: { hash },
    navigator: { language },
    atob: globalThis.atob,
    TextDecoder: globalThis.TextDecoder,
    Uint8Array
  };
  vm.runInNewContext(code, sandbox);
  return card.children;
}

test('страница /r: код комнаты и кнопка в приложение с этим же кодом', async () => {
  const res = await worker.fetch(new Request('https://luys.example/r'), {}, {});
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-security-policy'), /default-src 'none'/);

  const nodes = run('#K7P2Z');
  assert.ok(nodes.some((n) => n.textContent === 'K7P2Z'));
  assert.ok(nodes.some((n) => n.href === 'armenianbible://room?c=K7P2Z'));
  assert.ok(nodes.some((n) => n.href === 'https://apps.apple.com/app/id6790569890'));
});

test('страница /r: неверный код считается повреждённой ссылкой', () => {
  for (const hash of ['', '#', '#abc', '#K7P2', '#K7P2ZZ', '#IIIII', '#K7P2<']) {
    const nodes = run(hash, 'en-US');
    assert.ok(nodes.some((n) => n.textContent === 'This link is damaged'), `hash=${hash}`);
    assert.ok(!nodes.some((n) => n.href.startsWith('armenianbible://')), `hash=${hash}`);
  }
});

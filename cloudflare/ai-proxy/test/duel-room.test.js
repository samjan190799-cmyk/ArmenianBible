import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  LIMITS, createRoom, join, setConnected, leave, start, answer, rematch, tick, nextDeadline, isExpired, view,
  validateConfig, validCode, cleanName
} from '../src/duel-room.js';

const A = 'player-aaaaaaaa';
const B = 'player-bbbbbbbb';
const C = 'player-cccccccc';
const CONFIG = { c: 'all', s: 12345, n: 3, m: 90 };

function lobby(now = 1000) {
  let s = createRoom('ABCDE', now);
  s = join(s, { pid: A, name: 'Самвел', config: CONFIG }, now).state;
  s = join(s, { pid: B, name: 'Ани' }, now).state;
  return s;
}

/** Комната в игре: обратный отсчёт прошёл, идёт первый вопрос. Время вопроса 0 = t0 */
function playing(t0 = 10000) {
  let s = lobby(t0 - LIMITS.countdownMs);
  s = start(s, A, t0 - LIMITS.countdownMs).state;
  s = tick(s, t0);
  return { s, t0 };
}

test('коды и настройки: допустимые проходят, мусор нет', () => {
  assert.ok(validCode('ABCDE'));
  assert.ok(validCode('K7P2Z'));
  for (const bad of ['', 'abcde', 'ABCD', 'ABCDEF', 'ABCD0', 'ABCDI', 'ABC O1', null, 5]) {
    assert.ok(!validCode(bad), String(bad));
  }
  assert.deepEqual(validateConfig(CONFIG), CONFIG);
  assert.equal(validateConfig({ ...CONFIG, n: 0 }), null);
  assert.equal(validateConfig({ ...CONFIG, n: 31 }), null);
  assert.equal(validateConfig({ ...CONFIG, m: 2 }), null);
  assert.equal(validateConfig({ ...CONFIG, s: 0 }), null);
  assert.equal(validateConfig({ ...CONFIG, s: 1.5 }), null);
  assert.equal(validateConfig({ ...CONFIG, c: '../x' }), null);
  assert.equal(validateConfig(null), null);
});

test('имя: без разметки и управляющих знаков, не длиннее 24', () => {
  assert.equal(cleanName('  Ани  '), 'Ани');
  assert.ok(!/[<>]/.test(cleanName('<script>x</script>')));
  assert.equal(cleanName('a'.repeat(100)).length, 24);
  assert.equal(cleanName(undefined), '');
});

test('создание: первый вошедший с настройками становится создателем, комната переходит в лобби', () => {
  const room = createRoom('ABCDE', 1000);
  assert.equal(room.phase, 'new');
  const { state, error } = join(room, { pid: A, name: 'Самвел', config: CONFIG }, 1000);
  assert.equal(error, undefined);
  assert.equal(state.phase, 'lobby');
  assert.equal(state.hostId, A);
  assert.equal(state.players.length, 1);
  assert.equal(room.phase, 'new', 'исходное состояние не изменено');
});

test('вход в несуществующую комнату и с плохими настройками отклоняется', () => {
  const room = createRoom('ABCDE', 1000);
  assert.equal(join(room, { pid: B, name: 'Ани' }, 1000).error, 'not_found');
  assert.equal(join(room, { pid: A, config: { ...CONFIG, n: 99 } }, 1000).error, 'bad_request');
  assert.equal(join(room, { pid: 'x', config: CONFIG }, 1000).error, 'bad_request');
});

test('занятый код: второй создатель получает exists, а не перезаписывает комнату', () => {
  const s = lobby();
  assert.equal(join(s, { pid: C, config: CONFIG }, 1100).error, 'exists');
});

test('третий не входит; игра идёт — тоже нет мест', () => {
  const s = lobby();
  assert.equal(join(s, { pid: C, name: 'Лев' }, 1100).error, 'full');
  const { s: inGame } = playing();
  assert.equal(join(inGame, { pid: C, name: 'Лев' }, 11000).error, 'full');
});

test('гость, который вышел из приложения в лобби, уступает место новому', () => {
  let s = lobby();
  s = setConnected(s, B, false, 1500);
  const result = join(s, { pid: C, name: 'Лев' }, 2000);
  assert.equal(result.error, undefined);
  assert.deepEqual(result.state.players.map((p) => p.id), [A, C]);
});

test('создатель в лобби не теряет место, если ушёл за ссылкой и вернулся', () => {
  let s = lobby();
  s = setConnected(s, A, false, 1500);
  assert.equal(join(s, { pid: C, name: 'Лев' }, 2000).error, 'full');
  s = join(s, { pid: A, name: 'Самвел' }, 2500).state;
  assert.ok(s.players.find((p) => p.id === A).connected);
});

test('старт: только создатель и только когда двое на связи', () => {
  const solo = join(createRoom('ABCDE', 0), { pid: A, name: 'Самвел', config: CONFIG }, 0).state;
  assert.equal(start(solo, A, 10).error, 'not_ready');
  const s = lobby();
  assert.equal(start(s, B, 2000).error, 'not_host');
  const away = setConnected(s, B, false, 1500);
  assert.equal(start(away, A, 2000).error, 'not_ready');
  const go = start(s, A, 2000);
  assert.equal(go.state.phase, 'countdown');
  assert.equal(go.state.startsAt, 2000 + LIMITS.countdownMs);
  assert.equal(start(go.state, A, 2100).error, 'bad_state');
});

test('отсчёт: до конца идёт countdown, потом первый вопрос с отсчётом времени от startsAt', () => {
  let s = start(lobby(), A, 2000).state;
  assert.equal(tick(s, 2000 + LIMITS.countdownMs - 1).phase, 'countdown');
  s = tick(s, 2000 + LIMITS.countdownMs + 400);
  assert.equal(s.phase, 'playing');
  assert.equal(s.q, 0);
  assert.equal(s.qStart, 2000 + LIMITS.countdownMs, 'время вопроса не уплывает от опоздания таймера');
});

test('вопрос заканчивается, когда ответили оба; пауза; следующий вопрос', () => {
  const { s: s0, t0 } = playing();
  let s = answer(s0, A, { q: 0, correct: true, ms: 1200 }, t0 + 1200).state;
  assert.equal(s.revealAt, null, 'ждём второго');
  s = answer(s, B, { q: 0, correct: false, ms: 3000 }, t0 + 3000).state;
  assert.equal(s.revealAt, t0 + 3000 + LIMITS.revealMs);
  assert.equal(s.q, 0);
  s = tick(s, t0 + 3000 + LIMITS.revealMs);
  assert.equal(s.q, 1);
  assert.equal(s.qStart, t0 + 3000 + LIMITS.revealMs);
  assert.equal(s.revealAt, null);
});

test('время вышло: молчавший получает «нет ответа», вопрос раскрывается сам', () => {
  const { s: s0, t0 } = playing();
  let s = answer(s0, A, { q: 0, correct: true, ms: 800 }, t0 + 800).state;
  s = tick(s, t0 + LIMITS.questionMs);
  assert.equal(s.revealAt, t0 + LIMITS.questionMs + LIMITS.revealMs);
  const v = view(s, A, t0 + LIMITS.questionMs);
  assert.equal(v.players.find((p) => !p.you).answered, false);
  assert.equal(v.players.find((p) => p.you).correct, true);
});

test('поздний тик не сдвигает следующий вопрос: время идёт от запланированного', () => {
  const { s: s0, t0 } = playing();
  const s = tick(s0, t0 + LIMITS.questionMs + LIMITS.revealMs + 5000);
  assert.equal(s.q, 1);
  assert.equal(s.qStart, t0 + LIMITS.questionMs + LIMITS.revealMs);
});

test('ответ: чужой вопрос, повтор, неверные поля и лишний игрок отбрасываются', () => {
  const { s, t0 } = playing();
  assert.equal(answer(s, A, { q: 1, correct: true, ms: 10 }, t0 + 10).error, 'bad_state');
  assert.equal(answer(s, A, { q: 0, correct: 'yes', ms: 10 }, t0 + 10).error, 'bad_request');
  assert.equal(answer(s, C, { q: 0, correct: true, ms: 10 }, t0 + 10).error, 'bad_request');
  const once = answer(s, A, { q: 0, correct: true, ms: 10 }, t0 + 10).state;
  assert.equal(answer(once, A, { q: 0, correct: false, ms: 20 }, t0 + 20).error, 'bad_state', 'ответ не переписать');
  assert.equal(once.players[0].answers[0].correct, true);
});

test('ответ в лобби и в паузе после вопроса не принимается', () => {
  assert.equal(answer(lobby(), A, { q: 0, correct: true, ms: 1 }, 1100).error, 'bad_state');
  const { s: s0, t0 } = playing();
  let s = answer(s0, A, { q: 0, correct: true, ms: 1 }, t0 + 1).state;
  s = answer(s, B, { q: 0, correct: true, ms: 2 }, t0 + 2).state;
  assert.equal(answer(s, A, { q: 0, correct: false, ms: 3 }, t0 + 3).error, 'bad_state');
});

test('время ответа ограничено вопросом, мусор вместо числа считается за максимум', () => {
  const { s, t0 } = playing();
  const a = answer(s, A, { q: 0, correct: true, ms: 99999 }, t0 + 10).state;
  assert.equal(a.players[0].answers[0].ms, LIMITS.questionMs);
  const b = answer(s, A, { q: 0, correct: true, ms: -5 }, t0 + 10).state;
  assert.equal(b.players[0].answers[0].ms, 0);
  const c = answer(s, A, { q: 0, correct: true, ms: 'x' }, t0 + 10).state;
  assert.equal(c.players[0].answers[0].ms, LIMITS.questionMs);
});

/** Проигрывает партию до конца: A отвечает верно на всё, B верно на первый */
function playAll() {
  const { s: s0, t0 } = playing();
  let s = s0;
  let t = t0;
  for (let q = 0; q < CONFIG.n; q += 1) {
    s = answer(s, A, { q, correct: true, ms: 1000 }, t + 1000).state;
    s = answer(s, B, { q, correct: q === 0, ms: 2000 }, t + 2000).state;
    t += 2000 + LIMITS.revealMs;
    s = tick(s, t);
  }
  return { s, t };
}

test('партия до конца: после последнего вопроса finished, счёт верный', () => {
  const { s, t } = playAll();
  assert.equal(s.phase, 'finished');
  const mine = view(s, A, t);
  assert.equal(mine.players.find((p) => p.you).score, 3);
  assert.equal(mine.players.find((p) => !p.you).score, 1);
  const theirs = view(s, B, t);
  assert.equal(theirs.players.find((p) => p.you).score, 1);
});

test('счёт не выдаёт ответ соперника, пока вопрос не раскрыт', () => {
  const { s: s0, t0 } = playing();
  const s = answer(s0, A, { q: 0, correct: true, ms: 500 }, t0 + 500).state;
  const forB = view(s, B, t0 + 500);
  const them = forB.players.find((p) => !p.you);
  assert.equal(them.answered, true);
  assert.equal(them.correct, null);
  assert.equal(them.score, 0);
  const done = answer(s, B, { q: 0, correct: false, ms: 900 }, t0 + 900).state;
  const after = view(done, B, t0 + 900);
  assert.equal(after.players.find((p) => !p.you).correct, true);
  assert.equal(after.players.find((p) => !p.you).score, 1);
});

test('реванш: нужны оба, новое семя, счёт и ответы обнулены', () => {
  const { s, t } = playAll();
  const first = rematch(s, A, t, 777).state;
  assert.equal(first.phase, 'finished', 'один не начинает');
  assert.ok(first.players[0].rematch);
  const both = rematch(first, B, t + 100, 777).state;
  assert.equal(both.phase, 'countdown');
  assert.equal(both.config.s, 777);
  assert.equal(both.q, 0);
  assert.deepEqual(both.players.map((p) => p.answers), [{}, {}]);
  assert.ok(both.players.every((p) => !p.rematch));
  assert.equal(rematch(lobby(), A, 5, 9).error, 'bad_state');
});

test('связь пропала и вернулась в пределах паузы: партия идёт, не ждём вернувшегося', () => {
  const { s: s0, t0 } = playing();
  let s = answer(s0, A, { q: 0, correct: true, ms: 500 }, t0 + 500).state;
  s = setConnected(s, B, false, t0 + 600);
  assert.equal(s.revealAt, t0 + 600 + LIMITS.revealMs, 'вопрос не ждёт отключённого');
  s = tick(s, t0 + 5000);
  assert.equal(s.phase, 'playing');
  s = join(s, { pid: B, name: 'Ани' }, t0 + 5000).state;
  assert.ok(s.players.find((p) => p.id === B).connected);
});

test('оба потеряли связь: вопросы не сгорают, пока ждём возвращения', () => {
  const { s: s0, t0 } = playing();
  let s = setConnected(s0, A, false, t0 + 100);
  s = setConnected(s, B, false, t0 + 200);
  s = tick(s, t0 + LIMITS.questionMs + 5000);
  assert.equal(s.q, 0);
  assert.equal(s.revealAt, null);
  s = join(s, { pid: A, name: 'Самвел' }, t0 + 16000).state;
  s = tick(s, t0 + 16000);
  assert.equal(s.phase, 'playing');
});

test('игрок не вернулся за graceMs: партия закрывается, победа за оставшимся', () => {
  const { s: s0, t0 } = playing();
  let s = setConnected(s0, B, false, t0 + 1000);
  s = tick(s, t0 + 1000 + LIMITS.graceMs - 1);
  assert.equal(s.phase, 'playing');
  s = tick(s, t0 + 1000 + LIMITS.graceMs);
  assert.equal(s.phase, 'finished');
  assert.equal(view(s, A, t0).abandoned, 'opponent');
  assert.equal(view(s, B, t0).abandoned, 'you');
});

test('уход игрока посреди партии: сразу finished', () => {
  const { s: s0, t0 } = playing();
  const s = leave(s0, B, t0 + 100);
  assert.equal(s.phase, 'finished');
  assert.equal(s.abandoned, B);
});

test('уход из лобби: гость освобождает место; создатель передаёт комнату; пустая комната исчезает', () => {
  let s = lobby();
  s = leave(s, B, 2000);
  assert.deepEqual(s.players.map((p) => p.id), [A]);
  s = join(s, { pid: C, name: 'Лев' }, 2100).state;
  s = leave(s, A, 2200);
  assert.equal(s.hostId, C);
  s = leave(s, C, 2300);
  assert.equal(s.phase, 'new');
  assert.equal(s.players.length, 0);
});

test('nextDeadline: отсчёт, вопрос, пауза, и ожидание вернувшегося', () => {
  const s = lobby(1000);
  assert.equal(nextDeadline(s), 1000 + LIMITS.idleMs);
  assert.equal(nextDeadline(createRoom('ABCDE', 0)), null);
  const go = start(s, A, 2000).state;
  assert.equal(nextDeadline(go), 2000 + LIMITS.countdownMs);
  const { s: p, t0 } = playing();
  assert.equal(nextDeadline(p), t0 + LIMITS.questionMs);
  const off = setConnected(p, B, false, t0 + 2000);
  assert.equal(nextDeadline(off), t0 + LIMITS.questionMs, 'вопрос раньше, чем grace');
  const late = setConnected(p, B, false, t0 + 14000);
  assert.equal(nextDeadline(late), t0 + LIMITS.questionMs);
});

test('комната без движения устаревает через idleMs', () => {
  const s = lobby(1000);
  assert.equal(isExpired(s, 1000 + LIMITS.idleMs - 1), false);
  assert.equal(isExpired(s, 1000 + LIMITS.idleMs), true);
  assert.equal(isExpired(createRoom('ABCDE', 0), 10 * LIMITS.idleMs), false);
});

test('вид для клиента: серверное время, признак создателя, ничего лишнего (чужих id нет)', () => {
  const s = lobby();
  const v = view(s, B, 5000);
  assert.equal(v.serverNow, 5000);
  assert.equal(v.isHost, false);
  assert.equal(view(s, A, 5000).isHost, true);
  assert.ok(!JSON.stringify(v).includes(A), 'id соперника клиенту не отдаётся');
  assert.ok(v.players.find((p) => p.you).name === 'Ани');
});

test('исходное состояние никогда не меняется функциями движка', () => {
  const { s, t0 } = playing();
  const snapshot = JSON.stringify(s);
  answer(s, A, { q: 0, correct: true, ms: 100 }, t0 + 100);
  tick(s, t0 + 999999);
  setConnected(s, B, false, t0 + 1);
  leave(s, A, t0 + 1);
  assert.equal(JSON.stringify(s), snapshot);
});

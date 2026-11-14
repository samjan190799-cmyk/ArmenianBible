// Дуэль в реальном времени: чистая логика комнаты. Здесь нет ни сети, ни часов, ни случайности: время (now) и
// «семя» нового раунда приходят аргументами, поэтому каждое правило проверяется обычным тестом.
// Durable Object (duel-do.js) только принимает сообщения, вызывает эти функции и рассылает результат.
//
// Вопросы сервер не знает: у обоих телефонов одна кураторская база, а из «семени» получается один порядок вопросов
// (так же, как в дуэли по ссылке). Игрок сообщает, верно ли он ответил, и за сколько миллисекунд. Это дружеская игра
// на двоих, не турнир, поэтому честность ответа проверять не нужно.

export const LIMITS = {
  countdownMs: 3000, // обратный отсчёт перед первым вопросом
  questionMs: 15000, // время на один вопрос
  revealMs: 1800, // пауза после вопроса: видно, кто что ответил
  graceMs: 20000, // сколько ждём вернувшегося игрока, прежде чем считать, что он ушёл
  idleMs: 30 * 60 * 1000, // комната без движения живёт полчаса
  maxPlayers: 2
};

const CODE_RE = /^[A-HJ-NP-Z2-9]{5}$/;
const PID_RE = /^[A-Za-z0-9_-]{8,64}$/;
const CATEGORY_RE = /^[A-Za-z0-9_-]{1,24}$/;

export function validCode(code) {
  return typeof code === 'string' && CODE_RE.test(code);
}

export function validPid(pid) {
  return typeof pid === 'string' && PID_RE.test(pid);
}

export function cleanName(name) {
  return String(name ?? '')
    .replace(/[\u0000-\u001f\u007f<>]/g, '')
    .trim()
    .slice(0, 24);
}

/** Настройки партии от создателя комнаты; null, если что-то вне разумных пределов */
export function validateConfig(config) {
  if (!config || typeof config !== 'object') return null;
  const { c, s, n, m } = config;
  if (typeof c !== 'string' || !CATEGORY_RE.test(c)) return null;
  if (!Number.isInteger(s) || s < 1 || s > 2147483647) return null;
  if (!Number.isInteger(n) || n < 1 || n > 30) return null;
  if (!Number.isInteger(m) || m < n || m > 5000) return null;
  return { c, s, n, m };
}

export function createRoom(code, now) {
  return {
    code,
    phase: 'new', // new: комнаты ещё нет; lobby; countdown; playing; finished
    config: null,
    hostId: null,
    players: [],
    q: 0,
    startsAt: null,
    qStart: null,
    revealAt: null,
    abandoned: null, // кто ушёл посреди партии
    activity: now
  };
}

function clone(state) {
  return structuredClone(state);
}

function ok(state) {
  return { state };
}

function fail(state, error) {
  return { state, error };
}

function touch(state, now) {
  state.activity = now;
}

/** Вход в комнату. Создатель присылает config, гость нет */
export function join(state, { pid, name, config }, now) {
  if (!validPid(pid)) return fail(state, 'bad_request');
  const s = clone(state);
  const cleaned = cleanName(name);

  const existing = s.players.find((p) => p.id === pid);
  if (existing) {
    existing.connected = true;
    existing.disconnectedAt = null;
    if (cleaned) existing.name = cleaned;
    touch(s, now);
    return ok(s);
  }

  if (s.phase === 'new') {
    if (config === undefined || config === null) return fail(state, 'not_found');
    const valid = validateConfig(config);
    if (!valid) return fail(state, 'bad_request');
    s.config = valid;
    s.hostId = pid;
    s.phase = 'lobby';
    s.players = [newPlayer(pid, cleaned)];
    touch(s, now);
    return ok(s);
  }

  // Комната уже есть: создавать её заново нельзя, код занят
  if (config !== undefined && config !== null) return fail(state, 'exists');
  if (s.phase !== 'lobby') return fail(state, 'full');

  if (s.players.length >= LIMITS.maxPlayers) {
    // Гость, который вышел из приложения (например, за ссылкой в другой чат), не держит место вечно
    const stale = s.players.findIndex((p) => p.id !== s.hostId && !p.connected);
    if (stale === -1) return fail(state, 'full');
    s.players.splice(stale, 1);
  }
  s.players.push(newPlayer(pid, cleaned));
  touch(s, now);
  return ok(s);
}

function newPlayer(id, name) {
  return { id, name, connected: true, disconnectedAt: null, rematch: false, answers: {} };
}

/** Связь с игроком оборвалась или вернулась. Обрыв не выкидывает его из комнаты: у него есть graceMs на возвращение */
export function setConnected(state, pid, connected, now) {
  const index = state.players.findIndex((p) => p.id === pid);
  if (index === -1) return state;
  const s = clone(state);
  const player = s.players[index];
  player.connected = connected;
  player.disconnectedAt = connected ? null : now;
  touch(s, now);
  return tick(s, now);
}

/** Игрок ушёл сам (закрыл комнату) */
export function leave(state, pid, now) {
  const index = state.players.findIndex((p) => p.id === pid);
  if (index === -1) return state;
  const s = clone(state);
  if (s.phase === 'countdown' || s.phase === 'playing') {
    finishAbandoned(s, pid);
    touch(s, now);
    return s;
  }
  s.players.splice(index, 1);
  if (s.players.length === 0) {
    return createRoom(s.code, now);
  }
  if (s.hostId === pid) s.hostId = s.players[0].id;
  for (const p of s.players) p.rematch = false;
  touch(s, now);
  return s;
}

function finishAbandoned(s, pid) {
  s.phase = 'finished';
  s.abandoned = pid;
  s.revealAt = null;
  s.startsAt = null;
  for (const p of s.players) p.rematch = false;
}

/** Создатель запускает партию, когда в комнате двое и оба на связи */
export function start(state, pid, now) {
  if (state.phase !== 'lobby') return fail(state, 'bad_state');
  if (pid !== state.hostId) return fail(state, 'not_host');
  if (state.players.length < 2 || state.players.some((p) => !p.connected)) return fail(state, 'not_ready');
  const s = clone(state);
  beginCountdown(s, now);
  touch(s, now);
  return ok(s);
}

function beginCountdown(s, now) {
  s.phase = 'countdown';
  s.startsAt = now + LIMITS.countdownMs;
  s.q = 0;
  s.qStart = null;
  s.revealAt = null;
  s.abandoned = null;
  for (const p of s.players) {
    p.answers = {};
    p.rematch = false;
  }
}

/** Ответ на текущий вопрос. Повторный, запоздалый и чужой отбрасываются */
export function answer(state, pid, { q, correct, ms }, now) {
  if (state.phase !== 'playing' || state.revealAt !== null) return fail(state, 'bad_state');
  if (!Number.isInteger(q) || q !== state.q) return fail(state, 'bad_state');
  if (typeof correct !== 'boolean') return fail(state, 'bad_request');
  const index = state.players.findIndex((p) => p.id === pid);
  if (index === -1) return fail(state, 'bad_request');
  if (state.players[index].answers[q] !== undefined) return fail(state, 'bad_state');
  const s = clone(state);
  const spent = Number.isFinite(ms) ? Math.min(LIMITS.questionMs, Math.max(0, Math.round(ms))) : LIMITS.questionMs;
  s.players[index].answers[q] = { correct, ms: spent };
  touch(s, now);
  return ok(tick(s, now));
}

/** Просьба о реванше; когда согласны оба, начинается новый отсчёт с новым «семенем» */
export function rematch(state, pid, now, seed) {
  if (state.phase !== 'finished') return fail(state, 'bad_state');
  const index = state.players.findIndex((p) => p.id === pid);
  if (index === -1) return fail(state, 'bad_request');
  const s = clone(state);
  s.players[index].rematch = true;
  touch(s, now);
  const everyone = s.players.length === LIMITS.maxPlayers && s.players.every((p) => p.rematch && p.connected);
  if (everyone && Number.isInteger(seed) && seed >= 1) {
    s.config.s = seed;
    beginCountdown(s, now);
  }
  return ok(s);
}

/** Двигает время: отсчёт, окончание вопроса, пауза, следующий вопрос, уход не вернувшегося игрока */
export function tick(state, now) {
  let s = state;
  let cloned = false;
  const mutable = () => {
    if (!cloned) {
      s = clone(s);
      cloned = true;
    }
    return s;
  };

  for (let guard = 0; guard < 80; guard += 1) {
    if (s.phase === 'countdown') {
      if (now < s.startsAt) break;
      const m = mutable();
      m.phase = 'playing';
      m.q = 0;
      m.qStart = m.startsAt;
      m.startsAt = null;
      m.revealAt = null;
      continue;
    }

    if (s.phase !== 'playing') break;

    const gone = s.players.find((p) => !p.connected && now - p.disconnectedAt >= LIMITS.graceMs);
    if (gone) {
      finishAbandoned(mutable(), gone.id);
      break;
    }

    if (s.revealAt === null) {
      // Никого на связи: вопросы не сгорают, ждём возвращения или конца graceMs
      if (s.players.every((p) => !p.connected)) break;
      const waiting = s.players.filter((p) => p.connected && p.answers[s.q] === undefined);
      const timeout = s.qStart + LIMITS.questionMs;
      if (waiting.length === 0 || now >= timeout) {
        const m = mutable();
        m.revealAt = (waiting.length === 0 ? Math.min(now, timeout) : timeout) + LIMITS.revealMs;
        continue;
      }
      break;
    }

    if (now >= s.revealAt) {
      const m = mutable();
      m.q += 1;
      if (m.q >= m.config.n) {
        m.phase = 'finished';
        m.revealAt = null;
        m.qStart = null;
        for (const p of m.players) p.rematch = false;
      } else {
        m.qStart = m.revealAt;
        m.revealAt = null;
      }
      continue;
    }
    break;
  }
  return s;
}

/** Когда серверу нужно проснуться в следующий раз; null, если будить не нужно */
export function nextDeadline(state) {
  if (state.phase === 'new') return null;
  const times = [state.activity + LIMITS.idleMs];
  if (state.phase === 'countdown') times.push(state.startsAt);
  if (state.phase === 'playing') {
    times.push(state.revealAt !== null ? state.revealAt : state.qStart + LIMITS.questionMs);
    for (const p of state.players) {
      if (!p.connected && p.disconnectedAt !== null) times.push(p.disconnectedAt + LIMITS.graceMs);
    }
  }
  return Math.min(...times);
}

export function isExpired(state, now) {
  return state.phase !== 'new' && now - state.activity >= LIMITS.idleMs;
}

function revealedUpTo(state) {
  if (state.phase === 'finished') return state.config ? state.config.n : 0;
  if (state.phase === 'playing') return state.revealAt !== null ? state.q + 1 : state.q;
  return 0;
}

/** Что видит игрок pid: счёт только по вопросам, которые уже раскрыты, чужой ответ на текущий вопрос скрыт */
export function view(state, pid, now) {
  const revealed = revealedUpTo(state);
  const showCurrent = state.phase === 'playing' && state.revealAt !== null;
  return {
    code: state.code,
    phase: state.phase,
    config: state.config,
    serverNow: now,
    startsAt: state.startsAt,
    qStart: state.qStart,
    revealAt: state.revealAt,
    questionMs: LIMITS.questionMs,
    revealMs: LIMITS.revealMs,
    q: state.q,
    isHost: pid === state.hostId,
    abandoned: state.abandoned === null ? null : state.abandoned === pid ? 'you' : 'opponent',
    players: state.players.map((p) => {
      let score = 0;
      for (let i = 0; i < revealed; i += 1) {
        if (p.answers[i] && p.answers[i].correct) score += 1;
      }
      const current = p.answers[state.q];
      return {
        you: p.id === pid,
        name: p.name,
        connected: p.connected,
        score,
        answered: current !== undefined,
        correct: showCurrent && current !== undefined ? current.correct : null,
        rematch: p.rematch
      };
    })
  };
}

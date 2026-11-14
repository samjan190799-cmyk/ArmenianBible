// Комната дуэли в реальном времени: один Durable Object на код комнаты, два игрока на WebSocket.
// Вся логика партии лежит в duel-room.js (чистые функции); здесь только сеть и хранение:
// - состояние комнаты хранится в storage, так что объект может «заснуть» (hibernation) между сообщениями;
// - в какой комнате какой игрок, помнит вложение сокета (serializeAttachment): оно переживает сон;
// - время вопросов и пауз отсчитывает alarm: ближайший срок считает nextDeadline.

import {
  LIMITS, createRoom, validCode, join, setConnected, leave, start, answer, rematch, tick, nextDeadline, isExpired, view
} from './duel-room.js';

const MAX_SOCKETS = 8; // двое играют, остальное запас на переподключения; больше — это уже не игра
const MAX_MESSAGE = 2048;

export class DuelRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;
    // Пинг клиента отвечается без пробуждения объекта: соединение живёт, а счётчик времени не растёт
    if (typeof WebSocketRequestResponsePair === 'function' && typeof ctx.setWebSocketAutoResponse === 'function') {
      ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair('ping', 'pong'));
    }
  }

  async fetch(request) {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('expected websocket', { status: 426 });
    }
    const code = new URL(request.url).pathname.split('/').pop();
    if (!validCode(code)) return new Response('bad code', { status: 400 });
    if (this.ctx.getWebSockets().length >= MAX_SOCKETS) return new Response('busy', { status: 429 });

    await this.ctx.storage.put('code', code);
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    return new Response(null, { status: 101, webSocket: client });
  }

  async load(now) {
    const stored = await this.ctx.storage.get('room');
    if (stored) return stored;
    const code = (await this.ctx.storage.get('code')) ?? 'AAAAA';
    return createRoom(code, now);
  }

  async webSocketMessage(ws, raw) {
    if (typeof raw !== 'string' || raw.length > MAX_MESSAGE) return;
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }
    if (!msg || typeof msg !== 'object') return;
    const now = Date.now();
    let state = await this.load(now);

    if (msg.type === 'join') {
      const result = join(state, { pid: msg.pid, name: msg.name, config: msg.config }, now);
      if (result.error) {
        this.send(ws, { type: 'error', code: result.error });
        this.closeQuietly(ws, 1000, result.error);
        return;
      }
      // Тот же игрок с нового соединения (вернулся в приложение): старое закрываем, место не теряется
      for (const other of this.ctx.getWebSockets()) {
        if (other !== ws && this.pidOf(other) === msg.pid) this.closeQuietly(other, 1000, 'replaced');
      }
      ws.serializeAttachment({ pid: msg.pid });
      state = result.state;
    } else {
      const pid = this.pidOf(ws);
      if (!pid) return;
      let result = null;
      switch (msg.type) {
        case 'start':
          result = start(state, pid, now);
          break;
        case 'answer':
          result = answer(state, pid, { q: msg.q, correct: msg.correct, ms: msg.ms }, now);
          break;
        case 'rematch':
          result = rematch(state, pid, now, 1 + Math.floor(Math.random() * 2147483646));
          break;
        case 'leave':
          state = leave(state, pid, now);
          this.closeQuietly(ws, 1000, 'left');
          break;
        default:
          return;
      }
      if (result) {
        if (result.error) {
          // Ошибка правил (например, запоздалый ответ) клиенту не нужна: он получит свежее состояние
          this.send(ws, { type: 'state', state: view(state, pid, now) });
          return;
        }
        state = result.state;
      }
    }

    state = tick(state, now);
    await this.commit(state, now);
  }

  async webSocketClose(ws) {
    await this.dropped(ws);
  }

  async webSocketError(ws) {
    await this.dropped(ws);
  }

  async dropped(ws) {
    const pid = this.pidOf(ws);
    if (!pid) return;
    // Есть другое живое соединение того же игрока (он уже переподключился): значит, он на связи
    const alive = this.ctx.getWebSockets().some((s) => s !== ws && s.readyState === 1 && this.pidOf(s) === pid);
    if (alive) return;
    const now = Date.now();
    const state = setConnected(await this.load(now), pid, false, now);
    await this.commit(state, now);
  }

  async alarm() {
    const now = Date.now();
    const state = await this.load(now);
    if (state.phase === 'new') return;
    if (isExpired(state, now)) {
      for (const ws of this.ctx.getWebSockets()) this.closeQuietly(ws, 1000, 'expired');
      const code = state.code;
      await this.ctx.storage.deleteAll();
      await this.ctx.storage.put('code', code);
      return;
    }
    await this.commit(tick(state, now), now);
  }

  /** Сохраняет состояние, рассылает каждому его вид и назначает ближайшее пробуждение */
  async commit(state, now) {
    if (state.phase === 'new') {
      await this.ctx.storage.delete('room');
      await this.ctx.storage.deleteAlarm();
    } else {
      await this.ctx.storage.put('room', state);
      const next = nextDeadline(state);
      if (next === null) await this.ctx.storage.deleteAlarm();
      else await this.ctx.storage.setAlarm(Math.max(next, now + 1));
    }
    for (const ws of this.ctx.getWebSockets()) {
      const pid = this.pidOf(ws);
      if (pid) this.send(ws, { type: 'state', state: view(state, pid, now) });
    }
  }

  pidOf(ws) {
    try {
      const attachment = ws.deserializeAttachment();
      return attachment && typeof attachment.pid === 'string' ? attachment.pid : null;
    } catch {
      return null;
    }
  }

  send(ws, payload) {
    try {
      ws.send(JSON.stringify(payload));
    } catch {
      // сокет уже закрыт: webSocketClose отметит игрока ушедшим
    }
  }

  closeQuietly(ws, code, reason) {
    try {
      ws.close(code, reason);
    } catch {
      // уже закрыт
    }
  }
}

export { LIMITS };

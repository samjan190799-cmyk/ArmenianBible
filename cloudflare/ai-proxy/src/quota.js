// Счётчик запросов за сутки (по UTC). Один Durable Object на подписчика и один общий на весь сервис:
// общий — потолок расходов, если кто-то попытается злоупотребить.

function today() {
  return new Date().toISOString().slice(0, 10);
}

export class Quota {
  constructor(state) {
    this.state = state;
  }

  async fetch(request) {
    const url = new URL(request.url);
    const body = await request.json().catch(() => ({}));
    const limit = Number(body.limit) || 0;

    const day = await this.state.storage.get('day');
    let count = (await this.state.storage.get('count')) ?? 0;
    if (day !== today()) {
      count = 0;
      await this.state.storage.put('day', today());
    }

    if (url.pathname === '/refund') {
      count = Math.max(0, count - 1);
      await this.state.storage.put('count', count);
      return Response.json({ ok: true, used: count, limit });
    }

    if (count >= limit) {
      await this.state.storage.put('count', count);
      return Response.json({ ok: false, used: count, limit }, { status: 429 });
    }
    count += 1;
    await this.state.storage.put('count', count);
    return Response.json({ ok: true, used: count, limit });
  }
}

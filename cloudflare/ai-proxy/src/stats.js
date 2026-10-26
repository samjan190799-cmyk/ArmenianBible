// Счётчики воронки: один Durable Object на всё приложение. Ключи:
//   c|ДЕНЬ|событие|измерение            сколько раз случилось (измерение '' — всего, «source=ai» — с таким параметром)
//   u|ДЕНЬ|событие|измерение|человек     отметка, что этот человек был (отсюда считаем людей, а не нажатия)
//   f|человек                            когда впервые увидели
//   n|ДЕНЬ|человек                       сколько событий за день уже принято (потолок против накрутки)
// Человек — случайный идентификатор установки: он не связан ни с Apple ID, ни с рекламным идентификатором.

const DAY_LIMIT_PER_INSTALL = 400;

export function lastDays(count, now = new Date()) {
  const days = [];
  for (let i = count - 1; i >= 0; i--) {
    days.push(new Date(now.getTime() - i * 86_400_000).toISOString().slice(0, 10));
  }
  return days;
}

export class Stats {
  constructor(state) {
    this.storage = state.storage;
  }

  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === '/ingest') return Response.json(await this.ingest(await request.json()));
    if (url.pathname === '/report') return Response.json(await this.report(Number(url.searchParams.get('days')) || 14));
    return new Response('not found', { status: 404 });
  }

  async bump(key) {
    await this.storage.put(key, ((await this.storage.get(key)) ?? 0) + 1);
  }

  /** true, если отметка поставлена впервые */
  async mark(key) {
    if (await this.storage.get(key)) return false;
    await this.storage.put(key, 1);
    return true;
  }

  async ingest({ day, installId, lang, app, premium, events }) {
    const countKey = `n|${day}|${installId}`;
    let used = (await this.storage.get(countKey)) ?? 0;
    if (used >= DAY_LIMIT_PER_INSTALL) return { accepted: 0 };

    if (await this.mark(`f|${installId}`)) await this.bump(`c|${day}|_new|`);
    if (await this.mark(`u|${day}|_active||${installId}`)) {
      await this.bump(`c|${day}|_active|`);
      await this.bump(`c|${day}|_active|lang=${lang}`);
      await this.bump(`c|${day}|_active|premium=${premium ? 'yes' : 'no'}`);
      await this.bump(`c|${day}|_active|app=${app}`);
    }

    let accepted = 0;
    for (const event of events) {
      if (used >= DAY_LIMIT_PER_INSTALL) break;
      used += 1;
      accepted += 1;
      const dims = ['', ...Object.entries(event.dims).map(([key, value]) => `${key}=${value}`)];
      for (const dim of dims) {
        await this.bump(`c|${day}|${event.name}|${dim}`);
        await this.mark(`u|${day}|${event.name}|${dim}|${installId}`);
      }
    }
    await this.storage.put(countKey, used);
    return { accepted };
  }

  /** Сводка за последние дни: по каждому событию и параметру — сколько раз и сколько разных людей */
  async report(daysRequested) {
    const days = lastDays(Math.min(Math.max(daysRequested, 1), 90));
    const events = {};
    const daily = [];

    const cell = (name, dim) => {
      events[name] ??= {};
      events[name][dim] ??= { events: 0, people: new Set() };
      return events[name][dim];
    };

    for (const day of days) {
      const row = { day, active: 0, newInstalls: 0, paywallShown: 0, purchases: 0 };
      for (const [key, value] of await this.storage.list({ prefix: `c|${day}|` })) {
        const [, , name, dim] = key.split('|');
        cell(name, dim).events += value;
        if (name === '_active' && dim === '') row.active = value;
        if (name === '_new' && dim === '') row.newInstalls = value;
        if (name === 'paywall_shown' && dim === '') row.paywallShown = value;
        if (name === 'purchase_result' && dim === 'result=success') row.purchases = value;
      }
      for (const key of (await this.storage.list({ prefix: `u|${day}|` })).keys()) {
        const [, , name, dim, installId] = key.split('|');
        cell(name, dim).people.add(installId);
      }
      daily.push(row);
    }

    const out = {};
    for (const [name, dims] of Object.entries(events)) {
      out[name] = {};
      for (const [dim, data] of Object.entries(dims)) out[name][dim] = { events: data.events, people: data.people.size };
    }
    return { days, daily, events: out };
  }
}

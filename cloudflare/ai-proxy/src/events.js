// Воронка: какие события принимаем и какие параметры у них допустимы. Всё остальное отбрасывается, поэтому
// в статистику не может попасть ни текст вопросов, ни что-то личное: только короткие слова из этого списка.

export const EVENTS = {
  app_open: ['day'],
  paywall_shown: ['source', 'trial'],
  paywall_plan: ['plan'],
  paywall_closed: ['source', 'secs'],
  purchase_started: ['plan', 'source'],
  purchase_result: ['result', 'plan'],
  restore_result: ['result'],
  products_loaded: ['result'],
  feature_used: ['feature'],
  ai_result: ['result', 'via']
};

const VALUE = /^[a-z0-9_.-]{1,32}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const MAX_EVENTS = 25;

/** Проверяет пачку событий от приложения и приводит её к безопасному виду. null, если принимать нечего */
export function parseBatch(body) {
  if (!body || typeof body !== 'object') return null;
  const installId = String(body.installId || '').toLowerCase();
  if (!UUID.test(installId)) return null;
  if (!Array.isArray(body.events) || body.events.length === 0) return null;

  const lang = ['hy', 'ru', 'en'].includes(body.lang) ? body.lang : 'xx';
  const app = /^[0-9.]{1,12}$/.test(String(body.app)) ? String(body.app) : '0';

  const events = [];
  for (const raw of body.events.slice(0, MAX_EVENTS)) {
    const name = raw && typeof raw.name === 'string' ? raw.name : '';
    if (!Object.hasOwn(EVENTS, name)) continue;
    const dims = {};
    for (const key of EVENTS[name]) {
      const value = String(raw.params?.[key] ?? '').toLowerCase();
      if (VALUE.test(value)) dims[key] = value;
    }
    events.push({ name, dims });
  }
  if (events.length === 0) return null;
  return { installId, lang, app, premium: body.premium === true, events };
}

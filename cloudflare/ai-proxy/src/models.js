// Каталог моделей ИИ для приложения: кнопка «Обновить модели» в настройках берёт список отсюда (GET /v1/models),
// поэтому новые модели Google, OpenAI и Anthropic доступны без выпуска новой версии в App Store.
// Порядок важен: от модели по умолчанию (быстрая и недорогая) к более мощным запасным. Приложение пробует их по очереди.
// Список сверен с официальной документацией провайдеров 2026-11-05:
//   Google:    https://ai.google.dev/gemini-api/docs/models и /deprecations
//   OpenAI:    https://developers.openai.com/api/docs/models и /deprecations
//   Anthropic: https://platform.claude.com/docs/en/about-claude/model-deprecations
// Чтобы сменить список без правки кода, задайте переменную AI_MODEL_CATALOG (JSON такого же вида) в настройках Worker.

export const MODEL_CATALOG = {
  version: 1,
  updated: '2026-11-05',
  gemini: ['gemini-3.5-flash-lite', 'gemini-3.6-flash', 'gemini-3.8-flash', 'gemini-2.5-flash-lite'],
  openai: ['gpt-6-luna', 'gpt-6.1-terra', 'gpt-6.1-sol'],
  claude: ['claude-haiku-5-5', 'claude-sonnet-5-5', 'claude-sonnet-5', 'claude-haiku-4-5']
};

const PROVIDERS = ['gemini', 'openai', 'claude'];
const MAX_PER_PROVIDER = 8;
// Идентификатор попадает в адрес запроса к провайдеру, поэтому пропускаем только безопасные символы
const MODEL_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{2,63}$/;

/** Оставляет в списке только допустимые идентификаторы без повторов */
function cleanList(list) {
  if (!Array.isArray(list)) return [];
  const seen = new Set();
  const result = [];
  for (const item of list) {
    if (typeof item !== 'string') continue;
    const id = item.trim();
    if (!MODEL_ID.test(id) || seen.has(id)) continue;
    seen.add(id);
    result.push(id);
    if (result.length >= MAX_PER_PROVIDER) break;
  }
  return result;
}

/**
 * Каталог для ответа: из переменной AI_MODEL_CATALOG, если она задана и верна, иначе встроенный.
 * Поставщик без единой верной модели берётся из встроенного каталога, чтобы приложение не осталось с пустым списком.
 */
export function readCatalog(env = {}) {
  let custom = null;
  if (typeof env.AI_MODEL_CATALOG === 'string' && env.AI_MODEL_CATALOG.trim()) {
    try {
      custom = JSON.parse(env.AI_MODEL_CATALOG);
    } catch {
      custom = null;
    }
  }
  if (!custom || typeof custom !== 'object') return { ...MODEL_CATALOG };

  const catalog = {
    version: Number.isInteger(custom.version) && custom.version > 0 ? custom.version : MODEL_CATALOG.version,
    updated: typeof custom.updated === 'string' && custom.updated.length <= 32 ? custom.updated : MODEL_CATALOG.updated
  };
  for (const provider of PROVIDERS) {
    const list = cleanList(custom[provider]);
    catalog[provider] = list.length ? list : [...MODEL_CATALOG[provider]];
  }
  return catalog;
}

// Задачи ИИ: приложение говорит, для чего запрос (чат, викторина, «Нарек утешает», толкование, подбор стиха).
// Для каждой задачи можно задать СВОЙ ключ Gemini, свой список моделей и свой суточный потолок запросов.
// Так расход одной задачи не съедает квоту другой, а ключ можно отозвать или заменить по задаче.
//
//   секрет GEMINI_API_KEY_<ЗАДАЧА>   например GEMINI_API_KEY_CHAT:  wrangler secret put GEMINI_API_KEY_CHAT
//   переменная GEMINI_MODELS_<ЗАДАЧА>  свой список моделей задачи (через запятую)
//   переменная TASK_DAILY_LIMIT_<ЗАДАЧА>  сколько запросов в сутки (по UTC) разрешено задаче на всех вместе
//
// Что не задано, берётся общее: GEMINI_API_KEY и GEMINI_MODELS работают как раньше, потолка у задачи нет.

export const TASKS = ['chat', 'quiz', 'consolation', 'explain', 'verse'];

/** Неизвестное или пустое имя задачи превращается в 'general': имя из приложения в настройки не подставляется напрямую */
export function normalizeTask(value) {
  return typeof value === 'string' && TASKS.includes(value) ? value : 'general';
}

function suffixOf(task) {
  return String(task).toUpperCase();
}

function stringSetting(env, name) {
  const value = env[name];
  return typeof value === 'string' ? value.trim() : '';
}

/** Ключ и модели Gemini для задачи (в виде, который понимает gemini.js): свои, если заданы, иначе общие */
export function geminiEnvFor(env, task) {
  const suffix = suffixOf(task);
  const own = (name) => (task === 'general' ? '' : stringSetting(env, `${name}_${suffix}`));
  return {
    GEMINI_API_KEY: own('GEMINI_API_KEY') || env.GEMINI_API_KEY,
    GEMINI_MODELS: own('GEMINI_MODELS') || env.GEMINI_MODELS
  };
}

/** Суточный потолок задачи на всех вместе; 0, если не задан (тогда работают только общие лимиты) */
export function taskDailyLimit(env, task) {
  if (task === 'general') return 0;
  const limit = Number(stringSetting(env, `TASK_DAILY_LIMIT_${suffixOf(task)}`));
  return Number.isFinite(limit) && limit > 0 ? Math.floor(limit) : 0;
}

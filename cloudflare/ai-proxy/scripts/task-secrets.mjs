// Ключи Gemini из секретов GitHub для передачи Worker при выпуске (см. .github/workflows/ai-proxy.yml).
// Имя секрета в GitHub совпадает с именем секрета Worker: GEMINI_API_KEY (общий) и GEMINI_API_KEY_<ЗАДАЧА>
// для каждой задачи из src/tasks.js: CHAT, QUIZ, CONSOLATION, EXPLAIN, VERSE.
// Берутся только непустые: что в GitHub не задано, в Cloudflare остаётся как есть.

import { TASKS } from '../src/tasks.js';

export const SECRET_NAMES = ['GEMINI_API_KEY', ...TASKS.map((task) => `GEMINI_API_KEY_${task.toUpperCase()}`)];

/** Объект {имя: значение} для `wrangler secret bulk`: только заданные непустые ключи */
export function collectTaskSecrets(env) {
  const result = {};
  for (const name of SECRET_NAMES) {
    const value = typeof env[name] === 'string' ? env[name].trim() : '';
    if (value) result[name] = value;
  }
  return result;
}

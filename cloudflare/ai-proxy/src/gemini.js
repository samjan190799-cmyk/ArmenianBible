// Запрос к Gemini с ключом сервера. Текст запросов и ответов нигде не пишем.

// Модели по умолчанию, если GEMINI_MODELS не задана. gemini-2.0-flash закрыта Google (июнь 2026),
// gemini-2.5-flash с 1 декабря 2026 перенаправляется на gemini-3.5-flash-lite
export const DEFAULT_MODELS = 'gemini-3.5-flash-lite,gemini-3.6-flash,gemini-2.5-flash-lite';

// Сколько ждать ответа одной модели, чтобы зависшая не съела всё время и не помешала запасной
const REQUEST_TIMEOUT_MS = 25_000;

// Общий срок на все модели одного вопроса. Приложение ждёт ответ 60 секунд, поэтому сервер должен уложиться раньше
// и ответить понятным 502, а не молчать до таймаута приложения (три модели по 25 секунд могли занять 75)
export const TOTAL_BUDGET_MS = 45_000;

// Меньше этого запаса на следующую модель не оставляем: она всё равно не успеет ответить
const MIN_ATTEMPT_MS = 4_000;

// Запас токенов на «размышление» моделей Gemini 3: оно входит в maxOutputTokens, и без запаса короткий лимит
// съедается целиком, а ответ приходит пустым
const THINKING_HEADROOM = 1024;

export class GenerateError extends Error {
  constructor(status, trail = []) {
    super(`gemini_${status}`);
    this.status = status;
    /** Что вышло у каждой модели по порядку: [{ model, kind }], kind вроде «http_503», «timeout», «empty_safety». Без текста запросов и ответов */
    this.trail = trail;
  }
}

export function generationConfigFor(model, { json, maxTokens }) {
  const generationConfig = { temperature: 0.85, maxOutputTokens: maxTokens };
  if (json) generationConfig.responseMimeType = 'application/json';
  if (model.startsWith('gemini-2.5-flash')) {
    // У 2.5 Flash «размышление» съедает лимит токенов и ответ выходит пустым: для короткой справки оно не нужно
    generationConfig.thinkingConfig = { thinkingBudget: 0 };
  } else if (model.startsWith('gemini-3')) {
    generationConfig.maxOutputTokens = maxTokens + THINKING_HEADROOM;
  }
  return generationConfig;
}

/** Одно слово для счётчиков: строчные латиница, цифры и знаки «_ . -» */
function slug(value) {
  return String(value ?? '')
    .toLowerCase()
    .replace(/[^a-z0-9_.-]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 24);
}

/** Почему ответ пришёл пустым: Google заблокировал запрос или оборвал ответ (по причине, которую он сам назвал) */
function emptyKind(data) {
  const blocked = data?.promptFeedback?.blockReason;
  if (blocked) return `blocked_${slug(blocked)}`;
  const finish = data?.candidates?.[0]?.finishReason;
  return finish ? `empty_${slug(finish)}` : 'empty';
}

function isTimeout(error) {
  return error?.name === 'TimeoutError' || error?.name === 'AbortError';
}

/**
 * Идёт по моделям по очереди, пока одна не ответит. Возвращает { text, model, trail }, где trail это неудачи моделей,
 * которые были до ответившей (пусто, если первая ответила сразу). Если не ответила ни одна, бросает GenerateError с trail.
 * `nowFn` подменяется в тестах, чтобы проверять общий срок без настоящего ожидания.
 */
export async function generate(env, { prompt, system, json, maxTokens }, fetchFn = fetch, nowFn = Date.now) {
  const models = (env.GEMINI_MODELS || DEFAULT_MODELS).split(',').map((s) => s.trim()).filter(Boolean);
  const started = nowFn();
  const trail = [];
  let lastStatus = 502;

  for (const model of models) {
    // Первая модель пробуется всегда; следующим нужен запас времени, иначе приложение уже не дождётся ответа
    const left = TOTAL_BUDGET_MS - (nowFn() - started);
    if (trail.length > 0 && left < MIN_ATTEMPT_MS) break;
    const timeoutMs = Math.min(REQUEST_TIMEOUT_MS, Math.max(MIN_ATTEMPT_MS, left));

    const body = { contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig: generationConfigFor(model, { json, maxTokens }) };
    if (system) body.systemInstruction = { parts: [{ text: system }] };

    let res;
    try {
      res = await fetchFn(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(timeoutMs)
      });
    } catch (error) {
      // Сеть или таймаут: пробуем следующую модель, а не бросаем весь запрос
      trail.push({ model, kind: isTimeout(error) ? 'timeout' : 'net' });
      lastStatus = 504;
      continue;
    }

    if (res.ok) {
      let data;
      try {
        data = await res.json();
      } catch (error) {
        trail.push({ model, kind: isTimeout(error) ? 'timeout' : 'bad_json' });
        lastStatus = 502;
        continue;
      }
      const parts = data.candidates?.[0]?.content?.parts ?? [];
      // Куски с мыслями модели (thought) в ответ человеку не берём
      const text = parts.filter((p) => !p.thought).map((p) => p.text ?? '').join('').trim();
      if (text) return { text, model, trail };
      trail.push({ model, kind: emptyKind(data) });
      lastStatus = 502;
      continue;
    }
    trail.push({ model, kind: `http_${res.status}` });
    lastStatus = res.status;
    // Ключ не принят или квота Google исчерпана: другая модель не поможет
    if (res.status === 401 || res.status === 403 || res.status === 429) break;
  }
  throw new GenerateError(lastStatus, trail);
}

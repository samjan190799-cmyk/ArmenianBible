// Запрос к Gemini с ключом сервера. Текст запросов и ответов нигде не пишем.

// Модели по умолчанию, если GEMINI_MODELS не задана. gemini-2.0-flash закрыта Google (июнь 2026),
// gemini-2.5-flash с 1 декабря 2026 перенаправляется на gemini-3.5-flash-lite
export const DEFAULT_MODELS = 'gemini-3.5-flash-lite,gemini-3.6-flash,gemini-2.5-flash-lite';

// Сколько ждать ответа одной модели, чтобы зависшая не съела всё время и не помешала запасной
const REQUEST_TIMEOUT_MS = 25_000;

// Запас токенов на «размышление» моделей Gemini 3: оно входит в maxOutputTokens, и без запаса короткий лимит
// съедается целиком, а ответ приходит пустым
const THINKING_HEADROOM = 1024;

export class GenerateError extends Error {
  constructor(status) {
    super(`gemini_${status}`);
    this.status = status;
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

export async function generate(env, { prompt, system, json, maxTokens }, fetchFn = fetch) {
  const models = (env.GEMINI_MODELS || DEFAULT_MODELS).split(',').map((s) => s.trim()).filter(Boolean);
  let lastStatus = 502;

  for (const model of models) {
    const body = { contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig: generationConfigFor(model, { json, maxTokens }) };
    if (system) body.systemInstruction = { parts: [{ text: system }] };

    let res;
    try {
      res = await fetchFn(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
      });
    } catch {
      // Сеть или таймаут: пробуем следующую модель, а не бросаем весь запрос
      lastStatus = 504;
      continue;
    }

    if (res.ok) {
      let data;
      try {
        data = await res.json();
      } catch {
        lastStatus = 502;
        continue;
      }
      const parts = data.candidates?.[0]?.content?.parts ?? [];
      // Куски с мыслями модели (thought) в ответ человеку не берём
      const text = parts.filter((p) => !p.thought).map((p) => p.text ?? '').join('').trim();
      if (text) return { text, model };
      lastStatus = 502;
      continue;
    }
    lastStatus = res.status;
    // Ключ не принят или квота Google исчерпана: другая модель не поможет
    if (res.status === 401 || res.status === 403 || res.status === 429) break;
  }
  throw new GenerateError(lastStatus);
}

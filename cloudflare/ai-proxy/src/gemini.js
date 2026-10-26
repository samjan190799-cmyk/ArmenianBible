// Запрос к Gemini с ключом сервера. Текст запросов и ответов нигде не пишем.

export class GenerateError extends Error {
  constructor(status) {
    super(`gemini_${status}`);
    this.status = status;
  }
}

export async function generate(env, { prompt, system, json, maxTokens }, fetchFn = fetch) {
  const models = (env.GEMINI_MODELS || 'gemini-2.5-flash').split(',').map((s) => s.trim()).filter(Boolean);
  let lastStatus = 502;

  for (const model of models) {
    const generationConfig = { temperature: 0.85, maxOutputTokens: maxTokens };
    if (json) generationConfig.responseMimeType = 'application/json';
    // У 2.5 Flash «размышление» съедает лимит токенов и ответ выходит пустым: для короткой справки оно не нужно
    if (model.startsWith('gemini-2.5-flash')) generationConfig.thinkingConfig = { thinkingBudget: 0 };

    const body = { contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig };
    if (system) body.systemInstruction = { parts: [{ text: system }] };

    const res = await fetchFn(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
      body: JSON.stringify(body)
    });

    if (res.ok) {
      const data = await res.json();
      const text = (data.candidates?.[0]?.content?.parts ?? []).map((p) => p.text ?? '').join('').trim();
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

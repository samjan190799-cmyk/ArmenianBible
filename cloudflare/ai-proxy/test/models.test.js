import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { MODEL_CATALOG, readCatalog } from '../src/models.js';
import { generate, generationConfigFor, GenerateError } from '../src/gemini.js';

const PROVIDERS = ['gemini', 'openai', 'claude'];

// --- Каталог моделей для кнопки «Обновить модели»

test('GET /v1/models отдаёт каталог без авторизации и разрешает кэш', async () => {
  const res = await worker.fetch(new Request('https://luys.example/v1/models'), {}, {});
  assert.equal(res.status, 200);
  assert.match(res.headers.get('cache-control') || '', /max-age=\d+/);
  const data = await res.json();
  for (const provider of PROVIDERS) {
    assert.ok(Array.isArray(data[provider]) && data[provider].length > 0, provider);
  }
  assert.equal(typeof data.version, 'number');
  assert.equal(typeof data.updated, 'string');
});

test('POST на /v1/models не принимается', async () => {
  const res = await worker.fetch(new Request('https://luys.example/v1/models', { method: 'POST', body: '{}' }), {}, {});
  assert.equal(res.status, 404);
});

test('встроенный каталог: у всех трёх провайдеров верные идентификаторы без устаревших семейств', () => {
  const retired = /^(gemini-1\.5|gemini-2\.0|claude-3|gpt-3\.5|gpt-4\.5|o1|o3-mini)/;
  for (const provider of PROVIDERS) {
    for (const id of MODEL_CATALOG[provider]) {
      assert.match(id, /^[A-Za-z0-9][A-Za-z0-9._-]{2,63}$/, id);
      assert.doesNotMatch(id, retired, id);
    }
  }
  assert.ok(MODEL_CATALOG.gemini.every((id) => id.startsWith('gemini-')));
  assert.ok(MODEL_CATALOG.openai.every((id) => id.startsWith('gpt-')));
  assert.ok(MODEL_CATALOG.claude.every((id) => id.startsWith('claude-')));
});

test('AI_MODEL_CATALOG заменяет список, плохие идентификаторы отбрасываются', () => {
  const custom = JSON.stringify({
    version: 7,
    updated: '2027-01-01',
    gemini: ['gemini-9-flash', '../etc/passwd', 'gemini-9-flash', 42, 'a b'],
    openai: ['gpt-9-luna'],
    claude: []
  });
  const catalog = readCatalog({ AI_MODEL_CATALOG: custom });
  assert.equal(catalog.version, 7);
  assert.equal(catalog.updated, '2027-01-01');
  assert.deepEqual(catalog.gemini, ['gemini-9-flash']);
  assert.deepEqual(catalog.openai, ['gpt-9-luna']);
  // пустой список провайдера не оставляет приложение без моделей
  assert.deepEqual(catalog.claude, MODEL_CATALOG.claude);
});

test('AI_MODEL_CATALOG с мусором вместо JSON не ломает ответ', () => {
  assert.deepEqual(readCatalog({ AI_MODEL_CATALOG: 'не json' }), MODEL_CATALOG);
  assert.deepEqual(readCatalog({ AI_MODEL_CATALOG: '[1,2]' }).gemini, MODEL_CATALOG.gemini);
  assert.deepEqual(readCatalog({}), MODEL_CATALOG);
});

test('через AI_MODEL_CATALOG маршрут отдаёт новый список', async () => {
  const env = { AI_MODEL_CATALOG: JSON.stringify({ gemini: ['gemini-9-flash-lite'] }) };
  const data = await (await worker.fetch(new Request('https://luys.example/v1/models'), env, {})).json();
  assert.deepEqual(data.gemini, ['gemini-9-flash-lite']);
  assert.deepEqual(data.openai, MODEL_CATALOG.openai);
});

// --- Запрос к Gemini: запасные модели, таймаут, параметры

const reply = (text) => Response.json({ candidates: [{ content: { parts: [{ text }] } }] });
const modelOf = (url) => /models\/([^:]+):generateContent/.exec(url)[1];
const args = { prompt: 'Привет', system: '', json: false, maxTokens: 512 };

test('первая модель вернула 404: пробуется следующая, и ответ приходит от неё', async () => {
  const asked = [];
  const fetchFn = async (url) => {
    asked.push(modelOf(url));
    return asked.length === 1 ? new Response('not found', { status: 404 }) : reply('Ответ');
  };
  const result = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'old-model,new-model' }, args, fetchFn);
  assert.equal(result.text, 'Ответ');
  assert.equal(result.model, 'new-model');
  assert.deepEqual(asked, ['old-model', 'new-model']);
});

test('сбой сети или таймаут у первой модели не обрывает цепочку', async () => {
  let calls = 0;
  const fetchFn = async () => {
    calls += 1;
    if (calls === 1) throw new TypeError('network down');
    return reply('Ответ');
  };
  const result = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'a-model,b-model' }, args, fetchFn);
  assert.equal(result.model, 'b-model');
});

test('пустой ответ первой модели: берём следующую', async () => {
  let calls = 0;
  const fetchFn = async () => (++calls === 1 ? Response.json({ candidates: [{ finishReason: 'MAX_TOKENS' }] }) : reply('Готово'));
  const result = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'a-model,b-model' }, args, fetchFn);
  assert.equal(result.text, 'Готово');
});

test('ключ не принят (403) или квота Google (429): другие модели не пробуются', async () => {
  for (const status of [401, 403, 429]) {
    let calls = 0;
    const fetchFn = async () => {
      calls += 1;
      return new Response('no', { status });
    };
    await assert.rejects(generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'a-model,b-model' }, args, fetchFn), (error) => {
      assert.ok(error instanceof GenerateError);
      assert.equal(error.status, status);
      return true;
    });
    assert.equal(calls, 1);
  }
});

test('мысли модели (thought) в ответ человеку не попадают', async () => {
  const fetchFn = async () => Response.json({ candidates: [{ content: { parts: [{ text: 'скрыто', thought: true }, { text: 'Видимый ' }, { text: 'ответ' }] } }] });
  const result = await generate({ GEMINI_API_KEY: 'k', GEMINI_MODELS: 'a-model' }, args, fetchFn);
  assert.equal(result.text, 'Видимый ответ');
});

test('без GEMINI_MODELS берётся актуальный список, а закрытой gemini-2.0-flash в нём нет', async () => {
  const asked = [];
  const fetchFn = async (url) => {
    asked.push(modelOf(url));
    return new Response('boom', { status: 500 });
  };
  await assert.rejects(generate({ GEMINI_API_KEY: 'k' }, args, fetchFn));
  assert.deepEqual(asked, ['gemini-3.5-flash-lite', 'gemini-3.6-flash', 'gemini-2.5-flash-lite']);
  assert.ok(!asked.some((id) => id.startsWith('gemini-2.0')));
});

test('параметры генерации: запас на размышление у Gemini 3 и отключённое размышление у 2.5 Flash', () => {
  const g3 = generationConfigFor('gemini-3.5-flash-lite', { json: false, maxTokens: 1000 });
  assert.equal(g3.maxOutputTokens, 2024);
  assert.equal(g3.thinkingConfig, undefined);

  const g25 = generationConfigFor('gemini-2.5-flash-lite', { json: true, maxTokens: 1000 });
  assert.equal(g25.maxOutputTokens, 1000);
  assert.deepEqual(g25.thinkingConfig, { thinkingBudget: 0 });
  assert.equal(g25.responseMimeType, 'application/json');
});

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { collectTaskSecrets, SECRET_NAMES } from '../scripts/task-secrets.mjs';

test('имена секретов: общий ключ и по одному на каждую задачу', () => {
  assert.deepEqual(SECRET_NAMES, [
    'GEMINI_API_KEY',
    'GEMINI_API_KEY_CHAT',
    'GEMINI_API_KEY_QUIZ',
    'GEMINI_API_KEY_CONSOLATION',
    'GEMINI_API_KEY_EXPLAIN',
    'GEMINI_API_KEY_VERSE'
  ]);
});

test('берутся только заданные непустые ключи, пробелы по краям срезаются', () => {
  const env = {
    GEMINI_API_KEY_CHAT: '  chat-key\n',
    GEMINI_API_KEY_QUIZ: 'quiz-key',
    GEMINI_API_KEY_VERSE: '',
    GEMINI_API_KEY_EXPLAIN: '   ',
    PATH: '/usr/bin',
    CLOUDFLARE_API_TOKEN: 'must-not-leak'
  };
  assert.deepEqual(collectTaskSecrets(env), { GEMINI_API_KEY_CHAT: 'chat-key', GEMINI_API_KEY_QUIZ: 'quiz-key' });
});

test('ничего не задано: пустой объект, чужие переменные окружения не попадают', () => {
  assert.deepEqual(collectTaskSecrets({}), {});
  assert.deepEqual(collectTaskSecrets({ CLOUDFLARE_API_TOKEN: 'x', GEMINI_API_KEY_OTHER: 'y' }), {});
});

test('значения не строки игнорируются', () => {
  assert.deepEqual(collectTaskSecrets({ GEMINI_API_KEY: 123, GEMINI_API_KEY_CHAT: null, GEMINI_API_KEY_QUIZ: {} }), {});
});

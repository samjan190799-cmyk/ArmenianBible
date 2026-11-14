import { test } from 'node:test';
import assert from 'node:assert/strict';
import { TASKS, normalizeTask, geminiEnvFor, taskDailyLimit } from '../src/tasks.js';

test('известные задачи остаются, неизвестные и чужие типы становятся general', () => {
  for (const task of TASKS) assert.equal(normalizeTask(task), task);
  for (const value of ['', 'CHAT', 'chat ', 'admin', undefined, null, 5, {}, ['chat']]) {
    assert.equal(normalizeTask(value), 'general');
  }
});

test('у задачи свои ключ и модели, а чего нет, берётся общее', () => {
  const env = {
    GEMINI_API_KEY: 'common',
    GEMINI_MODELS: 'common-model',
    GEMINI_API_KEY_CHAT: ' chat-key ',
    GEMINI_MODELS_QUIZ: 'quiz-model'
  };
  assert.deepEqual(geminiEnvFor(env, 'chat'), { GEMINI_API_KEY: 'chat-key', GEMINI_MODELS: 'common-model' });
  assert.deepEqual(geminiEnvFor(env, 'quiz'), { GEMINI_API_KEY: 'common', GEMINI_MODELS: 'quiz-model' });
  assert.deepEqual(geminiEnvFor(env, 'verse'), { GEMINI_API_KEY: 'common', GEMINI_MODELS: 'common-model' });
});

test('general всегда работает на общем ключе, даже если рядом заданы ключи задач', () => {
  const env = { GEMINI_API_KEY: 'common', GEMINI_API_KEY_GENERAL: 'must-not-be-used', GEMINI_API_KEY_CHAT: 'chat-key' };
  assert.equal(geminiEnvFor(env, 'general').GEMINI_API_KEY, 'common');
});

test('пустой или нечисловой ключ задачи не подменяет общий', () => {
  const env = { GEMINI_API_KEY: 'common', GEMINI_API_KEY_CHAT: '   ', GEMINI_API_KEY_QUIZ: 123 };
  assert.equal(geminiEnvFor(env, 'chat').GEMINI_API_KEY, 'common');
  assert.equal(geminiEnvFor(env, 'quiz').GEMINI_API_KEY, 'common');
});

test('суточный потолок задачи: число больше нуля или 0, если не задан и для general', () => {
  const env = { TASK_DAILY_LIMIT_QUIZ: '50', TASK_DAILY_LIMIT_CHAT: '0', TASK_DAILY_LIMIT_EXPLAIN: 'много', TASK_DAILY_LIMIT_VERSE: '7.9', TASK_DAILY_LIMIT_GENERAL: '5' };
  assert.equal(taskDailyLimit(env, 'quiz'), 50);
  assert.equal(taskDailyLimit(env, 'chat'), 0);
  assert.equal(taskDailyLimit(env, 'explain'), 0);
  assert.equal(taskDailyLimit(env, 'verse'), 7);
  assert.equal(taskDailyLimit(env, 'consolation'), 0);
  assert.equal(taskDailyLimit(env, 'general'), 0);
});

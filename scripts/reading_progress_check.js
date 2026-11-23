'use strict';
// Проверка логики прогресса чтения на Node: порт Sources/ReadingProgress.swift и ReadingProgressStore.swift
// (Swift локально не запускается). Те же фикстуры лежат в Tests/ReadingProgressTests/ReadingProgressTests.swift.
// Запуск: node scripts/reading_progress_check.js

const assert = require('assert');

// ---------- Порт модели ----------
const CURRENT_SCHEMA = 2;

function newProgress() {
  return { schema: CURRENT_SCHEMA, books: new Map(), lastBookId: null, lastUpdatedAt: 0 };
}
function newBook() {
  return { read: new Map(), cleared: new Map(), position: null };
}
function bookIsEmpty(b) { return b.read.size === 0 && b.cleared.size === 0 && b.position === null; }
function isEmpty(p) { for (const b of p.books.values()) if (!bookIsEmpty(b)) return false; return true; }

function positionIsNewer(x, y) {
  if (x.updatedAt !== y.updatedAt) return x.updatedAt > y.updatedAt;
  if (x.chapter !== y.chapter) return x.chapter > y.chapter;
  return (x.verse || 0) > (y.verse || 0);
}

function mergeBook(a, b) {
  a = a || newBook(); b = b || newBook();
  const res = newBook();
  const chapters = new Set([...a.read.keys(), ...b.read.keys(), ...a.cleared.keys(), ...b.cleared.keys()]);
  for (const ch of chapters) {
    const rs = [a.read.get(ch), b.read.get(ch)].filter(v => v !== undefined);
    const cs = [a.cleared.get(ch), b.cleared.get(ch)].filter(v => v !== undefined);
    const readAt = rs.length ? Math.max(...rs) : undefined;
    const clearedAt = cs.length ? Math.max(...cs) : undefined;
    if (readAt !== undefined && (clearedAt === undefined || readAt > clearedAt)) res.read.set(ch, readAt);
    if (clearedAt !== undefined) res.cleared.set(ch, clearedAt);
  }
  if (a.position && b.position) res.position = positionIsNewer(b.position, a.position) ? b.position : a.position;
  else res.position = a.position || b.position || null;
  return res;
}

function merged(a, b) {
  const res = newProgress();
  for (const id of new Set([...a.books.keys(), ...b.books.keys()])) {
    const book = mergeBook(a.books.get(id), b.books.get(id));
    if (!bookIsEmpty(book)) res.books.set(id, book);
  }
  const cands = [a, b].filter(p => p.lastBookId !== null).map(p => ({ id: p.lastBookId, at: p.lastUpdatedAt }));
  if (cands.length) {
    const best = cands.reduce((m, c) => (c.at !== m.at ? (c.at > m.at ? c : m) : (c.id > m.id ? c : m)));
    res.lastBookId = best.id; res.lastUpdatedAt = best.at;
  }
  return res;
}

function markRead(p, bookId, ch, now) {
  if (!(bookId > 0 && ch > 0)) return false;
  const b = p.books.get(bookId) || newBook();
  if (b.read.has(ch)) return false;
  b.read.set(ch, now); b.cleared.delete(ch); p.books.set(bookId, b);
  return true;
}
function toggleRead(p, bookId, ch, now) {
  if (!(bookId > 0 && ch > 0)) return;
  const b = p.books.get(bookId) || newBook();
  if (b.read.has(ch)) { b.read.delete(ch); b.cleared.set(ch, now); p.books.set(bookId, b); }
  else markRead(p, bookId, ch, now);
}
function setPosition(p, bookId, ch, verse, now) {
  if (!(bookId > 0 && ch > 0)) return false;
  const v = (verse || 0) > 1 ? verse : null;
  const b = p.books.get(bookId) || newBook();
  if (b.position && b.position.chapter === ch && b.position.verse === v) return false;
  b.position = { chapter: ch, verse: v, updatedAt: now };
  p.books.set(bookId, b);
  p.lastBookId = bookId; p.lastUpdatedAt = now;
  return true;
}
function resumePoint(p, bookId) {
  const b = p.books.get(bookId);
  if (b && b.position && b.position.chapter > 0) return { chapter: b.position.chapter, verse: b.position.verse };
  if (b && b.read.size) { const m = Math.max(...b.read.keys()); if (m > 0) return { chapter: m, verse: null }; }
  return { chapter: 1, verse: null };
}
function clampedChapter(ch, count) {
  if (!(count > 0)) return Math.max(1, ch);
  return Math.min(Math.max(1, ch), count);
}
function clampedVerse(v, maxVerse) {
  if (v === null || v === undefined || !(v >= 1 && v <= maxVerse)) return null;
  return v;
}
function readChapters(p, bookId) { const b = p.books.get(bookId); return new Set(b ? b.read.keys() : []); }
function legacyReadSets(p) {
  const r = {};
  for (const [id, b] of p.books) if (b.read.size) r[String(id)] = [...b.read.keys()].sort((x, y) => x - y);
  return r;
}
function fromLegacyReadSets(sets) {
  const res = newProgress();
  for (const [key, chapters] of Object.entries(sets)) {
    const id = Number(key); if (!(Number.isInteger(id) && id > 0)) continue;
    for (const ch of chapters) if (Number.isInteger(ch) && ch > 0) {
      const b = res.books.get(id) || newBook(); b.read.set(ch, 0); res.books.set(id, b);
    }
  }
  return res;
}

// ---------- Порт миграции ----------
function migrate(snap) {
  const readByBook = new Map();
  for (const [key, chapters] of Object.entries(snap.readChapters || {})) {
    const id = Number(key); if (!(Number.isInteger(id) && id > 0)) continue;
    const valid = chapters.filter(c => c > 0);
    if (valid.length) readByBook.set(id, valid);
  }
  const res = fromLegacyReadSets(Object.fromEntries([...readByBook].map(([k, v]) => [String(k), v])));
  const positions = new Map();
  for (const [key, saved] of Object.entries(snap.positions || {})) {
    const id = Number(key); if (!(Number.isInteger(id) && id > 0 && saved.chapter > 0)) continue;
    const cleanVerse = (saved.verse || 0) > 1 ? saved.verse : null;
    let chapter = saved.chapter, verse = cleanVerse;
    const reads = readByBook.get(id);
    if (chapter <= 1 && cleanVerse === null && reads && Math.max(...reads) > 1) { chapter = Math.max(...reads); verse = null; }
    const at = Number.isFinite(saved.updatedAt) ? saved.updatedAt : 0;
    positions.set(id, { chapter, verse, updatedAt: at });
  }
  for (const [id, chapters] of readByBook) if (!positions.has(id)) positions.set(id, { chapter: Math.max(...chapters), verse: null, updatedAt: 0 });
  for (const [id, pos] of positions) { const b = res.books.get(id) || newBook(); b.position = pos; res.books.set(id, b); }
  const last = snap.lastBookId;
  if (last > 0 && positions.has(last)) { res.lastBookId = last; res.lastUpdatedAt = positions.get(last).updatedAt; }
  else if (positions.size) {
    const best = [...positions].reduce((m, c) => (c[1].updatedAt !== m[1].updatedAt ? (c[1].updatedAt > m[1].updatedAt ? c : m) : (c[0] > m[0] ? c : m)));
    res.lastBookId = best[0]; res.lastUpdatedAt = best[1].updatedAt;
  }
  return res;
}

// ---------- Порт JSON (Codable) ----------
function encode(p) {
  const books = {};
  for (const id of [...p.books.keys()].sort((a, b) => a - b)) {
    const b = p.books.get(id); if (bookIsEmpty(b)) continue;
    const obj = { read: {}, cleared: {} };
    for (const k of [...b.read.keys()].sort((x, y) => x - y)) obj.read[k] = b.read.get(k);
    for (const k of [...b.cleared.keys()].sort((x, y) => x - y)) obj.cleared[k] = b.cleared.get(k);
    if (b.position) obj.position = b.position;
    books[id] = obj;
  }
  return JSON.stringify({ books, lastBookId: p.lastBookId, lastUpdatedAt: p.lastUpdatedAt, schema: p.schema });
}
function decode(text) {
  let raw; try { raw = JSON.parse(text); } catch { return null; }
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const p = newProgress();
  p.schema = Number.isInteger(raw.schema) ? raw.schema : CURRENT_SCHEMA;
  const books = raw.books && typeof raw.books === 'object' ? raw.books : {};
  for (const [key, val] of Object.entries(books)) {
    const id = Number(key); if (!(Number.isInteger(id) && id > 0) || !val || typeof val !== 'object') continue;
    const b = newBook();
    for (const [k, v] of Object.entries(val.read || {})) { const ch = Number(k); if (Number.isInteger(ch) && ch > 0 && Number.isFinite(v)) b.read.set(ch, v); }
    for (const [k, v] of Object.entries(val.cleared || {})) { const ch = Number(k); if (Number.isInteger(ch) && ch > 0 && Number.isFinite(v)) b.cleared.set(ch, v); }
    const pos = val.position;
    if (pos && Number.isInteger(pos.chapter) && pos.chapter > 0) b.position = { chapter: pos.chapter, verse: Number.isInteger(pos.verse) ? pos.verse : null, updatedAt: Number.isFinite(pos.updatedAt) ? pos.updatedAt : 0 };
    if (!bookIsEmpty(b)) p.books.set(id, b);
  }
  p.lastBookId = Number.isInteger(raw.lastBookId) ? raw.lastBookId : null;
  p.lastUpdatedAt = Number.isFinite(raw.lastUpdatedAt) ? raw.lastUpdatedAt : 0;
  return p;
}

// ---------- Порт хранилища (defaults — обычный объект) ----------
const K = {
  model: 'reading_progress_v2', backup: 'reading_progress_backup_v1', migrated: 'reading_progress_migrated_schema',
  legacyRead: 'bible_read_chapters_by_book', lastBook: 'last_read_book_id', lastChapter: 'last_read_chapter',
  chPrefix: 'last_read_chapter_for_book_', vPrefix: 'last_read_verse_for_book_', uPrefix: 'last_read_updated_for_book_',
};
function intValue(x) {
  if (typeof x === 'number') return Number.isFinite(x) && Number.isInteger(Math.round(x)) ? Math.round(x) : null;
  if (typeof x === 'string' && /^-?\d+$/.test(x)) return parseInt(x, 10);
  return null;
}
function snapshotLegacy(sources) {
  const snap = { readChapters: {}, positions: {}, lastBookId: null, lastChapter: null };
  for (const d of sources) {
    const raw = d[K.legacyRead];
    if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
      for (const [key, value] of Object.entries(raw)) {
        if (!/^-?\d+$/.test(key) || !Array.isArray(value)) continue;
        const chapters = value.map(intValue).filter(c => c !== null && c > 0);
        snap.readChapters[key] = [...new Set([...(snap.readChapters[key] || []), ...chapters])].sort((a, b) => a - b);
      }
    }
    for (const [key, value] of Object.entries(d)) {
      if (!key.startsWith(K.chPrefix)) continue;
      const bookKey = key.slice(K.chPrefix.length);
      const ch = intValue(value);
      if (!/^-?\d+$/.test(bookKey) || snap.positions[bookKey] !== undefined || ch === null || ch <= 0) continue;
      const verse = intValue(d[K.vPrefix + bookKey]);
      const updated = typeof d[K.uPrefix + bookKey] === 'number' ? d[K.uPrefix + bookKey] : null;
      snap.positions[bookKey] = { chapter: ch, verse, updatedAt: updated };
    }
    if (snap.lastBookId === null) {
      const b = intValue(d[K.lastBook]);
      if (b !== null && b > 0) { snap.lastBookId = b; snap.lastChapter = intValue(d[K.lastChapter]); }
    }
  }
  return snap;
}
function snapshotIsEmpty(s) {
  return Object.values(s.readChapters).every(a => a.length === 0) && Object.keys(s.positions).length === 0 && s.lastBookId === null;
}
function lastLocation(p) {
  if (p.lastBookId === null) return null;
  const b = p.books.get(p.lastBookId);
  return b && b.position ? { bookId: p.lastBookId, chapter: b.position.chapter, verse: b.position.verse } : null;
}
function mirrorLegacyKeys(p, d) {
  d[K.legacyRead] = legacyReadSets(p);
  for (const [id, b] of p.books) {
    if (!b.position) continue;
    d[K.chPrefix + id] = b.position.chapter;
    if (b.position.verse !== null) d[K.vPrefix + id] = b.position.verse; else delete d[K.vPrefix + id];
  }
  const last = lastLocation(p);
  if (last) { d[K.lastBook] = last.bookId; d[K.lastChapter] = last.chapter; }
}
function save(p, d) { d[K.model] = encode(p); mirrorLegacyKeys(p, d); }
function loadOrMigrate(d, { crashAfterModel = false } = {}) {
  const existing = typeof d[K.model] === 'string' ? decode(d[K.model]) : null;
  const schema = intValue(d[K.migrated]) || 0;
  if (existing && schema >= CURRENT_SCHEMA) return existing;
  const snap = snapshotLegacy([d]);
  if (d[K.backup] === undefined && !snapshotIsEmpty(snap)) d[K.backup] = JSON.stringify(snap);
  let p = migrate(snap);
  if (existing) p = merged(existing, p);
  save(p, d);
  if (crashAfterModel) return p; // имитация обрыва: флаг не записан
  d[K.migrated] = CURRENT_SCHEMA;
  return p;
}

// ---------- Проверки ----------
let passed = 0;
function test(name, fn) { try { fn(); passed++; console.log('ok   ' + name); } catch (e) { console.log('FAIL ' + name + '\n     ' + e.message); process.exitCode = 1; } }
const setOf = a => new Set(a);
const range = (a, b) => Array.from({ length: b - a + 1 }, (_, i) => a + i);

const MATT = 40, MARK = 41, LUKE = 42, JOHN = 43;
function phoneDefaults() {
  // Данные с телефона пользователя: у Матфея 7/28, у Марка 2/16, у Луки 1/24, у Иоанна 5/21; сохранена глава 1 без стиха
  return {
    [K.legacyRead]: { '40': range(1, 7), '41': [1, 2], '42': [1], '43': range(1, 5) },
    [K.chPrefix + MATT]: 1,
    [K.lastBook]: MATT, [K.lastChapter]: 1,
  };
}

test('фикстура телефона: Матфей → глава 7, прочитанные не изменились', () => {
  const d = phoneDefaults();
  const p = loadOrMigrate(d);
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 7, verse: null });
  assert.deepStrictEqual([...readChapters(p, MATT)].sort((a, b) => a - b), range(1, 7));
  assert.deepStrictEqual([...readChapters(p, MARK)].sort(), [1, 2]);
  assert.deepStrictEqual([...readChapters(p, LUKE)], [1]);
  assert.deepStrictEqual([...readChapters(p, JOHN)].sort((a, b) => a - b), range(1, 5));
  // у книг без сохранённого места — наибольшая прочитанная
  assert.strictEqual(resumePoint(p, MARK).chapter, 2);
  assert.strictEqual(resumePoint(p, JOHN).chapter, 5);
  assert.strictEqual(resumePoint(p, LUKE).chapter, 1);
});

test('фикстура «ничего нет»: пустая модель, места нет, глава 1', () => {
  const d = {};
  const p = loadOrMigrate(d);
  assert.ok(isEmpty(p));
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 1, verse: null });
  assert.strictEqual(d[K.backup], undefined, 'пустую копию не пишем');
  assert.strictEqual(d[K.migrated], CURRENT_SCHEMA);
});

test('фикстура «сохранена глава 12 стих 9»: остаётся 12:9', () => {
  const d = { [K.chPrefix + MATT]: 12, [K.vPrefix + MATT]: 9, [K.legacyRead]: { '40': range(1, 12) } };
  const p = loadOrMigrate(d);
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 12, verse: 9 });
});

test('глава 1 со стихом остаётся (эвристика только для главы 1 без стиха)', () => {
  const d = { [K.chPrefix + MATT]: 1, [K.vPrefix + MATT]: 5, [K.legacyRead]: { '40': range(1, 7) } };
  assert.deepStrictEqual(resumePoint(loadOrMigrate(d), MATT), { chapter: 1, verse: 5 });
});

test('глава 1 без стиха и прочитана только она: остаётся 1', () => {
  const d = { [K.chPrefix + MATT]: 1, [K.legacyRead]: { '40': [1] } };
  assert.deepStrictEqual(resumePoint(loadOrMigrate(d), MATT), { chapter: 1, verse: null });
});

test('сохранённой главы нет вовсе: наибольшая прочитанная', () => {
  const d = { [K.legacyRead]: { '40': [2, 9, 4] } };
  assert.strictEqual(resumePoint(loadOrMigrate(d), MATT).chapter, 9);
});

test('миграция делает копию старых значений и не удаляет старые ключи', () => {
  const d = phoneDefaults();
  const before = JSON.stringify(d);
  loadOrMigrate(d);
  assert.ok(d[K.backup], 'есть резерв');
  const backup = JSON.parse(d[K.backup]);
  assert.deepStrictEqual(backup.readChapters['40'], range(1, 7));
  assert.strictEqual(backup.positions['40'].chapter, 1);
  assert.strictEqual(d[K.chPrefix + MATT], 7, 'зеркало старых ключей обновлено, а резерв хранит прежнее значение');
  assert.ok(Object.keys(JSON.parse(before)).every(k => k in d), 'ни один старый ключ не пропал');
});

test('миграция идемпотентна и второй запуск ничего не меняет', () => {
  const d = phoneDefaults();
  const p1 = loadOrMigrate(d);
  const snapshot = JSON.stringify(d);
  const p2 = loadOrMigrate(d);
  assert.strictEqual(encode(p1), encode(p2));
  assert.strictEqual(JSON.stringify(d), snapshot);
});

test('обрыв после записи модели (нет флага): повтор сливается без потерь и без порчи', () => {
  const d = phoneDefaults();
  const p1 = loadOrMigrate(d, { crashAfterModel: true });
  assert.strictEqual(d[K.migrated], undefined);
  // за время «обрыва» человек успел отметить ещё главу и записать место
  const m = decode(d[K.model]); markRead(m, MATT, 8, 1000); setPosition(m, MATT, 8, 3, 1000); d[K.model] = encode(m);
  const p2 = loadOrMigrate(d);
  assert.deepStrictEqual([...readChapters(p2, MATT)].sort((a, b) => a - b), range(1, 8));
  assert.deepStrictEqual(resumePoint(p2, MATT), { chapter: 8, verse: 3 });
  assert.ok(p1);
});

test('мусор в defaults не роняет миграцию', () => {
  const d = {
    [K.legacyRead]: { 'abc': [1, 2], '40': [1, 'x', -3, 0, 2.0, null, 5], '41': 'oops', '-5': [1] },
    [K.chPrefix + 'zzz']: 4, [K.chPrefix + MATT]: -2, [K.chPrefix + MARK]: 'семь',
    [K.vPrefix + MARK]: 'девять', [K.lastBook]: 'x', [K.lastChapter]: {},
    [K.model]: '{not json',
  };
  const p = loadOrMigrate(d);
  assert.deepStrictEqual([...readChapters(p, MATT)].sort((a, b) => a - b), [1, 2, 5]);
  assert.strictEqual(resumePoint(p, MATT).chapter, 5);
});

test('повреждённая модель при пометке «перенос сделан»: восстанавливается из зеркала старых ключей', () => {
  const d = phoneDefaults();
  loadOrMigrate(d);
  d[K.model] = 'garbage';
  const p = loadOrMigrate(d);
  assert.deepStrictEqual([...readChapters(p, MATT)].sort((a, b) => a - b), range(1, 7));
  assert.strictEqual(resumePoint(p, MATT).chapter, 7);
});

test('новое правило: открытие главы место не пишет; чтение пишет', () => {
  const p = newProgress();
  markRead(p, MATT, 7, 10); // открыли — отметили прочитанной (правило отметки прежнее)
  assert.strictEqual(setPosition(p, MATT, 7, null, 11), true);
  assert.strictEqual(setPosition(p, MATT, 7, null, 12), false, 'то же место время не обновляет');
  assert.strictEqual(p.books.get(MATT).position.updatedAt, 11);
  assert.strictEqual(setPosition(p, MATT, 7, 1, 13), false, 'стих 1 = начало главы, это то же место');
  // стих 1 приводится к null, то есть равен прежнему (7, null)
  assert.strictEqual(p.books.get(MATT).position.updatedAt, 11);
  assert.strictEqual(setPosition(p, MATT, 7, 12, 14), true);
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 7, verse: 12 });
  assert.strictEqual(setPosition(p, MATT, 7, null, 15), true, 'вернулся к началу главы: стих сбрасывается');
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 7, verse: null });
});

test('случайное открытие главы 1 не затирает место: markRead не трогает место', () => {
  const p = newProgress();
  setPosition(p, MATT, 7, 4, 100);
  markRead(p, MATT, 1, 200);
  assert.deepStrictEqual(resumePoint(p, MATT), { chapter: 7, verse: 4 });
});

test('границы: стих и глава', () => {
  assert.strictEqual(clampedVerse(30, 25), null);
  assert.strictEqual(clampedVerse(25, 25), 25);
  assert.strictEqual(clampedVerse(0, 25), null);
  assert.strictEqual(clampedVerse(null, 25), null);
  assert.strictEqual(clampedVerse(1, 25), 1);
  assert.strictEqual(clampedChapter(0, 28), 1);
  assert.strictEqual(clampedChapter(-4, 28), 1);
  assert.strictEqual(clampedChapter(99, 28), 28);
  assert.strictEqual(clampedChapter(7, 28), 7);
  assert.strictEqual(clampedChapter(7, 0), 7);
  const p = newProgress();
  assert.strictEqual(setPosition(p, MATT, 0, 3, 1), false);
  assert.strictEqual(setPosition(p, 0, 3, 3, 1), false);
  assert.strictEqual(markRead(p, MATT, 0, 1), false);
});

test('слияние: прочитанные объединяются, место — более свежее, записи без времени самые старые', () => {
  const a = newProgress(), b = newProgress();
  markRead(a, MATT, 1, 10); markRead(a, MATT, 2, 10); setPosition(a, MATT, 2, 5, 50);
  markRead(b, MATT, 2, 20); markRead(b, MATT, 3, 20); setPosition(b, MATT, 3, null, 60);
  markRead(b, MARK, 1, 5);
  const m = merged(a, b);
  assert.deepStrictEqual([...readChapters(m, MATT)].sort(), [1, 2, 3]);
  assert.deepStrictEqual([...readChapters(m, MARK)], [1]);
  assert.deepStrictEqual(resumePoint(m, MATT), { chapter: 3, verse: null });
  // запись без времени проигрывает
  const legacy = migrate({ readChapters: { '40': [1] }, positions: { '40': { chapter: 9, verse: 2, updatedAt: null } }, lastBookId: 40, lastChapter: 9 });
  assert.deepStrictEqual(resumePoint(merged(legacy, a), MATT), { chapter: 2, verse: 5 });
  assert.deepStrictEqual(resumePoint(merged(a, legacy), MATT), { chapter: 2, verse: 5 });
});

test('слияние не зависит от порядка и идемпотентно', () => {
  const a = newProgress(), b = newProgress();
  markRead(a, MATT, 1, 10); setPosition(a, MATT, 4, 2, 70); toggleRead(a, MATT, 1, 80);
  markRead(b, MATT, 1, 30); markRead(b, MATT, 5, 30); setPosition(b, MATT, 6, null, 70); // то же время правки
  setPosition(b, MARK, 2, null, 5);
  assert.strictEqual(encode(merged(a, b)), encode(merged(b, a)));
  assert.strictEqual(encode(merged(a, a)), encode(a));
  const ab = merged(a, b);
  assert.strictEqual(encode(merged(ab, b)), encode(ab));
});

test('снятая отметка не оживает при слиянии, а позднее чтение — оживляет', () => {
  const a = newProgress(); markRead(a, MATT, 3, 10);
  const b = merged(newProgress(), a);            // второе устройство получило главу
  toggleRead(a, MATT, 3, 20);                    // на первом сняли отметку
  const m1 = merged(a, b);
  assert.strictEqual(isReadOn(m1, MATT, 3), false, 'снятая не вернулась из старой копии');
  const c = merged(newProgress(), m1);
  markRead(c, MATT, 3, 30);                      // на третьем снова прочитали позже
  assert.strictEqual(isReadOn(merged(m1, c), MATT, 3), true);
  // старый формат (время 0) не оживляет снятую главу
  const legacy = fromLegacyReadSets({ '40': [3] });
  assert.strictEqual(isReadOn(merged(m1, legacy), MATT, 3), false);
});
function isReadOn(p, b, ch) { return readChapters(p, b).has(ch); }

test('toggle: снять и вернуть', () => {
  const p = newProgress(); markRead(p, MATT, 1, 1);
  toggleRead(p, MATT, 1, 2); assert.strictEqual(isReadOn(p, MATT, 1), false);
  toggleRead(p, MATT, 1, 3); assert.strictEqual(isReadOn(p, MATT, 1), true);
  assert.strictEqual(p.books.get(MATT).cleared.has(1), false);
});

test('JSON: круг туда и обратно, стабильный порядок, мусор отбрасывается', () => {
  const d = phoneDefaults(); const p = loadOrMigrate(d);
  const text = encode(p);
  assert.strictEqual(encode(decode(text)), text);
  const dirty = decode('{"schema":2,"books":{"40":{"read":{"1":0,"x":5,"-2":1},"position":{"chapter":0}},"abc":{"read":{"1":1}}},"lastBookId":"z"}');
  assert.deepStrictEqual([...readChapters(dirty, MATT)], [1]);
  assert.strictEqual(dirty.books.get(MATT).position, null);
  assert.strictEqual(dirty.books.size, 1);
  assert.strictEqual(dirty.lastBookId, null);
  assert.strictEqual(decode('[]'), null);
  assert.strictEqual(decode('не json'), null);
});

test('старый облачный набор читается как отметки без времени', () => {
  const legacy = fromLegacyReadSets({ '40': [1, 2, 3], '41': [1], 'junk': [1], '42': [0, -1] });
  assert.deepStrictEqual([...readChapters(legacy, MATT)].sort(), [1, 2, 3]);
  assert.strictEqual(legacy.books.size, 2);
  assert.deepStrictEqual(legacyReadSets(merged(legacy, newProgress())), { '40': [1, 2, 3], '41': [1] });
});

test('зеркало старых ключей: прежние версии видят главу, стих и прочитанные', () => {
  const d = {};
  const p = newProgress();
  markRead(p, MATT, 7, 1); setPosition(p, MATT, 7, 12, 2);
  save(p, d);
  assert.strictEqual(d[K.chPrefix + MATT], 7);
  assert.strictEqual(d[K.vPrefix + MATT], 12);
  assert.strictEqual(d[K.lastBook], MATT);
  assert.strictEqual(d[K.lastChapter], 7);
  assert.deepStrictEqual(d[K.legacyRead], { '40': [7] });
  setPosition(p, MATT, 7, null, 3); save(p, d);
  assert.strictEqual(d[K.vPrefix + MATT], undefined);
});

test('последняя книга: берётся самая свежая', () => {
  const p = newProgress();
  setPosition(p, MATT, 7, null, 10); setPosition(p, JOHN, 3, null, 20);
  assert.deepStrictEqual(lastLocation(p), { bookId: JOHN, chapter: 3, verse: null });
  const q = newProgress(); setPosition(q, MATT, 9, null, 30);
  assert.strictEqual(merged(p, q).lastBookId, MATT);
});

console.log(`\nПроверок пройдено: ${passed}${process.exitCode ? ' (ЕСТЬ ПАДЕНИЯ)' : ''}`);

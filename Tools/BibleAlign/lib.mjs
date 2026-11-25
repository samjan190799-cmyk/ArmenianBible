// Общие функции для Tools/BibleAlign: чтение базы, заглушки, сходство текстов, сканеры сдвигов.
// Нужен Node 22 или новее (встроенный node:sqlite).
import { DatabaseSync } from 'node:sqlite';

export const COLS = ['hy', 'hya', 'ru', 'en'];
// имена колонок в таблице verses: эчмиадзинский, Нор Арарат, русский, английский
export const COLUMN = { hy: 'text_hy', hya: 'text_hy_ararat', ru: 'text_ru', en: 'text_en' };
// так в базе помечен второй стих, когда синодальный текст слит с предыдущим
export const PLACEHOLDER_RU = '(см. предыдущий стих)';

export const openDb = (path, readOnly = true) => new DatabaseSync(path, { readOnly });
export const rowKey = (r) => `${r.c}:${r.v}`;

/** Все стихи базы по порядку книга, глава, стих. text_hy_ararat может быть пустым. */
export function loadRows(db) {
  return db.prepare("SELECT id, book_id AS b, chapter AS c, verse AS v, text_hy AS hy, COALESCE(text_hy_ararat, '') AS hya, text_ru AS ru, text_en AS en FROM verses ORDER BY book_id, chapter, verse").all()
    .map((r) => ({ ...r }));
}
export const bookNames = (db) => Object.fromEntries(db.prepare('SELECT id, name_en FROM books').all().map((b) => [b.id, b.name_en]));

// ---------- заглушки (чужой язык в колонке, пусто, «см. предыдущий стих», «...») ----------
const count = (t, re) => (t.match(re) || []).length;
export function isFiller(col, text) {
  const t = String(text ?? '').trim();
  if (!t || t === '...') return true;
  if (col === 'ru') return t === PLACEHOLDER_RU;
  const letters = t.replace(/[^\p{L}]/gu, '').length;
  if (col === 'hy' || col === 'hya') return count(t, /[Ա-֏]/g) < 0.5 * letters;
  if (col === 'en') return count(t, /[A-Za-z]/g) < 0.5 * letters;
  return false;
}
/** Строка на чужом языке или пустая (не считая «см. предыдущий стих» в русском и «...» в Нор Арарат) */
export function foreignKind(col, text) {
  const t = String(text ?? '').trim();
  if (!t) return 'пусто';
  if (col === 'ru') return count(t, /[Ѐ-ӿ]/g) < 0.5 * t.replace(/[^\p{L}]/gu, '').length ? 'не по-русски' : null;
  if (t === '...') return null;
  const letters = t.replace(/[^\p{L}]/gu, '').length;
  if (col === 'hy' || col === 'hya') return count(t, /[Ա-֏]/g) < 0.5 * letters ? 'не по-армянски' : null;
  if (col === 'en') return count(t, /[A-Za-z]/g) < 0.5 * letters ? 'не по-английски' : null;
  return null;
}

// ---------- армянский: сходство двух переводов ----------
// Эчмиадзинский пишет классической орфографией, Нор Арарат современной: сглаживаем самые частые различия
export const normHy = (s) => String(s || '').toLowerCase()
  .replace(/\[[^\]]*\]/g, (m) => m.slice(1, -1))
  .replace(/եւ/g, 'և').replace(/օ/g, 'ո').replace(/յ/g, 'հ')
  .replace(/[^ա-և ]/g, ' ').replace(/\s+/g, ' ').trim();
export const grams = (s, n = 3) => {
  const t = ' ' + normHy(s) + ' '; const m = new Map();
  for (let i = 0; i + n <= t.length; i++) { const g = t.slice(i, i + n); m.set(g, (m.get(g) || 0) + 1); }
  return m;
};
export const mergeGrams = (list) => { const m = new Map(); for (const g of list) for (const [k, v] of g) m.set(k, (m.get(k) || 0) + v); return m; };
export const dice = (a, b) => {
  if (!a.size || !b.size) return 0; let inter = 0, ta = 0, tb = 0;
  for (const v of a.values()) ta += v; for (const v of b.values()) tb += v;
  for (const [g, v] of a) { const w = b.get(g); if (w) inter += Math.min(v, w); }
  return 2 * inter / (ta + tb);
};

// ---------- межъязыковое сходство: словарь «основа слова ↔ основа английского слова» учится на самой базе ----------
// Почти везде номера стихов в четырёх колонках совпадают, поэтому связи слов получаются верными; редкие сдвиги шумом не мешают.
const stripEn = (s) => String(s || '').replace(/\{[^}]*:[^}]*\}/g, ' ').replace(/[{}\[\]]/g, ' ');
const TOK = {
  en: (s) => (stripEn(s).toLowerCase().match(/[a-z]+/g) || []).filter((w) => w.length >= 3),
  ru: (s) => (String(s || '').replace(/\[[^\]]*\]/g, ' ').replace(PLACEHOLDER_RU, ' ').toLowerCase().replace(/ё/g, 'е').match(/[а-я]+/g) || []).filter((w) => w.length >= 3),
  hy: (s) => (normHy(String(s || '').replace(/\(\d+:\d+\)/g, ' ')).match(/[ա-և]+/g) || []).filter((w) => w.length >= 3),
};
TOK.hya = TOK.hy;
const STEM = { en: 5, ru: 5, hy: 4, hya: 4 };
const stemsOf = (col, s) => [...new Set(TOK[col](s).map((w) => w.slice(0, STEM[col])))];

export function learnModel(rows, col) {
  const N = rows.length, dfA = new Map(), dfB = new Map(), co = new Map();
  const SA = rows.map((r) => stemsOf(col, r[col])), SB = rows.map((r) => stemsOf('en', r.en));
  for (let i = 0; i < N; i++) { for (const a of SA[i]) dfA.set(a, (dfA.get(a) || 0) + 1); for (const b of SB[i]) dfB.set(b, (dfB.get(b) || 0) + 1); }
  const maxDf = 0.06 * N, minDf = 3;
  const okA = (a) => { const d = dfA.get(a); return d >= minDf && d <= maxDf; }, okB = (b) => { const d = dfB.get(b); return d >= minDf && d <= maxDf; };
  for (let i = 0; i < N; i++) { const a = SA[i].filter(okA), b = SB[i].filter(okB); for (const x of a) for (const y of b) { const k = x + '|' + y; co.set(k, (co.get(k) || 0) + 1); } }
  const assoc = new Map();
  for (const [k, n] of co) {
    if (n < 3) continue; const [a, b] = k.split('|'); const da = dfA.get(a), db = dfB.get(b);
    const d = 2 * n / (da + db), lift = (n * N) / (da * db);
    if (d < 0.25 || lift < 5) continue;
    if (!assoc.has(a)) assoc.set(a, []); assoc.get(a).push([b, Math.log(lift) * d]);
  }
  return { col, assoc, SA, SB, stemsOf: (s) => stemsOf(col, s) };
}
/** Насколько стих i колонки похож на английский стих j (по тем же номерам строк в массиве rows) */
export function xScore(model, i, j) {
  const set = new Set(model.SB[j]); let s = 0;
  for (const a of model.SA[i]) { const list = model.assoc.get(a); if (!list) continue; let best = 0; for (const [b, w] of list) if (set.has(b) && w > best) best = w; s += best; }
  return s / Math.sqrt((model.SA[i].length + 1) * (model.SB[j].length + 1));
}
/** То же для произвольного текста колонки и английского стиха j */
export function xScoreText(model, text, j) {
  const set = new Set(model.SB[j]); const A = model.stemsOf(text); let s = 0;
  for (const a of A) { const list = model.assoc.get(a); if (!list) continue; let best = 0; for (const [b, w] of list) if (set.has(b) && w > best) best = w; s += best; }
  return s / Math.sqrt((A.length + 1) * (model.SB[j].length + 1));
}

// ---------- поиск участков со сдвигом ----------
const SHIFTS = [-3, -2, -1, 0, 1, 2, 3];
function viterbi(n, gain, lambda, prior0) {
  const K = SHIFTS.length; let prev = SHIFTS.map((s) => (s === 0 ? prior0 : 0)); const back = [];
  for (let k = 0; k < n; k++) {
    const cur = new Array(K), bk = new Array(K);
    for (let si = 0; si < K; si++) {
      let best = -1e9, bj = si;
      for (let sj = 0; sj < K; sj++) { const v = prev[sj] - (si === sj ? 0 : lambda); if (v > best) { best = v; bj = sj; } }
      cur[si] = best + gain(k, SHIFTS[si]) + (SHIFTS[si] === 0 ? prior0 : 0); bk[si] = bj;
    }
    back.push(bk); prev = cur;
  }
  let si = prev.indexOf(Math.max(...prev)); const path = new Array(n);
  for (let k = n - 1; k >= 0; k--) { path[k] = SHIFTS[si]; si = back[k][si]; }
  return path;
}
function stretches(path, sc, rowsOfBook, minLen, minGain) {
  const out = []; let k = 0;
  while (k < path.length) {
    if (path[k] === 0) { k++; continue; }
    let e = k; while (e + 1 < path.length && path[e + 1] === path[k]) e++;
    let g = 0; for (let q = k; q <= e; q++) g += sc(q, path[k]) - sc(q, 0);
    if (e - k + 1 >= minLen && g >= minGain) out.push({ shift: path[k], from: rowsOfBook[k], to: rowsOfBook[e], n: e - k + 1, gain: g });
    k = e + 1;
  }
  return out;
}
function byBook(rows) { const m = new Map(); rows.forEach((r, i) => { if (!m.has(r.b)) m.set(r.b, []); m.get(r.b).push(i); }); return m; }

/** Колонка col (hy, hya, ru) против английского: участки, где стих лежит на чужом номере. */
export function scanAgainstEnglish(rows, col) {
  const model = learnModel(rows, col), found = [];
  for (const [b, idxs] of byBook(rows)) {
    const n = idxs.length, cache = new Map();
    const sc = (k, s) => { const j = k - s; if (j < 0 || j >= n) return 0; const key = k * 16 + s + 3; let v = cache.get(key); if (v === undefined) { v = xScore(model, idxs[k], idxs[j]); cache.set(key, v); } return v; };
    const path = viterbi(n, sc, 0.45, 0.06);
    for (const f of stretches(path, sc, idxs.map((i) => rows[i]), 2, 0.5)) found.push({ col, b, ...f });
  }
  return found;
}
/** Два армянских перевода друг против друга по сходству слов. Нор Арарат пустой или «...»: такие стихи не сравниваются. */
export function scanHyVsHya(rows) {
  const G = rows.map((r) => ({ hy: grams(r.hy), hya: r.hya && r.hya !== '...' ? grams(r.hya) : new Map() })); const found = [];
  for (const [b, idxs] of byBook(rows)) {
    const n = idxs.length, cache = new Map();
    const sc = (k, s) => { const j = k - s; if (j < 0 || j >= n) return 0; const key = k * 16 + s + 3; let v = cache.get(key); if (v === undefined) { v = dice(G[idxs[k]].hy, G[idxs[j]].hya); cache.set(key, v); } return v; };
    const path = viterbi(n, sc, 1.2, 0.1);
    for (const f of stretches(path, sc, idxs.map((i) => rows[i]), 3, 1.0)) found.push({ col: 'hy~hya', b, ...f });
  }
  return found;
}
export const describeStretch = (names, f) => `${f.col}: ${names[f.b]} ${f.from.c}:${f.from.v}–${f.to.c}:${f.to.v}, сдвиг ${f.shift}, ${f.n} стих., выигрыш ${f.gain.toFixed(1)}`;

/** Все ячейки на чужом языке или пустые */
export function listForeign(rows) {
  const out = [];
  for (const r of rows) for (const col of COLS) { const kind = foreignKind(col, r[col]); if (kind) out.push({ b: r.b, c: r.c, v: r.v, col, kind, text: String(r[col]).slice(0, 60) }); }
  return out;
}

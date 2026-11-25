#!/usr/bin/env node
// Выравнивание нумерации стихов в Sources/bible.db по английской (таблица правок в spec.mjs).
//   node Tools/BibleAlign/align.mjs apply  <исходная.db> <новая.db> [--review список.md] [--force]
//   node Tools/BibleAlign/align.mjs report <исходная.db>            (то же во временный файл, печатает итоги и список для носителя армянского)
//   node Tools/BibleAlign/align.mjs check  <база.db>                (чужой язык в колонках и участки со сдвигом; код выхода 1, если есть)
// Исходный файл никогда не меняется: результат пишется в новый файл. Нужен Node 22 или новее.
import { createHash } from 'node:crypto';
import { copyFileSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { COLUMN, bookNames, dice, describeStretch, grams, isFiller, listForeign, loadRows, mergeGrams, openDb, rowKey, scanAgainstEnglish, scanHyVsHya } from './lib.mjs';
import { DELETE_ROWS, EXPECTED_EMPTY_HYA, FIXES, KNOWN_EDGE, ORIGINAL_SHA256 } from './spec.mjs';

const sha256 = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');
const sig = (s) => String(s).toLowerCase().replace(/[^\p{L}]/gu, '');
const isArm = (col) => col === 'hy' || col === 'hya';
const upperFirst = (s) => (s ? s[0].toUpperCase() + s.slice(1) : s);
const lowerFirst = (s) => (s ? s[0].toLowerCase() + s.slice(1) : s);
const short = (s, n = 34) => { s = String(s).replace(/\s+/g, ' ').trim(); return s.length > 2 * n + 3 ? `${s.slice(0, n)}…${s.slice(-n)}` : s; };

// ---------- склейка и разрез с учётом знаков препинания армянского текста ----------
// Эчмиадзинский внутри стиха ставит «.», в конце стиха «։»; Нор Арарат везде «։». Слова не меняются.
function joinMerge(col, left, right) {
  left = left.trim(); right = right.trim();
  if (isArm(col)) {
    if (/[,՝;:]$/.test(left)) right = lowerFirst(right);
    else if (col === 'hy' && /։$/.test(left)) left = left.slice(0, -1) + '.';
  }
  return `${left} ${right}`;
}
function closeLeft(col, text) { // конец первой части после разреза
  text = text.trim();
  if (!isArm(col)) return text;
  text = text.replace(/[,.;:՝]\s*$/, '։');
  return /[։?!»]\s*$/.test(text) ? text : text + '։';
}
const openRight = (col, text) => (isArm(col) ? upperFirst(text.trim()) : text.trim()); // начало второй части

// ---------- нарезка текста на предложения и части предложений ----------
function segmentUnit(text) {
  const segs = []; let depth = 0, start = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '[' || ch === '«' || ch === '(') depth++;
    else if (ch === ']' || ch === '»' || ch === ')') depth = Math.max(0, depth - 1);
    else if (depth === 0 && /[։.;:,՝]/.test(ch) && /\s/.test(text[i + 1] || '')) {
      segs.push({ text: text.slice(start, i + 1).trim(), weak: !/[։.]/.test(ch) }); start = i + 1;
    }
  }
  const tail = text.slice(start).trim(); if (tail) segs.push({ text: tail, weak: false });
  return segs.length ? segs : [{ text: text.trim(), weak: false }];
}

// ---------- раскладка текстов по строкам по сходству с колонкой-образцом ----------
const PEN_STRONG = 0.06, PEN_WEAK = 0.12, PEN_MERGE = 0.04, NO_ANCHOR = 0.65, MAXLEN = 8, UNIT_BAND = 8;
function partition(col, units, anchors) {
  const segs = [];
  units.forEach((u, ui) => { const ss = segmentUnit(u.text); ss.forEach((s, k) => segs.push({ text: s.text, weak: s.weak, ui, last: k === ss.length - 1 })); });
  const m = segs.length, n = anchors.length, U = units.length;
  if (m < n) throw new Error(`частей текста ${m}, а строк ${n}`);
  const cumBefore = new Array(U + 1).fill(0); segs.forEach((s) => { cumBefore[s.ui + 1]++; }); for (let i = 1; i <= U; i++) cumBefore[i] += cumBefore[i - 1];
  const unitFirst = new Array(U).fill(-1), unitLast = new Array(U).fill(-1);
  segs.forEach((s, t) => { if (unitFirst[s.ui] < 0) unitFirst[s.ui] = t; unitLast[s.ui] = t; });
  const SG = segs.map((s) => grams(s.text)), AG = anchors.map((a) => (a && a !== '...' ? grams(a) : null));
  const cache = new Map();
  const cost = (j, a, b) => {
    const k = (j * 20011 + a) * 20011 + b; let hit = cache.get(k); if (hit !== undefined) return hit;
    const g = AG[j] ? mergeGrams(SG.slice(a, b + 1)) : null;
    let sim = AG[j] ? dice(g, AG[j]) : 1 - NO_ANCHOR, c = 1 - sim;
    if (b < m - 1 && !segs[b].last) c += segs[b].weak ? PEN_WEAK : PEN_STRONG;
    for (let t = a; t < b; t++) if (segs[t].last) c += PEN_MERGE;
    hit = { c, sim }; cache.set(k, hit); return hit;
  };
  const INF = 1e9, f = Array.from({ length: n + 1 }, () => new Float64Array(m + 1).fill(INF)), back = Array.from({ length: n + 1 }, () => new Int32Array(m + 1).fill(-1));
  f[0][0] = 0;
  for (let j = 1; j <= n; j++) {
    const e = Math.min(U, j - 1), lo = Math.max(j, cumBefore[Math.max(0, e - UNIT_BAND)]), hi = Math.min(m - (n - j), cumBefore[Math.min(U, e + UNIT_BAND + 1)]);
    for (let b = lo; b <= hi; b++) for (let len = 1; len <= MAXLEN && b - len >= 0; len++) {
      const a = b - len, prev = f[j - 1][a]; if (prev >= INF) continue;
      const c = prev + cost(j - 1, a, b - 1).c; if (c < f[j][b]) { f[j][b] = c; back[j][b] = a; }
    }
  }
  if (f[n][m] >= INF) throw new Error('раскладка не нашлась');
  const cuts = []; for (let j = n, b = m; j >= 1; j--) { const a = back[j][b]; cuts.unshift([a, b - 1]); b = a; }
  const texts = [], notes = [], warnings = [];
  cuts.forEach(([a, b], j) => {
    let out = segs[a].text;
    for (let t = a + 1; t <= b; t++) out = segs[t - 1].last ? joinMerge(col, out, segs[t].text) : `${out} ${segs[t].text}`;
    const startsMid = a > 0 && !segs[a - 1].last, endsMid = b < m - 1 && !segs[b].last;
    if (startsMid) out = openRight(col, out);
    if (endsMid) out = closeLeft(col, out);
    texts.push(out);
    const sim = cost(j, a, b).sim;
    // из каких стихов собрана строка: целиком, начало, конец или середина стиха
    const parts = []; for (let t = a; t <= b; t++) { const ui = segs[t].ui; if (!parts.length || parts[parts.length - 1].ui !== ui) parts.push({ ui, from: t, to: t }); else parts[parts.length - 1].to = t; }
    const part = (p) => { const whole = p.from === unitFirst[p.ui] && p.to === unitLast[p.ui]; const label = units[p.ui].label; return whole ? label : p.from === unitFirst[p.ui] ? `${label} (начало)` : p.to === unitLast[p.ui] ? `${label} (конец)` : `${label} (середина)`; };
    if (parts.length > 1 || startsMid || endsMid) notes.push({ j, how: 'из ' + parts.map(part).join(' + '), text: out });
    if (anchors[j] && anchors[j] !== '...' && sim < 0.25) warnings.push(`строка №${j + 1}: сходство с образцом только ${sim.toFixed(2)}`);
  });
  if (sig(units.map((u) => u.text).join('')) !== sig(texts.join(''))) throw new Error('при раскладке изменились слова');
  return { texts, notes, warnings };
}

// ---------- применение одной записи spec ----------
function expandRange(bookRows, [from, to]) {
  const i = bookRows.findIndex((r) => rowKey(r) === from), j = bookRows.findIndex((r) => rowKey(r) === to);
  if (i < 0 || j < 0 || j < i) throw new Error(`нет участка ${from}..${to}`);
  return bookRows.slice(i, j + 1);
}
function applyFix(db, fix, ctx) {
  const bookRows = ctx.rows.filter((r) => r.b === fix.book), col = fix.col, colName = COLUMN[col];
  const srcRows = fix.slices.flatMap((s) => expandRange(bookRows, s));
  const tgtRows = fix.targets ? fix.targets.flatMap((s) => expandRange(bookRows, s)) : srcRows;
  let units = srcRows.map((r) => ({ label: rowKey(r), text: String(r[col] ?? '') }));
  const idx = (label) => { const i = units.findIndex((u) => u.label === label); if (i < 0) throw new Error(`${fix.id}: нет стиха ${label}`); return i; };
  const notes = [];
  for (const op of fix.ops || []) {
    if (op.drop !== undefined) {
      const i = idx(op.drop); if (!isFiller(col, units[i].text)) throw new Error(`${fix.id}: ${op.drop} не заглушка: «${units[i].text.slice(0, 50)}»`);
      units.splice(i, 1);
    } else if (op.merge) {
      const a = idx(op.merge[0]), b = idx(op.merge[1]); if (b !== a + 1) throw new Error(`${fix.id}: ${op.merge} не соседние`);
      const text = joinMerge(col, units[a].text, units[b].text);
      notes.push({ row: units[a].label, how: `склейка ${op.merge[0]} + ${op.merge[1]}`, text }); units.splice(a, 2, { label: units[a].label, text });
    } else if (op.split !== undefined) {
      const i = idx(op.split), t = units[i].text, at = t.indexOf(op.at);
      if (at < 0 || t.indexOf(op.at, at + 1) >= 0) throw new Error(`${fix.id}: метка «${op.at}» в ${op.split} должна встречаться ровно один раз`);
      const left = closeLeft(col, t.slice(0, at)), right = openRight(col, t.slice(at));
      notes.push({ row: op.split, how: `разрез ${op.split}`, text: `${short(left)} | ${short(right)}` });
      units.splice(i, 1, { label: units[i].label, text: left }, { label: units[i].label + '+', text: right });
    } else if (op.insertBefore !== undefined || op.insertAfter !== undefined) {
      const at = op.insertBefore !== undefined ? idx(op.insertBefore) : idx(op.insertAfter) + 1;
      units.splice(at, 0, { label: (op.insertBefore ?? op.insertAfter) + '*', text: op.text });
    } else if (op.moveToEnd) {
      for (const l of op.moveToEnd) { const i = idx(l); units.push(units.splice(i, 1)[0]); }
    } else if (op.appendEmpty) {
      for (let k = 0; k < op.appendEmpty; k++) units.push({ label: 'пусто', text: '' });
    } else throw new Error(`${fix.id}: неизвестная операция ${JSON.stringify(op)}`);
  }
  let warnings = [];
  if (fix.partition) {
    const anchors = tgtRows.map((r) => String(r[fix.partition.anchor] ?? ''));
    const res = partition(col, units, anchors);
    units = res.texts.map((text, j) => ({ label: rowKey(tgtRows[j]), text })); warnings = res.warnings;
    for (const n of res.notes) notes.push({ row: rowKey(tgtRows[n.j]), how: n.how, text: n.text });
  }
  if (units.length !== tgtRows.length) throw new Error(`${fix.id}: кусков текста ${units.length}, а строк ${tgtRows.length}`);
  const upd = db.prepare(`UPDATE verses SET ${colName} = ? WHERE id = ?`);
  let changed = 0;
  tgtRows.forEach((r, i) => { const t = units[i].text; if (String(r[col] ?? '') !== t) { upd.run(t, r.id); changed++; } });
  return { fix, rows: tgtRows.length, changed, notes, warnings };
}

// ---------- проверка ----------
function check(dbPath, log = console.log) {
  const db = openDb(dbPath); const rows = loadRows(db), names = bookNames(db), problems = [];
  const expected = new Set(EXPECTED_EMPTY_HYA.map(([b, ref]) => `${b}:${ref}`));
  for (const f of listForeign(rows)) {
    if (f.col === 'hya' && f.kind === 'пусто' && expected.has(`${f.b}:${f.c}:${f.v}`)) continue;
    problems.push(`${f.kind} в колонке ${f.col}: ${names[f.b]} ${f.c}:${f.v} «${f.text}»`);
  }
  const known = new Set(KNOWN_EDGE);
  const found = [...scanAgainstEnglish(rows, 'ru'), ...scanAgainstEnglish(rows, 'hy'), ...scanAgainstEnglish(rows, 'hya'), ...scanHyVsHya(rows)];
  for (const s of found) { if (known.has(`${s.col}|${s.b}|${s.from.c}:${s.from.v}`)) continue; problems.push('сдвиг: ' + describeStretch(names, s) + `  [ключ ${s.col}|${s.b}|${s.from.c}:${s.from.v}]`); }
  log(`строк в базе: ${rows.length}; найдено проблем: ${problems.length}`); for (const p of problems) log('  ' + p);
  db.close(); return problems;
}

// ---------- запуск ----------
function apply(src, out, { force, reviewPath } = {}) {
  if (path.resolve(src) === path.resolve(out)) throw new Error('новая база не может совпадать с исходной');
  const hash = sha256(src);
  if (hash !== ORIGINAL_SHA256 && !force) throw new Error(`исходная база не та, что ждёт таблица правок (sha256 ${hash}); правки уже применены или база другая. Для проверки на другой базе добавьте --force`);
  copyFileSync(src, out);
  const db = openDb(out, false); const rows = loadRows(db), names = bookNames(db);
  const ctx = { rows }, results = [];
  db.exec('BEGIN');
  try {
    for (const fix of FIXES) { const r = applyFix(db, fix, ctx); results.push(r); console.log(`  ${fix.id}: строк ${r.rows}, изменено ${r.changed}${r.warnings.length ? ' ПРЕДУПРЕЖДЕНИЯ: ' + r.warnings.join('; ') : ''}`); }
    const del = db.prepare('DELETE FROM verses WHERE id = ?');
    for (const d of DELETE_ROWS) { const r = rows.find((x) => x.b === d.book && rowKey(x) === d.row); if (!r) throw new Error(`нет строки ${d.row} книги ${d.book}`); del.run(r.id); console.log(`  удалена строка ${names[d.book]} ${d.row}: ${d.why}`); }
    db.exec('COMMIT');
  } catch (e) { db.exec('ROLLBACK'); db.close(); throw e; }
  db.exec("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')");
  db.exec("INSERT INTO verses_fts(verses_fts) VALUES('integrity-check')");
  db.exec('VACUUM');
  console.log('integrity_check:', JSON.stringify(db.prepare('PRAGMA integrity_check').get()));
  const totalChanged = results.reduce((s, r) => s + r.changed, 0);
  console.log(`итого записей правок: ${results.length}, изменено ячеек: ${totalChanged}, удалено строк: ${DELETE_ROWS.length}, строк в базе: ${db.prepare('SELECT COUNT(*) n FROM verses').get().n}`);
  db.close();
  const md = reviewMarkdown(results, names);
  if (reviewPath) { writeFileSync(reviewPath, md); console.log('список для проверки записан в', reviewPath); }
  return { results, md };
}
function reviewMarkdown(results, names) {
  const lines = ['# Что нужно показать носителю армянского до выпуска', '',
    'Слова армянских текстов не менялись. Менялись только места склейки и разреза стихов, и в этих местах знаки препинания и регистр первой буквы:',
    'в конце первой части после разреза стоит «։», вторая часть начинается с заглавной; при склейке «։» в конце первой части становится «.» (эчмиадзинский) и вторая часть пишется со строчной после запятой.', ''];
  for (const r of results) {
    if (!r.fix.review) continue;
    lines.push(`## ${r.fix.title} [${r.fix.col === 'hy' ? 'эчмиадзинский' : 'Нор Арарат'}]`);
    if (!r.notes.length) lines.push('- без склеек и разрезов');
    for (const n of r.notes) lines.push(`- ${n.row ? `${n.row}: ` : ''}${n.how}: ${short(n.text, 60)}`);
    for (const w of r.warnings) lines.push(`- ВНИМАНИЕ: ${w}`);
    lines.push('');
  }
  return lines.join('\n');
}

const [cmd, a1, a2, ...rest] = process.argv.slice(2);
try {
  if (cmd === 'apply' && a1 && a2) {
    const ri = rest.indexOf('--review');
    apply(a1, a2, { force: rest.includes('--force'), reviewPath: ri >= 0 ? rest[ri + 1] : null });
    process.exit(check(a2).length ? 1 : 0);
  } else if (cmd === 'report' && a1) {
    const tmp = mkdtempSync(path.join(tmpdir(), 'bible-align-')), out = path.join(tmp, 'bible_fixed.db');
    try { const { md } = apply(a1, out, { force: rest.includes('--force') }); console.log('\n' + md); check(out); } finally { rmSync(tmp, { recursive: true, force: true }); }
  } else if (cmd === 'check' && a1) {
    process.exit(check(a1).length ? 1 : 0);
  } else {
    console.error('Использование:\n  node Tools/BibleAlign/align.mjs apply <исходная.db> <новая.db> [--review список.md] [--force]\n  node Tools/BibleAlign/align.mjs report <исходная.db>\n  node Tools/BibleAlign/align.mjs check <база.db>');
    process.exit(2);
  }
} catch (e) { console.error('ОШИБКА:', e.message); process.exit(1); }

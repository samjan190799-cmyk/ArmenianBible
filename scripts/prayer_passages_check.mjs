// Проверка таблицы отрывков для «молитв по часам» (Sources/PrayerPassages.swift) по базе Библии (Sources/bible.db), только чтение.
// Запуск из корня репозитория: node scripts/prayer_passages_check.mjs [путь к другой таблице для пробы]
// Что проверяется для каждого отрывка:
//   1) стихи есть во всех четырёх вариантах текста: эчмиадзинский, Нор Арарат, русский, английский;
//   2) нумерация главы не сдвинута: длины стихов армянского и русского текста повторяют длины английского
//      (настоящий сдвиг даёт резкий скачок корреляции при смещении на один стих; так выглядели Иоанна 8 и 10 в эчмиадзинском тексте);
//   3) каждая строка отрывка на своём языке: не пустая, не заглушка «см. предыдущий стих», не копия на чужом языке.
//      Так выглядел Мк 4:41: в английской колонке нет стиха 4:40, всё после него лежит на номер ниже,
//      а последнюю строку главы база забила русским текстом (и в английском, и в эчмиадзинском);
//   4) два армянских текста на одном номере стиха говорят об одном и том же: стих похож на свою пару больше, чем на соседние;
//   5) в главе отрывка нет строк на чужом языке или пустых: это признак сдвига, который мог начаться в середине главы,
//      а проверка 2 такой сдвиг не видит. Если отрывок заведомо стоит раньше начала сдвига, его записывают в SAFE_BEFORE_SHIFT;
//   6) нет повторов, номера в допустимых пределах, у каждого часа не меньше 20 наборов.
// Служебные пометки в фигурных и квадратных скобках проверка не считает ошибкой: их убирает PrayerPassageText.clean.
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const db = new DatabaseSync(new URL('Sources/bible.db', root), { readOnly: true });
const source = readFileSync(process.argv[2] || new URL('Sources/PrayerPassages.swift', root), 'utf8');

// Главы, где в базе есть строки на чужом языке, но отрывок стоит раньше начала сдвига (проверено глазами 25.11.2026).
// Ключ «книга:глава»; before — первый стих сдвинутого участка: отрывки, которые кончаются раньше него, допустимы.
const SAFE_BEFORE_SHIFT = new Map([
  ['50:4', { before: 21, why: 'Флп 4: сдвиг начинается с 4:21 (в эчмиадзинском 4:21 разрезан на два), лишняя строка 4:24' }],
]);

// Таблица читается как JSON: убираем комментарии «//» и запятую перед закрывающей скобкой
const table = {};
for (const m of source.matchAll(/static let (\w+): \[\[\[Int\]\]\] = \[([\s\S]*?)\n    \]/g)) {
  table[m[1]] = JSON.parse(('[' + m[2].replace(/\/\/.*$/gm, '') + ']').replace(/,\s*\]/g, ']'));
}
const hours = ['morning', 'noon', 'evening', 'night'];
let errors = 0;
const fail = (message) => { errors++; console.log('ОШИБКА: ' + message); };

const names = Object.fromEntries(db.prepare('SELECT id, name_en FROM books').all().map((b) => [b.id, b.name_en]));
const chapterStmt = db.prepare("SELECT verse, text_hy AS hy, COALESCE(text_hy_ararat, '') AS hya, text_ru AS ru, text_en AS en FROM verses WHERE book_id = ? AND chapter = ? ORDER BY verse");
const cache = new Map();
const chapter = (b, c) => { const k = b + ':' + c; if (!cache.has(k)) cache.set(k, chapterStmt.all(b, c)); return cache.get(k); };
const strip = (s) => String(s || '').replace(/\{[^}]*\}/g, '').replace(/\[[^\]]*\]/g, '').trim();
const len = (s) => [...String(s || '')].length;
const COLUMNS = [['hy', 'эчмиадзинский'], ['hya', 'Нор Арарат'], ['ru', 'русский'], ['en', 'английский']];

// --- Что не так со строкой стиха: пусто, заглушка, ссылка в начале или чужой язык
const PLACEHOLDER = /^\s*\(?\s*(см\.|смотр|пропущ)/i;
function problemOf(col, text) {
  const t = String(text || '');
  const body = col === 'ru' || col === 'en' ? strip(t) : t.trim();
  if (!body) return { kind: 'empty', message: 'нет текста' };
  const letters = t.replace(/[^\p{L}]/gu, '').length;
  const count = (re) => (t.match(re) || []).length;
  const own = { armenian: count(/[Ա-֏]/g), russian: count(/[Ѐ-ӿ]/g), english: count(/[A-Za-z]/g) };
  const mine = col === 'hy' || col === 'hya' ? 'armenian' : col === 'ru' ? 'russian' : 'english';
  if (own[mine] < 0.5 * letters) {
    const [foreign] = Object.entries(own).filter(([k]) => k !== mine).sort((a, b) => b[1] - a[1])[0];
    return { kind: 'foreign', message: `текст на чужом языке (${foreign})` };
  }
  if (PLACEHOLDER.test(t) && len(t) < 40) return { kind: 'placeholder', message: 'вместо текста заглушка' };
  if (/^\(\d+:\d+\)/.test(t.trim())) return { kind: 'xref', message: 'в начале стиха ссылка в скобках' };
  return null;
}

// --- Сходство двух армянских текстов (триграммы букв, упрощённая орфография)
const normHy = (s) => String(s || '').toLowerCase().replace(/\[[^\]]*\]/g, (m) => m.slice(1, -1))
  .replace(/եւ/g, 'և').replace(/օ/g, 'ո').replace(/յ/g, 'հ').replace(/[^ա-և ]/g, ' ').replace(/\s+/g, ' ').trim();
const grams = (s) => { const t = ' ' + normHy(s) + ' '; const m = new Map(); for (let i = 0; i + 3 <= t.length; i++) { const g = t.slice(i, i + 3); m.set(g, (m.get(g) || 0) + 1); } return m; };
const dice = (a, b) => {
  if (!a.size || !b.size) return 0;
  let inter = 0, ta = 0, tb = 0;
  for (const v of a.values()) ta += v;
  for (const v of b.values()) tb += v;
  for (const [g, v] of a) { const w = b.get(g); if (w) inter += Math.min(v, w); }
  return 2 * inter / (ta + tb);
};

// --- Сдвиг всей главы: длины стихов против английского
const corr = (a, b) => {
  const n = Math.min(a.length, b.length); if (n < 6) return null;
  const x = a.slice(0, n), y = b.slice(0, n), mx = x.reduce((s, v) => s + v, 0) / n, my = y.reduce((s, v) => s + v, 0) / n;
  let sxy = 0, sxx = 0, syy = 0;
  for (let i = 0; i < n; i++) { sxy += (x[i] - mx) * (y[i] - my); sxx += (x[i] - mx) ** 2; syy += (y[i] - my) ** 2; }
  return sxx && syy ? sxy / Math.sqrt(sxx * syy) : null;
};
// Лучший сдвиг не ноль, и он заметно лучше нуля
const shifted = (own, en) => {
  const c0 = corr(own, en); let best = { s: 0, c: c0 ?? -2 };
  for (let s = -2; s <= 2; s++) {
    const cc = corr(own.slice(Math.max(0, s)), en.slice(Math.max(0, -s)));
    if (cc !== null && cc > best.c) best = { s, c: cc };
  }
  return best.s !== 0 && best.c >= 0.75 && best.c - (c0 ?? -1) >= 0.3 ? best : null;
};

// Строки главы, которые выдают сдвиг: чужой язык или пустота (заглушки и ссылки в начале не считаем: они бывают законно)
const chapterAnomalies = (b, c) => {
  const found = [];
  for (const r of chapter(b, c)) for (const [col, label] of COLUMNS) {
    const p = problemOf(col, r[col]);
    if (p && (p.kind === 'foreign' || p.kind === 'empty')) found.push(`${c}:${r.verse} ${label}: ${p.message}`);
  }
  return found;
};

const seenChapters = new Set(), seenPassages = new Set();
let verses = 0;
for (const hour of hours) {
  const sets = table[hour] || [];
  if (sets.length < 20) fail(`у часа ${hour} только ${sets.length} наборов, нужно не меньше 20`);
  sets.forEach((set, i) => {
    const key = JSON.stringify(set);
    if (seenPassages.has(key)) fail(`${hour} №${i + 1}: повтор набора ${key}`);
    seenPassages.add(key);
    for (const [b, c, from, to] of set) {
      const where = `${hour} №${i + 1} ${names[b] || 'книга ' + b} ${c}:${from}${to > from ? '-' + to : ''}`;
      if (!names[b] || c < 1 || from < 1 || to < from) { fail(`${where}: неверные номера`); continue; }
      const rows = chapter(b, c);

      // 1, 3, 4: каждый стих отрывка
      for (let v = from; v <= to; v++) {
        const r = rows.find((x) => x.verse === v);
        if (!r) { fail(`${where}: нет стиха ${v}`); continue; }
        verses++;
        for (const [col, label] of COLUMNS) {
          const p = problemOf(col, r[col]);
          if (p) fail(`${where}:${v}: ${label}: ${p.message} «${String(r[col] || '').slice(0, 50)}»`);
        }
        if (len(r.hya) && len(r.hy)) {
          const own = grams(r.hy), same = dice(own, grams(r.hya));
          let best = { d: 0, s: -1 };
          for (const d of [-2, -1, 1, 2]) {
            const n = rows.find((x) => x.verse === v + d);
            if (n && len(n.hya)) { const s = dice(own, grams(n.hya)); if (s > best.s) best = { d, s }; }
          }
          if (same < 0.12 || best.s - same >= 0.12) {
            fail(`${where}:${v}: два армянских текста не совпадают по смыслу (сходство ${same.toFixed(2)}, у соседнего стиха ${best.d > 0 ? '+' : ''}${best.d} ${best.s.toFixed(2)}): нумерация сдвинута`);
          }
        }
      }

      // 5: в главе нет чужих и пустых строк
      const anomalies = chapterAnomalies(b, c);
      if (anomalies.length) {
        const safe = SAFE_BEFORE_SHIFT.get(b + ':' + c);
        if (!(safe && to < safe.before)) fail(`${where}: в главе есть строки на чужом языке или пустые (${anomalies.slice(0, 4).join('; ')}): отрывок мог попасть под сдвиг, замените его`);
      }

      // 2: сдвиг всей главы, один раз на главу
      const ck = b + ':' + c;
      if (!seenChapters.has(ck)) {
        seenChapters.add(ck);
        const en = rows.map((r) => len(strip(r.en)));
        for (const [label, pick] of [['эчмиадзинский', (r) => len(r.hy)], ['Нор Арарат', (r) => len(r.hya)], ['русский', (r) => len(strip(r.ru))]]) {
          const bad = shifted(rows.map(pick), en);
          if (bad) fail(`${names[b]} ${c}: у текста «${label}» нумерация сдвинута на ${bad.s} стих (корреляция ${bad.c.toFixed(2)})`);
        }
      }
    }
  });
}
const total = hours.reduce((s, h) => s + (table[h] || []).length, 0);
console.log(`наборов: ${total} (${hours.map((h) => `${h} ${(table[h] || []).length}`).join(', ')}); глав проверено: ${seenChapters.size}; стихов: ${verses}; ошибок: ${errors}`);
process.exit(errors ? 1 : 0);

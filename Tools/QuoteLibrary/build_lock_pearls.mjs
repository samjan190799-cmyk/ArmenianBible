// Собирает Sources/BibleVerseDatabase+LockPearls.swift: короткие законченные стихи из Sources/bible.db для экрана блокировки.
//
// Зачем: бесплатная подборка экрана блокировки состояла из 20 фраз, и они быстро повторялись. Здесь отбираются целые
// стихи, которые помещаются в три строки виджета на трёх языках и по смыслу самостоятельны (правила те же, что у
// «стиха дня»: Sources/VerseQuality.swift).
//
// Запуск (из корня репозитория, нужен Node 22+):
//   node Tools/QuoteLibrary/build_lock_pearls.mjs report   # показать, что получилось, ничего не записывая
//   node Tools/QuoteLibrary/build_lock_pearls.mjs write    # записать Sources/BibleVerseDatabase+LockPearls.swift
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const db = new DatabaseSync(path.join(ROOT, 'Sources', 'bible.db'), { readOnly: true });
const mode = process.argv[2] || 'report';

// ---- Правила самостоятельности стиха (порт Sources/VerseQuality.swift) ----
const TERMINALS = new Set(['.', '!', '?', '…', '»', '"', '”', ')']);
const LEAD_RU = ['говоря', 'сказал', 'сказали', 'сказала', 'сказав', 'скажи', 'глаголя', 'следующее'];
const LEAD_EN = ['saying', 'said', 'say', 'spake', 'answered', 'follows'];
const LEAD_HY = ['ասելով', 'ասաց', 'ասացին', 'ասէ', 'ասեց', 'խօսեց', 'խոսեց'];
const stripBraces = s => s.replace(/\{[^}]*\}/g, '').replace(/\s+/g, ' ').trim();
const words = s => s.split(/\s+/).filter(Boolean);
const bareEnd = s => s.replace(/[\s.,:;!?…»"”)(«—-]+$/u, '');
const lastWord = s => (words(bareEnd(s)).pop() || '').toLowerCase();
const isLower = ch => ch !== ch.toUpperCase() && ch === ch.toLowerCase();

function verdict(hy, ru, en) {
  const R = stripBraces(ru || ''), E = stripBraces(en || ''), H = stripBraces(hy || '');
  if (!R || !E || !H) return 'пусто';
  if (!TERMINALS.has(R.slice(-1))) return 'обрыв (ru)';
  if (!TERMINALS.has(E.slice(-1))) return 'обрыв (en)';
  if (isLower(R[0]) || isLower(E[0])) return 'продолжение';
  if (LEAD_RU.includes(lastWord(R)) || LEAD_EN.includes(lastWord(E)) || LEAD_HY.includes(lastWord(H))) return 'зачин';
  if ((R.match(/родил/gi) || []).length >= 2 || /\bbegat\b/i.test(E)) return 'родословие';
  const ws = words(R).slice(1);
  if (ws.length >= 4 && ws.filter(w => /^[А-ЯЁ]/.test(w)).length / ws.length >= 0.4) return 'перечень имён';
  const NUM = /(?:^|[^а-яё])(?:двадцат|тридцат|сорок|пятьдесят|шестьдесят|семьдесят|восемьдесят|девяносто|сто(?![а-яё])|двести|триста|четыреста|пятьсот|шестьсот|семьсот|восемьсот|девятьсот|тысяч|пятнадцат|шестнадцат|семнадцат|восемнадцат|девятнадцат|двенадцат|одиннадцат|тринадцат|четырнадцат)/gi;
  if ((R.match(NUM) || []).length >= 2) return 'числа';
  const head = words(R).slice(0, 3).map(w => w.toLowerCase().replace(/[^а-яё]/g, ''));
  const PAST = /^[а-яё]{3,}(?:л|ла|ли|ло|лся|лась|лись|лось)$/;
  const NOT_VERB = new Set(['было', 'были', 'была', 'мало', 'зло', 'число', 'село', 'дело', 'тело', 'много', 'гнев', 'ил', 'стол', 'жил', 'вол', 'орел', 'осел', 'котел', 'узел', 'престол', 'ствол', 'камыш', 'пол']);
  if (head.some(w => PAST.test(w) && !NOT_VERB.has(w))) return 'повествование';
  if (words(R).length < 5) return 'коротко (ru)';
  if (H.length < 25) return 'коротко (hy)';
  return 'ok';
}

// Слова, по которым видно, что стих о главном (порт VerseQuality.richness)
const RICH = ['бог', 'господ', 'христ', 'иисус', 'любов', 'любит', 'вера', 'веры', 'веру', 'вере', 'верит', 'верьте', 'веруй', 'надежд', 'милост', 'милосерд', 'благодат', 'благослов', 'истин', 'правд', 'свет', 'жизн', 'спас', 'молит', 'дух', 'радост', 'радуй', 'терпен', 'мудр', 'смирен', 'прощ', 'покая', 'блажен', 'вечн', 'царств', 'слав', 'заповед', 'уповай', 'сердц', 'душ'];
function richness(ru) {
  const t = ru.toLowerCase().split(/[^а-яё]+/).filter(Boolean);
  let s = RICH.filter(st => t.some(x => x.startsWith(st))).length;
  if (t.some(x => ['мир', 'мира', 'мире', 'миру'].includes(x))) s += 1;
  if (ru.toLowerCase().includes('не бойс')) s += 1;
  return s;
}

// То же, что ArmenianText.forWidget: без знаков над буквами, «։» и «`» как обычная пунктуация
function armDisplay(s) {
  return s.replace(/[՛՜՟]/g, '').replace(/՞/g, '').replace(/՝|`/g, ',').replace(/։/g, '.').replace(/:\s*$/, '.');
}

// ---- Отбор ----
const CONTINUATION = /^(И|А|Но|Ибо|Потому|Для того|Так как|Итак|Также|Зато|Если же|Же)\s/;
const LIMITS = { hy: 92, ru: 100, en: 112, minHy: 24 };
const rows = db.prepare(`
  SELECT v.id, b.id bid, b.name_ru bnru, b.name_en bnen, b.name_hy bnhy, v.chapter c, v.verse n,
         v.text_hy hy, COALESCE(v.text_hy_ararat,'') ar, v.text_ru ru, v.text_en en
  FROM verses v JOIN books b ON b.id = v.book_id WHERE LENGTH(v.text_hy) > 15`).all();

// Откуда берём: книги и главы, где стихи самостоятельны. Историческая проза, пророческие обличения, речи Иова и
// рассказы Евангелий вырванными из места читаются как обрывки.
const WHOLE = new Set(['Psalms', 'Proverbs', 'Ecclesiastes', 'Lamentations', 'Isaiah', 'Micah', 'Zephaniah', 'Nahum', 'Habakkuk',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Hebrews', 'James', '1 Peter', '2 Peter', '1 John']);
const CHAPTERS = { Matthew: [5, 6, 7, 11], Luke: [6, 11, 12], John: [3, 6, 8, 10, 13, 14, 15, 16] };
const inSources = r => WHOLE.has(r.bnen) || (CHAPTERS[r.bnen] || []).includes(r.c);
// Не самостоятельное: зачин рассказа, указание, пророческая формула
const NARRATIVE_START = /^(Вот|Тогда|Посему|Итак|Сей|Сия|Сие|Он|Она|Они|Иисус же|Потом|Затем|После|Так|Приветствуйте|Иаков|Павел|Петр|Иоанн|Рассудите|Никак|Чего|Братия)(?![а-яё])/;
// Послания и споры, которые без места не понятны
const BLOCK = new Set(['John 13:25', 'John 10:7', '1 Corinthians 4:21', '1 Corinthians 11:13', 'Romans 3:6', 'Romans 10:1', '2 Corinthians 8:16', '2 Corinthians 11:31', '1 Corinthians 1:8', 'Hebrews 10:10', 'Philippians 4:21', '1 Peter 5:14', 'James 1:1', 'Proverbs 3:33', 'Psalms 10:13', 'Psalms 27:8', 'Philippians 4:20', 'Ecclesiastes 6:9', 'Isaiah 42:8']);
const ORACLE = /говорит Господь|так говорит|сказал Господь|Господь сказал/i;
const stats = {};
const picked = [];
for (const r of rows) {
  if (BLOCK.has(`${r.bnen} ${r.c}:${r.n}`)) { stats.в_списке_исключений = (stats.в_списке_исключений || 0) + 1; continue; }
  if (!inSources(r)) { stats.не_та_книга = (stats.не_та_книга || 0) + 1; continue; }
  const why = verdict(r.hy, r.ru, r.en);
  if (why !== 'ok') { stats[why] = (stats[why] || 0) + 1; continue; }
  const ru = stripBraces(r.ru), en = stripBraces(r.en);
  const hyE = armDisplay(stripBraces(r.hy)), hyA = armDisplay(stripBraces(r.ar || r.hy));
  if (/[\[\]{}()]/.test(ru + en + hyE + hyA)) { stats.скобки = (stats.скобки || 0) + 1; continue; }
  if (NARRATIVE_START.test(ru) || ORACLE.test(ru)) { stats.зачин_или_пророчество = (stats.зачин_или_пророчество || 0) + 1; continue; }
  if (CONTINUATION.test(ru)) { stats.продолжение_ru = (stats.продолжение_ru || 0) + 1; continue; }
  if (Math.max(hyE.length, hyA.length) > LIMITS.hy || Math.min(hyE.length, hyA.length) < LIMITS.minHy) { stats.длина_hy = (stats.длина_hy || 0) + 1; continue; }
  if (ru.length > LIMITS.ru || en.length > LIMITS.en) { stats.длина_ru_en = (stats.длина_ru_en || 0) + 1; continue; }
  const rich = richness(ru);
  if (rich < 2) { stats.не_о_главном = (stats.не_о_главном || 0) + 1; continue; }
  picked.push({ ...r, ru, en, rich, hyLen: hyA.length });
}

// Ссылка вида «Псалом 23:1»; названия книг берём из таблицы books
const ref = (name, r) => `${name} ${r.c}:${r.n}`;

// Не больше 12 стихов с одной главы: иначе Псалмы и Притчи вытеснят остальное
const perChapter = new Map();
const final = [];
for (const r of picked.sort((a, b) => b.rich - a.rich || a.bid - b.bid || a.c - b.c || a.n - b.n)) {
  const key = `${r.bid}:${r.c}`;
  const used = perChapter.get(key) || 0;
  if (used >= 12) continue;
  perChapter.set(key, used + 1);
  final.push(r);
}
final.sort((a, b) => a.bid - b.bid || a.c - b.c || a.n - b.n);

console.log('отброшено:', JSON.stringify(stats));
console.log('прошло отбор:', picked.length, '| после лимита на главу:', final.length);
const byBook = new Map();
for (const r of final) byBook.set(r.bnen, (byBook.get(r.bnen) || 0) + 1);
console.log('по книгам:', [...byBook.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12).map(([k, v]) => `${k} ${v}`).join(', '));

if (mode === 'report') {
  const sample = final;
  for (const r of sample) console.log(`${ref(r.bnen, r)} [${r.rich}] ${r.ru}`);
  process.exit(0);
}

// В базе встречаются двойные запятые («светись,,»): сводим к одной
const esc = s => s.replace(/,{2,}/g, ',').replace(/\\/g, '\\\\').replace(/"/g, '\\"');
const entries = final.map(r => `        BibleVerse(
            textHy: "${esc(stripBraces(r.hy))}",
            textHyArarat: "${esc(stripBraces(r.ar || r.hy))}",
            textRu: "${esc(r.ru)}",
            textEn: "${esc(r.en)}",
            refHy: "${esc(ref(r.bnhy || r.bnru, r))}",
            refRu: "${esc(ref(r.bnru, r))}",
            refEn: "${esc(ref(r.bnen, r))}"
        )`);
const out = `import Foundation

// Сгенерировано Tools/QuoteLibrary/build_lock_pearls.mjs из Sources/bible.db. Не править вручную: правила отбора — в скрипте.
extension BibleVerse {
    /// Короткие законченные стихи для экрана блокировки и малого виджета (входят в бесплатную подборку «Жемчужины»)
    static let lockPearls: [BibleVerse] = [
${entries.join(',\n')}
    ]
}
`;
fs.writeFileSync(path.join(ROOT, 'Sources', 'BibleVerseDatabase+LockPearls.swift'), out);
console.log('записано', final.length, 'стихов,', Math.round(out.length / 1024), 'КБ');

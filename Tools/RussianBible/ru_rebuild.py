"""Перестройка русской колонки bible.db из синодального JSON.

Правило: в главах, где число стихов в БД и в JSON совпадает, стих N берётся из синодального стиха N (стандартная синодальная
нумерация). В остальных главах и в Псалмах (нумерация LXX, заголовки отдельными стихами) стихи выравниваются по длине сразу
по двум колонкам БД — армянской и английской (метод Гейла—Черча).

python -I ru_rebuild.py report            — только отчёт
python -I ru_rebuild.py apply <out.db>    — записать результат в копию базы

Источник и порядок работы — в README.md рядом. Переменные окружения: RU_SYNOD_JSON, BIBLE_DB.
"""
import json
import math
import os
import re
import shutil
import sqlite3
import sys
from collections import Counter, defaultdict
from difflib import SequenceMatcher

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.environ.get("RU_SYNOD_JSON", os.path.join(HERE, "ru_synod.json"))
DB = os.environ.get("BIBLE_DB", os.path.join(HERE, "..", "..", "Sources", "bible.db"))
MODE = sys.argv[1] if len(sys.argv) > 1 else "report"

SHARED_NOTE = "(см. предыдущий стих)"
MISSING_NOTE = "(нет в синодальном переводе)"
arm = re.compile("[\u0531-\u0587]")


def clean(t):
    # слова в квадратных скобках — вставки из греческого текста, которых нет в принятой у нас редакции: вырезаем вместе со скобками
    prev = None
    while prev != t:
        prev = t
        t = re.sub(r"\[[^\[\]]*\]", "", t)
    t = t.replace("\u0301", "").replace("||", " ").replace("|", " ")
    t = re.sub(r"\s+([,.;:!?»)])", r"\1", t)
    t = re.sub(r"([«(])\s+", r"\1", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def norm(s):
    return re.sub(r"[^а-я0-9]", "", s.lower().replace("ё", "е"))


# ------------------------------------------------------------------ загрузка
data = json.load(open(SRC, encoding="utf-8-sig"))
con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
books = con.execute("select id, name_en from books order by id").fetchall()
names = {b[0]: b[1] for b in books}
canon = [b[0] for b in books if b[0] not in (17, 27)]
def strip_brackets_chapter(verses):
    """Вырезает слова в квадратных скобках; вставка может начаться в одном стихе и закончиться в следующем"""
    depth = 0
    out = []
    for t in verses:
        buf = []
        for ch in t:
            if ch == "[":
                depth += 1
            elif ch == "]":
                depth = max(0, depth - 1)
            elif depth == 0:
                buf.append(ch)
        out.append("".join(buf))
    return out


SYN = {bid: [[clean(v) for v in strip_brackets_chapter(ch)] for ch in data[i]["chapters"]] for i, bid in enumerate(canon)}

DBV = defaultdict(list)  # (book, chapter) -> [(verse, hy, en, old_ru)]
for b, ch, v, hy, en, ru in con.execute("select book_id, chapter, verse, text_hy, text_en, text_ru from verses order by book_id, chapter, verse"):
    DBV[(b, ch)].append((v, hy, en, ru))
for key, lst in DBV.items():
    assert [x[0] for x in lst] == list(range(1, len(lst) + 1)), ("стихи не подряд", key)

# ------------------------------------------------------------------ Гейл—Черч по двум колонкам
sums = {"hy": [0, 0], "en": [0, 0]}
pairs = []
for bid, chs in SYN.items():
    for ci, vs in enumerate(chs, 1):
        d = DBV.get((bid, ci))
        if d and len(d) == len(vs):
            for (v, hy, en, ru), t in zip(d, vs):
                if not t:
                    continue
                for k, txt in (("hy", hy), ("en", en)):
                    sums[k][0] += len(txt)
                    sums[k][1] += len(t)
                pairs.append((hy, en, t))
PAR = {}
for k in ("hy", "en"):
    c = sums[k][1] / sums[k][0]
    idx = 0 if k == "hy" else 1
    dv = [(len(t) - c * max(len(p[idx]), 1)) / math.sqrt(max(len(p[idx]), 1)) for p in pairs for t in [p[2]]]
    PAR[k] = (c, sum(x * x for x in dv) / len(dv))
print("Гейл—Черч:", {k: (round(v[0], 3), round(v[1], 2)) for k, v in PAR.items()}, "по", len(pairs), "стихам")

PRIOR = {(1, 1): 0.89, (1, 0): 0.0099, (0, 1): 0.0099, (2, 1): 0.089, (1, 2): 0.089, (2, 2): 0.011, (3, 1): 0.0035, (1, 3): 0.0035}
PCOST = {k: -math.log(v) for k, v in PRIOR.items()}


def mcost(l1, l2, key):
    if l1 == 0 and l2 == 0:
        return 0.0
    c, s2 = PAR[key]
    delta = (l2 - l1 * c) / math.sqrt(max(l1, 1) * s2)
    p = max(1e-12, 2 * (1 - 0.5 * (1 + math.erf(abs(delta) / math.sqrt(2)))))
    return -math.log(p)


def cum(xs):
    out = [0]
    for x in xs:
        out.append(out[-1] + x)
    return out


def align(hy_l, en_l, ru_l):
    """Бусины [(i0, i1, j0, j1)]: строки БД [i0:i1] ↔ стихи JSON [j0:j1]; цена считается по обеим колонкам БД"""
    n, m = len(hy_l), len(ru_l)
    INF = 1e18
    cost = [[INF] * (m + 1) for _ in range(n + 1)]
    back = [[None] * (m + 1) for _ in range(n + 1)]
    cost[0][0] = 0.0
    ph, pe, pr = cum(hy_l), cum(en_l), cum(ru_l)
    for i in range(n + 1):
        for j in range(m + 1):
            if cost[i][j] >= INF:
                continue
            for (a, b), pc in PCOST.items():
                ni, nj = i + a, j + b
                if ni > n or nj > m:
                    continue
                lr = pr[nj] - pr[j]
                cc = cost[i][j] + pc + min(mcost(ph[ni] - ph[i], lr, "hy"), mcost(pe[ni] - pe[i], lr, "en"))
                if cc < cost[ni][nj]:
                    cost[ni][nj] = cc
                    back[ni][nj] = (i, j)
    beads = []
    i, j = n, m
    while (i, j) != (0, 0):
        pi, pj = back[i][j]
        beads.append((pi, i, pj, j))
        i, j = pi, pj
    beads.reverse()
    return beads, cost[n][m]


def offset_cost(hy_l, en_l, ru_l, k):
    D = len(hy_l)
    return sum(PCOST[(1, 1)] + min(mcost(hy_l[i], ru_l[i + k], "hy"), mcost(en_l[i], ru_l[i + k], "en")) for i in range(D))


# ------------------------------------------------------------------ сборка нового ru
new_ru = {}
notes = []
title_count = [0]
flagged = []


def put_window(bid, db_chapters, json_flat, beads):
    flat_db = [(ch, v) for ch, lst in db_chapters for v, _, _, _ in lst]
    for i0, i1, j0, j1 in beads:
        group = flat_db[i0:i1]
        texts = json_flat[j0:j1]
        if not group:
            title_count[0] += len(texts)
            continue
        if len(group) == len(texts):  # поровну: стих в стих
            for (ch, v), t in zip(group, texts):
                new_ru[(bid, ch, v)] = t or MISSING_NOTE
            continue
        notes.append((names[bid], group[0], group[-1], len(group), len(texts)))
        joined = " ".join(t for t in texts if t)
        new_ru[(bid, *group[0])] = joined if joined else MISSING_NOTE
        for ch, v in group[1:]:
            new_ru[(bid, ch, v)] = SHARED_NOTE if joined else MISSING_NOTE


def lens(db_chs):
    flat = [x for _, lst in db_chs for x in lst]
    return [len(x[1]) for x in flat], [len(x[2]) for x in flat]


PSALMS = 19
for bid, chs in SYN.items():
    if bid == PSALMS:
        continue
    mism = [ci for ci in range(1, len(chs) + 1) if len(DBV[(bid, ci)]) != len(chs[ci - 1])]
    for ci in range(1, len(chs) + 1):
        if ci in mism:
            continue
        for (v, hy, en, ru), t in zip(DBV[(bid, ci)], chs[ci - 1]):
            new_ru[(bid, ci, v)] = t or MISSING_NOTE
        # диагностика: нет ли длинного сдвига (только отчёт, на результат не влияет)
        hy_l, en_l = lens([(ci, DBV[(bid, ci)])])
        ru_l = [len(t) for t in chs[ci - 1]]
        beads, c_dp = align(hy_l, en_l, ru_l)
        c_id = sum(PCOST[(1, 1)] + min(mcost(hy_l[i], ru_l[i], "hy"), mcost(en_l[i], ru_l[i], "en")) for i in range(len(ru_l)))
        real = [(a0 + 1, a1, b0 + 1, b1) for a0, a1, b0, b1 in beads if (a1 - a0) != (b1 - b0)]
        if c_id - c_dp > 25 and real:
            flagged.append((names[bid], ci, round(c_id - c_dp, 1), real[:4]))
    k = 0
    while k < len(mism):
        group = [mism[k]]
        while k + 1 < len(mism) and mism[k + 1] == group[-1] + 1:
            k += 1
            group.append(mism[k])
        k += 1
        db_chs = [(ci, DBV[(bid, ci)]) for ci in group]
        json_flat = [t for ci in group for t in chs[ci - 1]]
        hy_l, en_l = lens(db_chs)
        beads, _ = align(hy_l, en_l, [len(t) for t in json_flat])
        put_window(bid, db_chs, json_flat, beads)

# --- Псалмы
windows = []
n = 1
while n <= 150:
    if n <= 8 or n >= 148:
        windows.append(([n], [n])); n += 1
    elif n == 9:
        windows.append(([9, 10], [9])); n += 2
    elif n == 114:
        windows.append(([114, 115], [113])); n += 2
    elif n == 116:
        windows.append(([116], [114, 115])); n += 1
    elif n == 147:
        windows.append(([147], [146, 147])); n += 1
    else:
        windows.append(([n], [n - 1])); n += 1

ps = SYN[PSALMS]
pstat = Counter()
psalm_notes = []
MARK_RE = re.compile(r"\(\s*\d+\s*[:\-\u2013]\s*\d+\s*\)")
FORCED_TITLE = {13: 1, 90: 1}  # псалмы, где число стихов совпадает, но первый стих JSON — заголовок


def old_title(old_v1, new_v1):
    """Заголовок из прежнего русского текста: всё, что стоит перед началом первого стиха (без пометок вроде «(22:1)»)"""
    if arm.search(old_v1):
        return ""
    words = [re.sub(r"[^\w]", "", w) for w in new_v1.split()]
    words = [w for w in words if w][:2]
    if len(words) < 2:
        return ""
    m = re.search(re.escape(words[0]) + r"[^\w]+" + re.escape(words[1]), old_v1)
    if not m or m.start() == 0:
        return ""
    raw = MARK_RE.sub(" ", old_v1[:m.start()])
    raw = re.sub(r"\s+", " ", raw).strip(" ,;")
    return raw if 3 < len(raw) < 320 and re.search("[а-яА-Я]", raw) else ""


for dbl, jl in windows:
    db_chs = [(c, DBV[(PSALMS, c)]) for c in dbl]
    json_flat = [t for p in jl for t in ps[p - 1]]
    hy_l, en_l = lens(db_chs)
    D, J = len(hy_l), len(json_flat)
    k = J - D
    tv = k if 1 <= k <= 3 else FORCED_TITLE.get(dbl[0], 0)
    title = " ".join(t for t in json_flat[:tv] if t).strip() if tv else ""
    rest = json_flat[tv:]
    beads, _ = align(hy_l, en_l, [len(t) for t in rest])
    put_window(PSALMS, db_chs, rest, beads)
    key1 = (PSALMS, dbl[0], 1)
    src = "JSON"
    if not title:
        title = old_title(DBV[(PSALMS, dbl[0])][0][3], new_ru[key1])
        src = "старый текст"
    if title:
        new_ru[key1] = f"[{title}] {new_ru[key1]}"
        pstat["заголовок из " + src] += 1
    else:
        pstat["без заголовка"] += 1
    if k < 0 or k > 3:
        psalm_notes.append((dbl, jl, D, J, k))

# --- Есфирь и Даниил: нет в синодальном JSON; чистим прежний текст (пометки «(4:1)», армянские заглушки в хвосте глав)
def strip_marks(t):
    t = MARK_RE.sub(" ", t)
    t = re.sub(r"\s+([,.;:!?»)])", r"\1", t)
    return re.sub(r"\s+", " ", t).strip()


side_notes = []
for bid in (17, 27):
    for ch in sorted({key[1] for key in DBV if key[0] == bid}):
        rows = DBV[(bid, ch)]
        olds = [r[3] for r in rows]
        if not any(arm.search(o) for o in olds):
            for (v, hy, en, ru) in rows:
                new_ru[(bid, ch, v)] = strip_marks(ru)
            continue
        src = [strip_marks(o) for o in olds if not arm.search(o)]
        hy_l, en_l = lens([(ch, rows)])
        beads, _ = align(hy_l, en_l, [len(t) for t in src])
        put_window(bid, [(ch, rows)], src, beads)
        side_notes.append((names[bid], ch, len(rows), len(src), [(a0 + 1, a1, b0 + 1, b1) for a0, a1, b0, b1 in beads if (a1 - a0) != (b1 - b0)]))

# ------------------------------------------------------------------ отчёт
total_db = sum(len(v) for v in DBV.values())
print(f"стихов в БД: {total_db}; новый текст: {len(new_ru)}; без синодального источника (Есфирь, Даниил): {total_db - len(new_ru)}")
print("стихов JSON без пары в БД (заголовки псалмов и т.п.):", title_count[0])
print("Псалмы:", dict(pstat))
for r in psalm_notes:
    print("   Псалом, выбран DP:", r)
print("Есфирь/Даниил, главы с заглушками (строк БД, стихов в старом тексте, бусины):")
for sn in side_notes:
    print("   ", sn)
print("нестандартные бусины (не стих в стих):", len(notes))
for nt in notes:
    print("   ", nt)
print("главы с равным числом стихов и сильным подозрением на сдвиг (>25 нат; на результат не влияет):", len(flagged))
for f in flagged:
    print("   ", f)
empties = [k for k, t in new_ru.items() if t in (MISSING_NOTE,)]
shared = [k for k, t in new_ru.items() if t == SHARED_NOTE]
print("строк с пометкой «нет в синодальном переводе»:", len(empties), "; «см. предыдущий стих»:", len(shared))

ratios = []
for (bid, ch, v), t in new_ru.items():
    old = DBV[(bid, ch)][v - 1][3]
    if arm.search(old) or not old.strip() or t in (SHARED_NOTE, MISSING_NOTE):
        continue
    ratios.append(SequenceMatcher(None, norm(old), norm(t)).ratio())
nn = len(ratios)
for thr in (0.99, 0.95, 0.8):
    print(f"сходство нового с прежним >= {thr}: {sum(1 for r in ratios if r >= thr)} из {nn} ({100 * sum(1 for r in ratios if r >= thr) / nn:.1f}%)")

if MODE == "apply":
    out = sys.argv[2]
    shutil.copyfile(DB, out)
    w = sqlite3.connect(out)
    w.execute("pragma journal_mode=delete")
    w.executemany("update verses set text_ru=? where book_id=? and chapter=? and verse=?", [(t, b, c, v) for (b, c, v), t in new_ru.items()])
    w.commit()
    w.execute("insert into verses_fts(verses_fts) values('rebuild')")
    w.commit()
    w.execute("vacuum")
    print("записано в", out, "; обновлено стихов:", len(new_ru))
    w.close()

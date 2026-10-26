"""Собирает Sources/narek_original_hy.json — армянский оригинал «Մատեան Ողբերգութեան» (Книга скорбных песнопений, 95 глав).

Источник: страница «Մատեան Ողբերգութեան» на hy.wikisource.org (грабар), переданная владельцем приложения 2026-10-21.
Скрипт сам скачивает викитекст через API MediaWiki (или берёт сохранённый файл, если указан путь) и разбирает его:
  * заголовки «== Բան Ա ==» — 95 глав по порядку (в заголовке 87-й главы опечатка «Բան ԶԷ», берётся порядковый номер);
  * в `<poem>` сначала заголовок прописными буквами (одна-две строки), потом строфы: строка с армянской цифрой («Ա», «Բ», «ԺԱ»…) и строки строфы.

Что исправляется в тексте (это следы набора, не слова автора):
  * «`` ` ``» в конце строк — армянский знак «՝» (ստորակետ);
  * «,-» в конце строки → «,» (тире после запятой — след разметки);
  * буква «þ» перед словом (в 10 местах, Բան ԾԲ, ՀԲ, ՀԵ, ՀԷ, ՂԲ, ՂԳ) — след кавычки: убирается (перед прописной буквой остаётся пробел);
  * «_» между словами → пробел, лишний «\\» и «+» убираются, неразрывный пробел → пробел.
Прочие знаки (« . », « : », «,») остаются как в источнике.

Запуск (из корня репозитория):
    python -I Tools/NarekOriginal/build_original.py report [файл.wiki]
    python -I Tools/NarekOriginal/build_original.py write [файл.wiki]
"""
import hashlib
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Sources" / "narek_original_hy.json"
PAGE = "Մատեան Ողբերգութեան"
API = "https://hy.wikisource.org/w/api.php"

NUMERALS = {}
for i, ch in enumerate("ԱԲԳԴԵԶԷԸԹ", 1):
    NUMERALS[ch] = i
for i, ch in enumerate("ԺԻԼԽԾԿՀՁՂ", 1):
    NUMERALS[ch] = i * 10
for i, ch in enumerate("ՃՄՅՆՇՈՉՊՋ", 1):
    NUMERALS[ch] = i * 100


def numeral_value(label):
    return sum(NUMERALS.get(c, 0) for c in label)


def fetch():
    params = urllib.parse.urlencode({
        "action": "query", "prop": "revisions", "rvprop": "ids|timestamp|content", "rvslots": "main",
        "format": "json", "titles": PAGE,
    })
    # Викимедиа отвечает 403 на запросы без User-Agent
    request = urllib.request.Request(f"{API}?{params}", headers={"User-Agent": "ArmenianBibleApp-build-script/1.0 (https://github.com/samjan190799-cmyk/ArmenianBible)"})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = json.load(response)
    page = next(iter(data["query"]["pages"].values()))
    revision = page["revisions"][0]
    return revision["slots"]["main"]["*"], revision["revid"], revision["timestamp"]


def is_caps(line):
    letters = [c for c in line if "Ա" <= c <= "և"]
    return bool(letters) and not any("ա" <= c <= "և" for c in letters)


def sentence_case(line):
    low = line.lower()
    low = re.sub(r"\b(աստուած\w*|աստուծ\w*|միւռոն\w*)", lambda m: m.group(1)[0].upper() + m.group(1)[1:], low)
    return low[:1].upper() + low[1:]


def clean_line(line):
    line = line.replace(" ", " ").replace("'''", "")
    line = line.replace("`", "՝")
    line = re.sub(r",-\s*$", ",", line)
    line = line.replace("\\", "").replace("_", " ")
    line = re.sub(r"þ(?=[Ա-Ֆ])", " ", line)
    line = line.replace("þ", "")
    return re.sub(r"[ \t]+", " ", line).strip()


def parse(text):
    parts = re.split(r"^==\s*(.+?)\s*==\s*$", text, flags=re.M)
    sections = [(parts[i], parts[i + 1]) for i in range(1, len(parts) - 1, 2)]
    chapters = []
    problems = []
    for number, (heading, body) in enumerate(sections, 1):
        inner = re.search(r"<poem>\n?(.*?)</poem>", body, re.S)
        if not inner:
            problems.append((number, "нет <poem>"))
            continue
        lines = [clean_line(l) for l in inner.group(1).split("\n")]
        lines = [l for l in lines if l and l not in ("՝", "+")]
        title_lines = []
        # заголовок — первые строки прописными буквами; цифра строфы («Ա», «ԺԱ») тоже прописная, но короче четырёх знаков
        while lines and is_caps(lines[0]) and len(re.sub(r"[^Ա-Ֆ]", "", lines[0])) >= 4:
            title_lines.append(lines.pop(0))
        stanzas = []
        current = None
        for l in lines:
            label_match = re.fullmatch(r"[+\s]*([Ա-Ֆ]{1,3})[\s.]*", l)
            if label_match and numeral_value(label_match.group(1)) > 0 and len(l) <= 6:
                current = {"label": label_match.group(1), "lines": []}
                stanzas.append(current)
            else:
                if current is None:
                    current = {"label": "", "lines": []}
                    stanzas.append(current)
                current["lines"].append(l)
        stanzas = [s for s in stanzas if s["lines"]]
        values = [numeral_value(s["label"]) for s in stanzas if s["label"]]
        if values != list(range(1, len(values) + 1)):
            problems.append((number, f"строфы идут не по порядку: {values}"))
        if any(not s["label"] for s in stanzas):
            problems.append((number, "строки до первой цифры строфы"))
        chapters.append({
            "id": number,
            "ban": heading if number != 87 else "Բան ՁԷ",
            "titleLines": [sentence_case(t) for t in title_lines],
            "stanzas": stanzas,
        })
    return chapters, problems


def main(mode, path=None):
    sys.stdout.reconfigure(encoding="utf-8")
    if path:
        text = Path(path).read_text(encoding="utf-8")
        revision, timestamp = 394708, "2026-09-06T10:07:48Z"
    else:
        text, revision, timestamp = fetch()
    chapters, problems = parse(text)
    total_lines = sum(len(s["lines"]) for c in chapters for s in c["stanzas"])
    total_chars = sum(len(l) for c in chapters for s in c["stanzas"] for l in s["lines"])
    print(f"глав: {len(chapters)}, строф: {sum(len(c['stanzas']) for c in chapters)}, строк: {total_lines}, знаков: {total_chars}")
    print("замечания:", problems or "нет")
    for c in chapters[:2] + chapters[-2:]:
        print(c["id"], c["ban"], c["titleLines"], [(s["label"], len(s["lines"])) for s in c["stanzas"]][:6], "|", c["stanzas"][0]["lines"][0])
    left = sorted({ch for c in chapters for s in c["stanzas"] for l in s["lines"] for ch in l if not ("Ա" <= ch <= "և") and ch not in " ,.:;!?-՝՜՞՛"})
    print("необычные знаки в тексте:", left)
    if mode != "write":
        return
    data = {
        "source": {
            "title": PAGE,
            "language": "hy (грабар)",
            "site": "hy.wikisource.org",
            "url": "https://hy.wikisource.org/wiki/" + urllib.parse.quote(PAGE.replace(" ", "_")),
            "revision": revision,
            "revisionTime": timestamp,
            "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        },
        "chapters": chapters,
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=None, separators=(",", ":")) + "\n", encoding="utf-8")
    print("записано:", OUT.relative_to(ROOT), OUT.stat().st_size, "байт")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "report", sys.argv[2] if len(sys.argv) > 2 else None)

"""Собирает Sources/BibleVerseDatabase+Library.swift: цельные отрывки из Sources/bible.db для среднего и большого виджета.

Зачем: подходящих по длине цитат для среднего (56-90 знаков) и большого (101-360) виджета было по ~50 на язык,
они быстро повторялись. Здесь отрывки берутся прямо из базы, по списку мест ниже.

Что делает для каждого места:
  * склеивает стихи в один отрывок; если отрывок обрывается на «:», «;» или запятой, дочитывает до конца предложения
    (до трёх стихов вперёд);
  * убирает пометки переводчиков KJV `{wither: Heb. fade}`, слова-вставки `{is}`, `{nl}`, заголовки псалмов в [скобках],
    богослужебное «Слава:»; ставит точку вместо «:» или «;» в конце и заглавную букву в начале (по-русски и по-английски);
  * пропускает отрывок, если в нём остались скобки или пометки, он обрывается на запятой, или длины на трёх языках
    расходятся (признак сдвига нумерации в английской или армянской колонке);
  * пропускает то, что уже есть в других подборках (по книге, главе и пересечению стихов);
  * в ссылках пользуется теми же названиями книг, что и старые подборки; номера псалмов по-русски — синодальные.

Армянский текст берётся в обеих редакциях: `textHy` — Эчмиадзин (как в базе), `textHyArarat` — Арарат.

Запуск (из корня репозитория):
    python -I Tools/QuoteLibrary/build_library.py report   # показать, что получилось, ничего не записывая
    python -I Tools/QuoteLibrary/build_library.py write    # записать Sources/BibleVerseDatabase+Library.swift
"""
import json
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DB = ROOT / "Sources" / "bible.db"
OUT = ROOT / "Sources" / "BibleVerseDatabase+Library.swift"

# Места: «Книга глава:стих» или «Книга глава:стих-стих». Книги названы короткими английскими именами из таблицы books.
REFS = """
Ps 1:1-3; Ps 4:8; Ps 16:11; Ps 18:2; Ps 19:1-2; Ps 19:7-8; Ps 23:4; Ps 23:5-6; Ps 25:4-5; Ps 27:4; Ps 28:7; Ps 29:11;
Ps 30:5; Ps 32:8; Ps 34:4-5; Ps 36:5-6; Ps 36:9; Ps 37:7; Ps 37:23-24; Ps 42:1-2; Ps 51:10-12; Ps 55:22; Ps 63:1;
Ps 73:25-26; Ps 84:1-2; Ps 84:10-11; Ps 86:5; Ps 90:12; Ps 91:1-2; Ps 118:24; Ps 119:9-11; Ps 119:105; Ps 121:7-8;
Ps 126:5-6; Ps 127:1; Ps 130:5-6; Ps 138:3; Ps 139:13-14; Ps 139:23-24; Ps 145:8-9; Ps 145:18; Ps 147:3-4; Ps 150:6;
Prov 3:3-4; Prov 3:13-14; Prov 4:23; Prov 10:12; Prov 11:25; Prov 12:25; Prov 14:30; Prov 15:1; Prov 15:13; Prov 16:3;
Prov 16:9; Prov 17:17; Prov 17:22; Prov 18:10; Prov 18:24; Prov 22:6; Prov 27:17; Prov 31:25-26;
Eccl 3:11; Eccl 4:9-10; Eccl 4:12;
Isa 9:6; Isa 26:3; Isa 30:18; Isa 40:8; Isa 41:13; Isa 43:18-19; Isa 49:15-16; Isa 53:4-5; Isa 54:10; Isa 55:1;
Isa 55:10-11; Isa 60:1; Isa 66:13;
Jer 17:7-8; Jer 29:11-13; Jer 31:3; Jer 33:3; Lam 3:22-24; Lam 3:25-26; Mic 6:8; Mic 7:7-8; Zeph 3:17; Nah 1:7;
Matt 5:14-16; Matt 5:44-45; Matt 6:6; Matt 6:9-13; Matt 6:19-21; Matt 6:24; Matt 6:33-34; Matt 7:7-8; Matt 7:12;
Matt 7:24-25; Matt 11:28-30; Matt 16:24-26; Matt 18:20; Matt 19:26; Matt 25:21; Matt 28:19-20;
Mark 9:23; Mark 10:27; Mark 11:24;
Luke 1:37; Luke 6:27-28; Luke 6:31; Luke 6:36-38; Luke 11:9-10; Luke 12:6-7; Luke 12:34; Luke 15:7; Luke 15:20; Luke 18:27;
John 1:1-5; John 1:29; John 3:16-17; John 4:23-24; John 6:35; John 6:37; John 8:12; John 10:10-11; John 10:27-28;
John 11:25-26; John 12:24; John 13:34-35; John 14:1-3; John 14:6; John 14:15-17; John 14:27; John 15:4-5; John 16:33;
John 17:3; John 20:29;
Acts 1:8; Acts 4:12; Acts 20:35;
Rom 1:16; Rom 5:1-2; Rom 5:3-5; Rom 5:8; Rom 6:23; Rom 8:1; Rom 8:18; Rom 8:28; Rom 8:31-32; Rom 10:9-10; Rom 10:17;
Rom 12:15-18; Rom 15:13;
1Cor 1:18; 1Cor 2:9; 1Cor 10:13; 1Cor 13:4-7; 1Cor 13:12-13; 1Cor 15:55-58; 1Cor 16:13-14;
2Cor 1:3-4; 2Cor 4:16-18; 2Cor 5:17; 2Cor 5:20-21; 2Cor 9:7-8; 2Cor 12:9-10;
Gal 2:20; Gal 5:1; Gal 5:22-23; Gal 6:2; Gal 6:9-10;
Eph 2:8-10; Eph 3:20-21; Eph 4:1-3; Eph 4:31-32; Eph 5:1-2;
Phil 3:13-14; Phil 4:4-7; Phil 4:8; Phil 4:11-13; Phil 4:19;
Col 3:1-3; Col 3:12-14; Col 3:15-17; Col 3:23-24;
1Thess 5:11; 1Thess 5:14-18; 2Thess 3:3; 1Tim 4:12; 1Tim 6:6-8; 2Tim 1:7; 2Tim 4:7-8; Titus 3:4-7;
Heb 4:12; Heb 4:15-16; Heb 11:1-3; Heb 11:6; Heb 12:1-2; Heb 13:5-6; Heb 13:8; Heb 13:15-16;
Jas 1:2-4; Jas 1:5; Jas 1:12; Jas 1:17; Jas 1:19-20; Jas 1:22; Jas 4:7-8; Jas 4:10; Jas 5:16;
1Pet 1:3-5; 1Pet 2:9; 1Pet 3:8-9; 1Pet 4:8-10; 1Pet 5:6-7; 1Pet 5:10; 2Pet 3:8-9;
1John 3:1; 1John 4:7-8; 1John 4:9-11; 1John 4:16; 1John 4:18-19;
Rev 3:20; Rev 21:5-7; Rev 22:12-13; Rev 22:17;
Ps 37:5; Ps 37:39-40; Ps 46:1-2; Ps 62:5-6; Ps 103:2-4; Ps 103:13-14; Ps 107:8-9; Ps 116:1-2; Ps 118:5-6; Ps 118:8-9; Ps 119:50;
Ps 119:165; Ps 121:1-2; Ps 139:7-10; Ps 143:10; Ps 146:5; Ps 147:11;
Prov 3:7-8; Prov 11:2; Prov 12:18; Prov 13:20; Prov 14:26; Prov 15:30; Prov 16:7; Prov 16:24; Prov 16:32; Prov 17:9; Prov 18:21;
Prov 19:21; Prov 21:21; Prov 22:1; Prov 24:3-4; Prov 24:16; Prov 25:11; Prov 28:13; Prov 29:25; Prov 30:5; Prov 31:30;
Eccl 3:1; Eccl 7:8;
Isa 12:2; Isa 12:3; Isa 32:17; Isa 35:3-4; Isa 40:29-31; Isa 44:3; Isa 46:4; Isa 49:13; Isa 51:11; Isa 52:7; Isa 57:15; Isa 61:10; Isa 65:24;
Jer 15:16; Jer 31:25; Jer 32:17; Ezek 36:26; Dan 12:3; Hos 6:3; Joel 2:13; Hab 2:3; Hab 2:14; Zech 4:6;
Matt 5:3-6; Matt 5:7-9; Matt 5:16; Matt 6:14-15; Matt 6:21; Matt 6:31-32; Matt 6:34; Matt 7:1-2; Matt 7:13-14; Matt 9:37-38;
Matt 10:29-31; Matt 17:20; Matt 18:3-4; Matt 18:19; Matt 20:26-28; Matt 21:22; Matt 24:35; Matt 28:20;
Mark 8:34-36; Mark 9:35; Mark 10:14; Mark 10:45; Mark 12:31; Mark 16:15;
Luke 2:10-11; Luke 2:14; Luke 6:35; Luke 6:37; Luke 9:23-24; Luke 12:15; Luke 12:32; Luke 14:11; Luke 15:10; Luke 16:10; Luke 17:6;
Luke 19:10; Luke 21:33;
John 1:12-13; John 1:16-17; John 3:36; John 4:14; John 5:24; John 6:63; John 7:37-38; John 8:36; John 9:4-5; John 10:9; John 10:14-15;
John 12:46; John 13:14-15; John 13:35; John 14:13-14; John 14:21; John 14:23; John 15:7-8; John 15:11; John 15:12-13; John 15:16;
John 16:24; John 16:27; John 17:17; John 20:21; John 20:31;
Acts 2:21; Acts 3:19; Acts 10:34-35; Acts 16:31; Acts 20:24;
Rom 3:28; Rom 5:5; Rom 8:6; Rom 8:15-16; Rom 8:37-39; Rom 11:33; Rom 11:36; Rom 12:1-2; Rom 12:9-10; Rom 12:12; Rom 12:14;
Rom 12:17-18; Rom 13:10; Rom 14:8; Rom 15:5-6; Rom 15:7;
1Cor 3:16; 1Cor 6:19-20; 1Cor 10:31; 1Cor 13:1-3; 1Cor 13:13; 1Cor 15:3-4; 1Cor 15:10; 1Cor 15:20; 1Cor 15:57; 1Cor 15:58;
2Cor 3:17-18; 2Cor 4:7-9; 2Cor 4:18; 2Cor 5:1; 2Cor 5:7; 2Cor 5:14-15; 2Cor 5:18; 2Cor 6:2; 2Cor 8:9; 2Cor 9:6; 2Cor 9:15;
2Cor 12:9; 2Cor 13:11; 2Cor 13:14;
Gal 3:26-28; Gal 4:6-7; Gal 5:6; Gal 5:13-14; Gal 5:16; Gal 5:25; Gal 6:7-8;
Eph 1:7-8; Eph 2:10; Eph 3:16-17; Eph 4:29; Eph 5:8-10; Eph 5:19-20; Eph 6:10-11;
Phil 1:6; Phil 1:21; Phil 2:3-4; Phil 2:13; Phil 3:20-21; Phil 4:4-5; Phil 4:6-7; Phil 4:9;
Col 1:13-14; Col 1:27; Col 2:6-7; Col 3:2; Col 3:13; Col 3:16; Col 3:17; Col 4:2; Col 4:6;
1Thess 4:13-14; 1Thess 5:15; 1Thess 5:23-24; 2Thess 2:16-17; 2Thess 3:16;
1Tim 1:15; 1Tim 2:5-6; 1Tim 4:8; 1Tim 6:11-12; 1Tim 6:17-19; 2Tim 1:9; 2Tim 1:12; 2Tim 2:1; 2Tim 2:22; 2Tim 3:16-17; 2Tim 4:17-18;
Titus 2:11-12;
Heb 2:18; Heb 3:13; Heb 6:19; Heb 7:25; Heb 8:12; Heb 10:22; Heb 10:23; Heb 10:24-25; Heb 10:35-36; Heb 11:1; Heb 12:2; Heb 12:11;
Heb 12:14; Heb 13:2; Heb 13:6; Heb 13:16; Heb 13:20-21;
Jas 1:2-3; Jas 1:19; Jas 1:21; Jas 2:13; Jas 3:17-18; Jas 4:6; Jas 5:7-8;
1Pet 1:6-7; 1Pet 1:8-9; 1Pet 1:22; 1Pet 2:21; 1Pet 2:24; 1Pet 3:15; 1Pet 4:10; 1Pet 4:12-13; 1Pet 5:5-6; 1Pet 5:7; 1Pet 5:8-9;
2Pet 1:3-4; 2Pet 3:18;
1John 1:5; 1John 1:7; 1John 1:9; 1John 2:1; 1John 2:17; 1John 3:2; 1John 3:16; 1John 3:18; 1John 3:23; 1John 4:4; 1John 4:10;
1John 4:12; 1John 4:19; 1John 5:4; 1John 5:11-12; 1John 5:13; 1John 5:14-15;
Jude 1:20-21; Jude 1:24-25; Rev 1:8; Rev 1:17-18; Rev 2:10; Rev 7:16-17; Rev 21:3-4; Rev 21:6; Rev 22:1-2; Rev 22:20-21
"""

# Отрывки, которые не берём, хотя они проходят автоматические проверки
EXCLUDE = {
    "Psalm 143:8",       # в русской колонке лишняя запятая «Укажи мне, путь»
    "Isaiah 30:14-15",   # продолжение угрозы, обрывается на «но вы не хотели»
    "Luke 23:34",        # вместе с повествованием о делёжке одежд
    "Luke 15:20",        # начинается с «Встал и пошёл…» без подлежащего: вне притчи непонятно, о ком речь
    "Psalm 37:7",        # вторая половина («не ревнуй успевающему…») тёмная без контекста
    "James 4:7-8",       # заканчивается упрёком «грешники, двоедушные»
    "1 Corinthians 2:9", # начинается с «Но, как написано:»
    # начинаются с повествования («Петр отверз уста и сказал:», «Они же сказали:») или с отсылки к предыдущему («Которая…», «Вторая…»)
    "Mark 8:34-36", "Mark 9:35", "Mark 10:14", "Mark 12:31", "Luke 9:23-24", "Luke 12:15", "Luke 17:6", "Acts 10:34-35",
    "Acts 16:31", "John 7:37-38", "John 14:23", "John 20:21", "Matthew 9:37-38", "Matthew 17:20-21", "Revelation 1:17-18",
    "Hebrews 6:19-20", "Hebrews 13:6", "1 Peter 1:8-9", "Zechariah 4:6",
    # тёмные по смыслу вне контекста, личные места посланий, строгие предостережения
    "Revelation 2:10", "Daniel 12:3", "Romans 8:6-7", "Galatians 5:16-17", "1 Peter 5:8-9", "1 Timothy 2:5-7",
    "2 Timothy 2:22", "Ephesians 5:8-11", "Philippians 1:6-7", "Colossians 1:27-29", "Acts 3:19-21", "Acts 20:24",
    "Jeremiah 15:16",
    # в русской колонке остаётся закрывающая кавычка «»» без открывающей
    "Hosea 6:3", "Hebrews 8:12",
}

# Союзы в начале отрывка отрезаем: «Ибо Я Господь, Бог твой» -> «Я Господь, Бог твой». Так цитата начинается с мысли, а не с отсылки к предыдущему стиху.
LEAD_WORDS = {
    "ru": ("Ибо, ", "Ибо ", "Итак, ", "Итак ", "Посему ", "Потому что ", "Но ", "А "),
    "en": ("For ", "But ", "Therefore ", "Wherefore ", "Now "),
    "hy": ("Որովհետև ", "Որովհետեւ ", "Բայց ", "Արդ ", "Ուրեմն ", "Ուստի ", "Իսկ "),
}


def trim_lead(text, words):
    for w in words:
        if text.startswith(w) and len(text) - len(w) >= 25:
            rest = text[len(w):]
            return rest[0].upper() + rest[1:]
    return text

MIN_LEN = 56    # в самом длинном из трёх языков не короче (иначе это короткая цитата, у них своя подборка)
MAX_LEN = 430   # и не длиннее (в большой виджет дольше не помещается)


def clean(s):
    s = s.replace("{nl}", " ")
    s = re.sub(r"\{[^{}]*:[^{}]*\}", "", s)       # пометки переводчиков KJV: {wither: Heb. fade}
    s = re.sub(r"[{}]", "", s)                    # слова, добавленные переводчиком: {is}
    s = re.sub(r"\[[^\[\]]*\]\s*", "", s)         # заголовки псалмов в квадратных скобках
    s = re.sub(r"\s*Слава:\s*", " ", s)           # богослужебная вставка в синодальной Псалтири
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r",\s*,", ",", s)                  # «светись,, ибо» в русской колонке
    s = re.sub(r"\s+([,.;:!?])", r"\1", s)
    return s


def first_letter(s):
    for c in s:
        if c.isalpha():
            return c
    return "A"


def psalm_ru(ch):
    # в синодальном переводе нумерация псалмов на единицу меньше (10-113 и 117-146 по еврейской нумерации)
    return ch - 1 if (10 <= ch <= 113 or 117 <= ch <= 146) else ch


# --- Что уже есть в других подборках: названия книг и занятые места
FIELD = re.compile(r'(\w+):\s*"((?:[^"\\]|\\.)*)"')


def existing_refs():
    refs = []
    for path in sorted((ROOT / "Sources").glob("BibleVerseDatabase*.swift")):
        if path.name.endswith("+Library.swift"):
            continue
        text = path.read_text(encoding="utf-8")
        for m in re.finditer(r"BibleVerse\(", text):
            i, depth, in_str = m.end(), 1, False
            while i < len(text) and depth:
                c = text[i]
                if in_str:
                    if c == "\\":
                        i += 1
                    elif c == '"':
                        in_str = False
                elif c == '"':
                    in_str = True
                elif c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                i += 1
            fields = {f.group(1): f.group(2) for f in FIELD.finditer(text[m.end():i - 1])}
            if "refEn" in fields:
                refs.append(fields)
    return refs


def span_of(ref_en):
    m = re.match(r"(.+?) (\d+):(\d+)(?:-(\d+))?$", ref_en)
    if not m:
        return None
    return (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4) or m.group(3)))


def main(mode):
    sys.stdout.reconfigure(encoding="utf-8")
    db = sqlite3.connect(DB)
    books = {}
    for bid, nhy, nru, nen, sen in db.execute("select id, name_hy, name_ru, name_en, short_name_en from books"):
        books[sen] = (bid, nhy, nru, nen)

    old = existing_refs()
    names = {}
    for f in old:
        m_en = re.match(r"(.+?) \d+:\d+", f.get("refEn", ""))
        m_hy = re.match(r"(.+?) \d+:\d+", f.get("refHy", ""))
        m_ru = re.match(r"(.+?) \d+:\d+", f.get("refRu", ""))
        if m_en and m_hy and m_ru:
            names.setdefault(m_en.group(1), (m_hy.group(1), m_ru.group(1)))
    old_spans = [s for s in (span_of(f["refEn"]) for f in old) if s]

    def overlaps(span):
        return any(s[0] == span[0] and s[1] == span[1] and not (s[3] < span[2] or s[2] > span[3]) for s in old_spans)

    def ref_names(short):
        bid, nhy, nru, nen = books[short]
        if short == "Ps":
            return bid, "Սաղմոսներ", "Псалом", "Psalm"
        if nen in names:
            return bid, names[nen][0], names[nen][1], nen
        return bid, nhy, nru, nen

    def fetch(bid, ch, a, b):
        rows = db.execute(
            "select text_hy, text_hy_ararat, text_ru, text_en from verses where book_id=? and chapter=? and verse between ? and ? order by verse",
            (bid, ch, a, b),
        ).fetchall()
        if len(rows) != b - a + 1:
            return None
        t = {
            "hy": clean(" ".join(r[0] for r in rows)),
            "ar": clean(" ".join((r[1] or "") for r in rows)),
            "ru": clean(" ".join(r[2] for r in rows)),
            "en": clean(" ".join(r[3] for r in rows)),
        }
        return t if all(t.values()) else None

    skipped = []
    taken = []
    seen = set()

    for raw in re.split(r"[;\n]+", REFS):
        raw = raw.strip()
        if not raw:
            continue
        m = re.match(r"(\w+) (\d+):(\d+)(?:-(\d+))?$", raw)
        short, ch, a, b = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4) or m.group(3))
        if short not in books:
            skipped.append((raw, "нет такой книги"))
            continue
        bid, n_hy, n_ru, n_en = ref_names(short)
        a0, b0 = a, b
        t = None
        for _ in range(8):
            t = fetch(bid, ch, a, b)
            if not t:
                break
            if t["ru"].rstrip()[-1] in ",:;—-" and b - b0 < 3:
                b += 1  # отрывок обрывался посреди предложения
                continue
            break
        if not t:
            skipped.append((raw, "нет стихов в базе"))
            continue
        if re.search(r"\b(Heb|Gr|Or)\.\s|\(см\.|[\[\]{}]", " ".join(t.values())):
            skipped.append((raw, "пометки или скобки"))
            continue
        # Стих в русской и английской колонках часто обрывается на «:» или «;», потому что предложение идёт дальше.
        # Если дочитать не удалось, ставим точку; запятая означает, что мысль не закончена.
        stop = False
        for lang in ("ru", "en"):
            if t[lang][-1] == ",":
                skipped.append((raw, "обрывается на запятой"))
                stop = True
                break
            t[lang] = re.sub(r"[:;]$", ".", t[lang])
            t[lang] = re.sub(r"^(\W*)(\w)", lambda mm: mm.group(1) + mm.group(2).upper(), t[lang])
        if stop:
            continue
        if t["ru"].count("«") != t["ru"].count("»") or t["ru"].count("(") != t["ru"].count(")") or t["en"].count("(") != t["en"].count(")"):
            skipped.append((raw, "кавычки или скобки не закрыты"))
            continue
        t["ru"] = trim_lead(t["ru"], LEAD_WORDS["ru"])
        t["en"] = trim_lead(t["en"], LEAD_WORDS["en"])
        t["hy"] = trim_lead(t["hy"], LEAD_WORDS["hy"])
        t["ar"] = trim_lead(t["ar"], LEAD_WORDS["hy"])
        L = [len(t["ar"]), len(t["ru"]), len(t["en"])]
        if not (0.55 <= L[0] / L[1] <= 1.6) or not (0.6 <= L[2] / L[1] <= 1.8):
            skipped.append((raw, f"длины расходятся {L}: возможно сдвиг нумерации"))
            continue
        if max(L) > MAX_LEN or max(L) < MIN_LEN:
            skipped.append((raw, f"длина {L} не подходит среднему и большому"))
            continue
        rng = f"{a}-{b}" if b != a else f"{a}"
        item = {
            "textHy": t["hy"], "textHyArarat": t["ar"], "textRu": t["ru"], "textEn": t["en"],
            "refHy": f"{n_hy} {ch}:{rng}",
            "refRu": f"{n_ru} {ch if short != 'Ps' else psalm_ru(ch)}:{rng}",
            "refEn": f"{n_en} {ch}:{rng}",
            "len": L,
        }
        if item["refEn"] in EXCLUDE:
            skipped.append((raw, "исключено вручную"))
            continue
        if overlaps(span_of(item["refEn"])) or item["refEn"] in seen:
            skipped.append((raw, "уже есть в других подборках"))
            continue
        seen.add(item["refEn"])
        taken.append(item)

    print(f"цитат в библиотеке: {len(taken)}")
    for raw, why in skipped:
        print("  пропущено", raw, "-", why)
    if mode == "report":
        for it in taken:
            print(f"{it['refEn']:20s} {it['len']} | {it['textRu']}")
        return

    def lit(s):
        return json.dumps(s, ensure_ascii=False)

    lines = [
        "import Foundation",
        "",
        "// Сгенерировано Tools/QuoteLibrary/build_library.py из Sources/bible.db. Не править вручную: список мест и правила — в скрипте.",
        "extension BibleVerse {",
        "    /// Цельные отрывки Писания разной длины для среднего и большого виджета (входят в общую базу `database`)",
        "    static let libraryQuotes: [BibleVerse] = [",
    ]
    for it in taken:
        lines += [
            "        BibleVerse(",
            f"            textHy: {lit(it['textHy'])},",
            f"            textHyArarat: {lit(it['textHyArarat'])},",
            f"            textRu: {lit(it['textRu'])},",
            f"            textEn: {lit(it['textEn'])},",
            f"            refHy: {lit(it['refHy'])},",
            f"            refRu: {lit(it['refRu'])},",
            f"            refEn: {lit(it['refEn'])}",
            "        ),",
        ]
    lines += ["    ]", "}"]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("записано:", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "report")

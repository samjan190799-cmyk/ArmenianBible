"""Собирает из prayers.py два файла Swift:
  Sources/NarekatsiInspired.swift                  — тексты молитв 6–15 (подставляются вместо повторяющихся в NarekatsiDatabase)
  Sources/BibleVerseDatabase+NarekInspired.swift   — строки и строфы этих молитв для виджетов (подпись «в духе Нарекаци»)

Запуск из корня репозитория:
    python -I Tools/NarekInspired/build_inspired.py report   # длины строк, ничего не записывая
    python -I Tools/NarekInspired/build_inspired.py write
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prayers import PRAYERS, SHORT_LINES  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT_PRAYERS = ROOT / "Sources" / "NarekatsiInspired.swift"
OUT_VERSES = ROOT / "Sources" / "BibleVerseDatabase+NarekInspired.swift"

REF = {"hy": "Նարեկացու ոգով", "ru": "В духе Нарекаци", "en": "In the spirit of Narekatsi"}
STOP = {"hy": "։", "ru": ".", "en": "."}
LEAD = {"hy": ("Եւ ",), "ru": ("И ",), "en": ("And ",)}


def lit(s):
    return json.dumps(s, ensure_ascii=False)


def close(text, lang):
    """Запятая или двоеточие в конце → точка (по-армянски «։»)"""
    text = text.rstrip()
    if text and text[-1] in ",;:":
        text = text[:-1]
    if not text.endswith(STOP[lang]) and text[-1] not in ".!?»։":
        text += STOP[lang]
    return text


def trim_lead(text, lang):
    for w in LEAD[lang]:
        if text.startswith(w):
            rest = text[len(w):]
            return rest[0].upper() + rest[1:]
    return text


def stanza_text(stanza, lang):
    lines = list(stanza[lang])
    lines[-1] = close(lines[-1], lang)
    return "\n".join(lines)


def prayer_text(prayer, lang):
    return "\n\n".join(stanza_text(s, lang) for s in prayer["stanzas"])


def verse(texts):
    return [
        "        BibleVerse(",
        f"            textHy: {lit(texts['hy'])},",
        f"            textRu: {lit(texts['ru'])},",
        f"            textEn: {lit(texts['en'])},",
        f"            refHy: {lit(REF['hy'])},",
        f"            refRu: {lit(REF['ru'])},",
        f"            refEn: {lit(REF['en'])}",
        "        ),",
    ]


def main(mode):
    sys.stdout.reconfigure(encoding="utf-8")
    by_id = {p["id"]: p for p in PRAYERS}

    # --- короткие строки
    short = []
    for pid, si, li in SHORT_LINES:
        st = by_id[pid]["stanzas"][si]
        texts = {}
        for lang in ("hy", "ru", "en"):
            texts[lang] = close(trim_lead(st[lang][li], lang), lang)
        short.append((pid, texts))

    # --- строфы: каждая строфа отдельно и молитва целиком
    stanzas = []
    for p in PRAYERS:
        for st in p["stanzas"]:
            stanzas.append({lang: stanza_text(st, lang) for lang in ("hy", "ru", "en")})
        stanzas.append({lang: "\n".join(stanza_text(st, lang) for st in p["stanzas"]) for lang in ("hy", "ru", "en")})

    print(f"молитв: {len(PRAYERS)}, коротких строк: {len(short)}, строф: {len(stanzas)}")
    print("короткие строки (hy, ru, en):")
    for pid, t in short:
        print(f"  {pid:2d} ({len(t['hy']):2d}, {len(t['ru']):2d}, {len(t['en']):2d}) {t['ru']} | {t['en']}")
    print("длины строф (hy, ru, en):", [(len(s['hy']), len(s['ru']), len(s['en'])) for s in stanzas][:12], "…")
    if mode == "report":
        return

    # --- молитвы
    lines = [
        "import Foundation",
        "",
        "// Сгенерировано Tools/NarekInspired/build_inspired.py из prayers.py. Не править вручную.",
        "// Молитвы 6–15 «в духе Нарекаци»: они заменяют тексты, которые раньше повторяли пять первых молитв по кругу.",
        "// Это не дословный текст «Книги скорбных песнопений»; в приложении они так и подписаны.",
        "enum NarekatsiInspired {",
        "    struct Entry {",
        "        let titleHy: String",
        "        let titleRu: String",
        "        let titleEn: String",
        "        let textHy: String",
        "        let textRu: String",
        "        let textEn: String",
        "    }",
        "",
        "    static let entries: [Int: Entry] = [",
    ]
    for p in PRAYERS:
        lines += [
            f"        {p['id']}: Entry(",
            f"            titleHy: {lit(p['title']['hy'])},",
            f"            titleRu: {lit(p['title']['ru'])},",
            f"            titleEn: {lit(p['title']['en'])},",
            f"            textHy: {lit(prayer_text(p, 'hy'))},",
            f"            textRu: {lit(prayer_text(p, 'ru'))},",
            f"            textEn: {lit(prayer_text(p, 'en'))}",
            "        ),",
        ]
    lines += [
        "    ]",
        "",
        "    /// Подставляет собственный текст, если он есть; номер, подпись главы и ссылки на запись остаются прежними",
        "    static func apply(to prayer: NarekPrayer) -> NarekPrayer {",
        "        guard let entry = entries[prayer.id] else { return prayer }",
        "        return NarekPrayer(",
        "            id: prayer.id,",
        "            banNumber: prayer.banNumber,",
        '            titleHy: "\\(entry.titleHy) (\\(prayer.banNumber))",',
        '            titleRu: "\\(entry.titleRu) (Глава \\(prayer.id))",',
        '            titleEn: "\\(entry.titleEn) (Chapter \\(prayer.id))",',
        "            textHy: entry.textHy,",
        "            textRu: entry.textRu,",
        "            textEn: entry.textEn,",
        "            audioUrlHy: prayer.audioUrlHy,",
        "            audioUrlRu: prayer.audioUrlRu",
        "        )",
        "    }",
        "}",
    ]
    OUT_PRAYERS.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # --- строки и строфы для виджетов
    v = [
        "import Foundation",
        "",
        "// Сгенерировано Tools/NarekInspired/build_inspired.py из prayers.py. Не править вручную.",
        "// Строки и строфы молитв 6–15 «в духе Нарекаци» (NarekatsiInspired.swift) для виджетов и «Слова дня».",
        "extension BibleVerse {",
        "    /// Все подборки Нарекаци: прежние (BibleVerseDatabase.swift) и строки и строфы молитв 6–15",
        "    static let shortNarekatsi: [BibleVerse] = shortNarekatsiBase + narekInspiredLines",
        "    static let narekStanzas: [BibleVerse] = narekStanzasBase + narekInspiredStanzas",
        "",
        "    /// Короткие строки (экран блокировки, малый виджет); каждая — строка одной из молитв, по ней приложение находит молитву",
        "    static let narekInspiredLines: [BibleVerse] = [",
    ]
    for _, t in short:
        v += verse(t)
    v += ["    ]", "", "    /// Строфы по две строки и молитвы целиком (средний и большой виджет)", "    static let narekInspiredStanzas: [BibleVerse] = ["]
    for t in stanzas:
        v += verse(t)
    v += ["    ]", "}"]
    OUT_VERSES.write_text("\n".join(v) + "\n", encoding="utf-8")
    print("записано:", OUT_PRAYERS.relative_to(ROOT), OUT_VERSES.relative_to(ROOT))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "report")

import os

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

hy_text = """«Luys: Armenian Bible» — ոգեշնչող հոգևոր հավելված, որը բերում է Աստծո Խոսքը ձեր iPhone-ի Կողպեքրանին (Lock Screen) և Գլխավոր էկրանին:

✨ ԱՌԱՆՁՆԱՀԱՏԿՈՒԹՅՈՒՆՆԵՐԸ.
• Կողպեքրանի Վիդջեթներ — Աստվածաշնչի ոգեշնչող տողեր ամեն ժամ ավտոմատ թարմացմամբ և սինխրոնացմամբ:
• Ամբողջական Սուրբ Գիրք — Հին և Նոր Կտակարանների բոլոր գրքերը (Արարատ և Էջմիածնի թարգմանություններ):
• Գրիգոր Նարեկացի՝ «Մատյան Ողբերգության» — Բոլոր 95 գլուխները ստուդիական աուդիոյով (Սոս Սարգսյան և Օլեգ Մոլենկո):
• ԱԲ Հոգևոր Օգնական (AI Guide) — Հարցեր և մեկնաբանություններ (Gemini, ChatGPT, Claude):
• Աստվածաշնչյան Վիկտորինա — Ինտերակտիվ թեստեր գիտելիքների ստուգման համար:
• Հոգևոր Բացիկներ և Էջանիշեր — Գեղեցիկ քարտերի ստեղծում և տողերի պահպանում:
• 100% Անցանց և Գաղտնի — Աշխատում է առանց ինտերնետի, առանց գովազդի և տվյալների հավաքագրման:"""

en_text = """\"Luys: Armenian Bible\" brings the inspiring Word of God directly to your iOS Lock Screen and Home Screen.

✨ KEY FEATURES:
• Lock Screen Widgets — Daily Bible verses with automatic hourly updates and sync.
• Complete Holy Bible — Old & New Testaments in Armenian, English, and Russian.
• Saint Gregory of Narek — Book of Lamentations — Full 95 chapters with studio audio recitations (Sos Sargsyan & Oleg Molenko).
• AI Spiritual Guide — Deep biblical reflections powered by Gemini, ChatGPT, and Claude.
• Bible Quiz & Trivia — Strengthen your faith with interactive knowledge tests.
• Spiritual Postcards & Bookmarks — Create elegant quote cards and save favorite verses.
• 100% Offline & Private — No tracking, no ads, works fully offline."""

ru_text = """«Luys: Armenian Bible» — вдохновляющие строки Священного Писания прямо на Экране блокировки (Lock Screen) и Главном экране вашего iPhone.

✨ ГЛАВНЫЕ ВОЗМОЖНОСТИ:
• Виджеты экрана блокировки — Библейские стихи с автоматическим обновлением каждый час.
• Полный текст Библии — Ветхий и Новый Завет на армянском, русском и английском языках.
• Григор Нарекаци — «Книга скорбных песнопений» — Все 95 глав со студийной озвучкой (Сос Саргсян и Олег Моленко).
• ИИ-помощник (AI Guide) — Духовные ответы и толкования (Gemini, ChatGPT, Claude).
• Библейская викторина — Интерактивные тесты на знание Священного Писания.
• Духовные открытки и закладки — Создание красивых карточек и поиск по текстам.
• 100% Оффлайн и Конфиденциальность — Без интернета, рекламы и сбора данных."""

combined_desc = f"""🇦🇲 ՀԱՅԵՐԵՆ:
{hy_text}

─────────────────────────
🇬🇧 ENGLISH:
{en_text}

─────────────────────────
🇷🇺 РУССКИЙ:
{ru_text}"""

print(f"Total length: {len(combined_desc)} chars (Apple App Store limit is 4000 chars)")

# Short descriptions
hy_short = "Աստվածաշունչ, Կողպեքրանի վիդջեթ, Նարեկացի 95 գլուխ աուդիոյով և ԱԲ Օգնական:"
en_short = "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide."
ru_short = "Армянская Библия, виджет локскрина, 95 глав Нарекаци с аудио и ИИ-помощник."

promo_hy = "Աստվածաշնչի ոգեշնչող տողեր ձեր iPhone-ի կողպեքրանին ամեն օր:"
promo_en = "Daily inspiring Bible verses directly on your iPhone Lock Screen!"
promo_ru = "Вдохновляющие стихи из Библии на экране блокировки вашего iPhone каждый день!"

keywords_en = "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz"
keywords_hy = "աստվածաշունչ,նարեկացի,վիդջեթ,աղոթք,հայերեն,սուրբ գիրք,նարեկ,քրիստոնեություն,լույս"
keywords_ru = "библия,армянская библия,нарекаци,виджет,локскрин,молитва,нарек,стих дня,христианство"

locales_ios = {
    "en-US": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & Widget",
        "description.txt": combined_desc,
        "keywords.txt": keywords_en,
        "promotional_text.txt": promo_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "default": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & Widget",
        "description.txt": combined_desc,
        "keywords.txt": keywords_en,
        "promotional_text.txt": promo_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "hy": {
        "name.txt": "Luys: Աստվածաշունչ և Վիդջեթ",
        "subtitle.txt": "Սուրբ Գիրք, Նարեկացի և Վիդջեթ",
        "description.txt": hy_text,
        "keywords.txt": keywords_hy,
        "promotional_text.txt": promo_hy,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "ru": {
        "name.txt": "Luys: Армянская Библия",
        "subtitle.txt": "Библия, Нарекаци и Виджет",
        "description.txt": ru_text,
        "keywords.txt": keywords_ru,
        "promotional_text.txt": promo_ru,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    }
}

for loc, files in locales_ios.items():
    loc_dir = os.path.join(base_dir, "fastlane", "metadata", loc)
    os.makedirs(loc_dir, exist_ok=True)
    for fname, content in files.items():
        fpath = os.path.join(loc_dir, fname)
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(content.strip() + "\n")

locales_android = {
    "en-US": {
        "title.txt": "Luys: Armenian Bible & Widget",
        "short_description.txt": en_short,
        "full_description.txt": combined_desc
    },
    "hy-AM": {
        "title.txt": "Luys: Աստվածաշունչ և Վիդջեթ",
        "short_description.txt": hy_short,
        "full_description.txt": hy_text
    },
    "ru-RU": {
        "title.txt": "Luys: Армянская Библия",
        "short_description.txt": ru_short,
        "full_description.txt": ru_text
    }
}

for loc, files in locales_android.items():
    loc_dir = os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", loc)
    os.makedirs(loc_dir, exist_ok=True)
    for fname, content in files.items():
        fpath = os.path.join(loc_dir, fname)
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(content.strip() + "\n")

print("Fastlane metadata generated successfully.")

import os
import sys
import shutil

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

# --- Тексты описаний ---
hy_text = """«Luys: Armenian Bible» — ոգեշնչող հոգևոր հավելված, որը բերում է Աստծո Խոսքը ձեր iPhone-ի Կողպեքրանին (Lock Screen) և Գլխավոր էկրանին:

✨ ԱՌԱՆՁՆԱՀԱՏԿՈՒԹՅՈՒՆՆԵՐԸ.
• Կողպեքրանի Վիդջեթներ — Աստվածաշնչի ոգեշնչող տողեր ամեն ժամ ավտոմատ թարմացմամբ և անկախ ռոտացիայով:
• Ամբողջական Սուրբ Գիրք — Հին և Նոր Կտակարանների բոլոր գրքերը (Արարատ և Էջմիածնի թարգմանություններ):
• Գրիգոր Նարեկացի՝ «Մատյան Ողբերգության» — Բոլոր 95 գլուխները ստուդիական աուդիոյով (Սոս Սարգսյան և Օլեգ Մոլենկո):
• ԱԲ Հոգևոր Օգնական (AI Guide) — Խորը մեկնաբանություններ և պատասխաններ (Gemini, ChatGPT, Claude):
• Աստվածաշնչյան Վիկտորինա — Ինտերակտիվ թեստեր գիտելիքների ամրապնդման համար:
• Հոգևոր Պաստառներ և Էջանիշեր — Բացառիկ հայկական խաչքարերով պաստառների ստեղծում:
• 100% Անցանց և Գաղտնի — Աշխատում է առանց ինտերնետի, առանց գովազդի և տվյալների հավաքագրման:"""

en_text = """\"Luys: Armenian Bible\" brings the inspiring Word of God directly to your iOS Lock Screen and Home Screen.

✨ KEY FEATURES:
• Lock Screen & Home Widgets — Inspiring Bible verses with automatic hourly updates and independent rotation.
• Complete Holy Bible — Old & New Testaments in Armenian, English, and Russian.
• Saint Gregory of Narek — Book of Lamentations — Full 95 chapters with studio audio recitations (Sos Sargsyan & Oleg Molenko).
• AI Spiritual Guide — Deep biblical reflections powered by Gemini, ChatGPT, and Claude.
• Bible Quiz & Trivia — Strengthen your faith with interactive knowledge tests.
• Spiritual Wallpapers & Bookmarks — Create elegant quote cards with ancient Armenian khachkars.
• 100% Offline & Private — No tracking, no ads, works fully offline."""

ru_text = """«Luys: Armenian Bible» — вдохновляющие строки Священного Писания прямо на Экране блокировки (Lock Screen) и Главном экране вашего iPhone.

✨ ГЛАВНЫЕ ВОЗМОЖНОСТИ:
• Виджеты экрана блокировки и экрана «Домой» — Библейские стихи с автообновлением каждый час и независимой ротацией.
• Полный текст Библии — Ветхий и Новый Завет на армянском, русском и английском языках.
• Григор Нарекаци — «Книга скорбных песнопений» — Все 95 глав со студийной озвучкой (Сос Саргсян и Олег Моленко).
• ИИ-помощник (AI Guide) — Духовные ответы и толкования (Gemini, ChatGPT, Claude).
• Библейская викторина — Интерактивные тесты на знание Священного Писания.
• Духовные обои и открытки — Создание премиальных карточек со стихами дня и древними хачкарами.
• 100% Оффлайн и Конфиденциальность — Без интернета, рекламы и сбора данных."""

combined_desc = f"""🇦🇲 ՀԱՅԵՐԵՆ:
{hy_text}

─────────────────────────
🇬🇧 ENGLISH:
{en_text}

─────────────────────────
🇷🇺 РУССКИЙ:
{ru_text}"""

# Краткие описания (Google Play <= 80 chars)
hy_short = "Աստվածաշունչ, Կողպեքրանի վիդջեթ, Նարեկացի 95 գլուխ աուդիոյով և ԱԲ Օգնական:"
en_short = "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide."
ru_short = "Армянская Библия, виджет локскрина, 95 глав Нарекаци с аудио и ИИ-помощник."

# Промо-текст (App Store <= 170 chars)
promo_hy = "Աստվածաշնչի ոգեշնչող տողեր ձեր iPhone-ի կողպեքրանին ամեն օր:"
promo_en = "Daily inspiring Bible verses directly on your iPhone Lock Screen!"
promo_ru = "Вдохновляющие стихи из Библии на экране блокировки вашего iPhone каждый день!"

# Ключевые слова (App Store <= 100 chars)
keywords_en = "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz"
keywords_hy = "աստվածաշունչ,նարեկացի,վիդջեթ,աղոթք,հայերեն,սուրբ գիրք,նարեկ,քրիստոնեություն,լույս"
keywords_ru = "библия,армянская библия,нарекаци,виджет,локскрин,молитва,нарек,стих дня,христианство"

# Что нового (Release notes / Changelog)
whats_new_en = """- Armenian Bible Premium: StoreKit 2 subscriptions & Grandfathering for early adopters
- Saint Gregory of Narek: Complete 95 audio chapters with studio narrations
- AI Spiritual Guide: Deep biblical reflections & interpretations
- Lock Screen & Home Screen widgets: High-legibility typography and independent verse rotation
- Spiritual Wallpapers: Exclusive Armenian Christian wallpapers & khachkars"""

whats_new_hy = """- Armenian Bible Premium: Բաժանորդագրություն և անվճար հասանելիություն նախկին գնորդների համար
- Գրիգոր Նարեկացի «Մատյան Ողբերգության»՝ Բոլոր 95 գլուխները ստուդիական աուդիոյով
- ԱԲ Հոգևոր Օգնական՝ Աստվածաշնչի մեկնաբանություններ և պատասխաններ
- Կողպեքրանի և Գլխավոր էկրանի վիդջեթների խոշոր տառատեսակներ և անկախ ռոտացիա
- Հոգևոր Պաստառներ՝ Բացառիկ հայկական խաչքարեր և ֆոներ"""

whats_new_ru = """- Armenian Bible Premium: Подписки StoreKit 2 и пожизненный Premium для ранних покупателей
- Григор Нарекаци «Книга скорбных песнопений»: Все 95 глав со студийной озвучкой
- Духовный ИИ-помощник: Ответы на вопросы веры и толкования Священного Писания
- Виджеты экрана блокировки и Главного экрана: Крупный четкий шрифт и независимая ротация
- Духовные обои: Эксклюзивные армянские фоны с древними хачкарами и стихом дня"""

whats_new_combined = f"""{whats_new_en}

{whats_new_hy}

{whats_new_ru}"""

# --- Генерация метаданных для iOS (Fastlane) ---
locales_ios = {
    "en-US": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & Widget",
        "description.txt": combined_desc,
        "keywords.txt": keywords_en,
        "promotional_text.txt": promo_en,
        "release_notes.txt": whats_new_en,
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
        "release_notes.txt": whats_new_combined,
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
        "release_notes.txt": whats_new_hy,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "ru": {
        "name.txt": "Luys: Армянская Библия",
        "subtitle.txt": "Библия, Нарекаци и Виджеты",
        "description.txt": ru_text,
        "keywords.txt": keywords_ru,
        "promotional_text.txt": promo_ru,
        "release_notes.txt": whats_new_ru,
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

# --- Генерация метаданных для Android (Google Play) ---
locales_android = {
    "en-US": {
        "title.txt": "Luys: Armenian Bible & Widget",
        "short_description.txt": en_short,
        "full_description.txt": combined_desc,
        "changelog": whats_new_en
    },
    "hy-AM": {
        "title.txt": "Luys: Աստվածաշունչ և Վիդջեթ",
        "short_description.txt": hy_short,
        "full_description.txt": hy_text,
        "changelog": whats_new_hy
    },
    "ru-RU": {
        "title.txt": "Luys: Армянская Библия",
        "short_description.txt": ru_short,
        "full_description.txt": ru_text,
        "changelog": whats_new_ru
    }
}

for loc, data in locales_android.items():
    loc_dir = os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", loc)
    os.makedirs(loc_dir, exist_ok=True)
    
    with open(os.path.join(loc_dir, "title.txt"), "w", encoding="utf-8") as f:
        f.write(data["title.txt"].strip() + "\n")
    with open(os.path.join(loc_dir, "short_description.txt"), "w", encoding="utf-8") as f:
        f.write(data["short_description.txt"].strip() + "\n")
    with open(os.path.join(loc_dir, "full_description.txt"), "w", encoding="utf-8") as f:
        f.write(data["full_description.txt"].strip() + "\n")
        
    changelogs_dir = os.path.join(loc_dir, "changelogs")
    os.makedirs(changelogs_dir, exist_ok=True)
    for c_name in ["default.txt", "12.txt"]:
        with open(os.path.join(changelogs_dir, c_name), "w", encoding="utf-8") as f:
            f.write(data["changelog"].strip() + "\n")

# --- Синхронизация скриншотов в Android phoneScreenshots ---
screenshot_names = [
    "01_lockscreen_widget.png",
    "02_home_daily_verse.png",
    "03_favorites_highlights.png",
    "04_spiritual_ai_assistant.png",
    "05_bible_reader.png",
    "06_narekatsi_audio_ru.png",
    "07_narekatsi_audio_hy.png",
    "08_narekatsi_text.png",
    "09_bible_library_books.png"
]

src_screenshots_dir = os.path.join(base_dir, "screenshots")

for loc in locales_android.keys():
    target_img_dir = os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", loc, "images", "phoneScreenshots")
    os.makedirs(target_img_dir, exist_ok=True)
    for s_name in screenshot_names:
        src_file = os.path.join(src_screenshots_dir, s_name)
        if os.path.exists(src_file):
            shutil.copy2(src_file, os.path.join(target_img_dir, s_name))

print("DONE: All Fastlane metadata generated successfully.")

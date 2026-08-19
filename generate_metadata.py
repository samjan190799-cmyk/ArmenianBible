import os

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

hy_text = """«Luys: Armenian Bible» — ոգեշնչող, ժամանակակից և հոգևոր հավելված, որը բերում է Աստծո Խոսքը անմիջապես ձեր iPhone-ի Կողպեքրանին (Lock Screen) և Գլխավոր էկրանին (Home Screen):

✨ ՀԻՄՆԱԿԱՆ ԱՌԱՆՁՆԱՀԱՏԿՈՒԹՅՈՒՆՆԵՐԸ.
• Կողպեքրանի և Գլխավոր էկրանի Վիդջեթներ — Աստվածաշնչի ոգեշնչող տողերը միշտ ձեր աչքի առաջ են: Յուրաքանչյուր ժամ տողի ավտոմատ թարմացում և ակնթարթային սինխրոնացում:
• Ամբողջական Սուրբ Գիրք — Հին և Նոր Կտակարանների բոլոր գրքերը հայերենով (Արարատ և Էջմիածնի թարգմանություններ):
• Գրիգոր Նարեկացի՝ «Մատյան Ողբերգության» (Նարեկ) — Բոլոր 95 Բաները (գլուխները) բնօրինակ գրաբարով, աշխարհաբարով և պրոֆեսիոնալ ստուդիական աուդիո ձայնագրություններով (Սոս Սարգսյանի և Օլեգ Մոլենկոյի ընթերցմամբ):
• Արհեստական Բանականությամբ Հոգևոր Օգնական (AI Bible Guide) — Խորհրդակցեք առաջատար ԱԲ մոդելների հետ (Gemini, ChatGPT, Claude)՝ աստվածաշնչյան տեքստերի մեկնաբանությունների և հոգևոր հարցերի շուրջ:
• Աստվածաշնչյան Վիկտորինա (Bible Quiz) — Ստուգեք և խորացրեք ձեր գիտելիքները Սուրբ Գրքի վերաբերյալ ինտերակտիվ թեստերի միջոցով:
• Հոգևոր Բացիկների Ստեղծում — Կիսվեք գեղեցիկ ձևավորված տողերով և աղոթքներով սոցիալական ցանցերում:
• Էջանիշեր և Որոնում — Պահպանեք ձեր սիրելի հատվածները և ակնթարթորեն գտեք անհրաժեշտ տողերը:
• 100% Գաղտնիություն և Անցանց ռեժիմ — Ձեր տվյալները չեն հավաքվում, իսկ հիմնական գործառույթներն աշխատում են առանց ինտերնետի:"""

en_text = """"Luys: Armenian Bible" is an elegant, feature-rich Christian companion designed to bring the inspiring Word of God directly to your iOS Lock Screen and Home Screen.

✨ KEY FEATURES:
• Lock Screen & Home Screen Widgets — Keep Holy Scripture close throughout your day with beautifully designed iOS widgets that refresh automatically or on demand.
• Complete Holy Bible — Full Old and New Testaments in Armenian (Eastern, Western, Classical / Ararat & Etchmiadzin translations), English, and Russian.
• Saint Gregory of Narek — Book of Lamentations (Narek) — Complete 95 chapters with high-definition studio audio recitations (by Sos Sargsyan and Oleg Molenko) and prayer texts.
• AI Spiritual Guide — Ask questions and explore deep biblical reflections powered by advanced AI models (Gemini, ChatGPT, Claude).
• Bible Quiz & Trivia — Strengthen your faith and test your biblical knowledge with engaging quizzes across multiple difficulty levels.
• Spiritual Postcard Creator — Share inspiring scripture verses styled with elegant gradients and typography on Instagram, WhatsApp, and Telegram.
• Favorites, Search & Offline Access — Fast scripture search, bookmarking, smooth spring animations, haptic feedback, and full offline functionality.
• Privacy First — No accounts, no data tracking, and no ads."""

ru_text = """«Luys: Armenian Bible» — это современное, элегантное и духовное приложение, созданное для того, чтобы вдохновляющие строки Священного Писания всегда были перед вашими глазами на Экране блокировки (Lock Screen) и Главном экране вашего iPhone.

✨ ГЛАВНЫЕ ВОЗМОЖНОСТИ:
• Виджеты экрана блокировки и рабочего стола — Вдохновляющие стихи из Библии на локскрине с автоматическим обновлением и мгновенной синхронизацией.
• Полный текст Библии — Ветхий и Новый Завет на армянском (Эчмиадзинский и Араратский переводы), русском (Синодальный перевод) и английском языках.
• Григор Нарекаци — «Книга скорбных песнопений» (Нарек) — Все 95 Глав (Слов) великой молитвенной книги с профессиональной студийной озвучкой (чтение Соса Саргсяна и Олега Моленко).
• Интеллектуальный помощник (AI Bible Guide) — Задавайте духовные вопросы и получайте библейские толкования с помощью передовых ИИ (Gemini, ChatGPT, Claude).
• Библейская викторина (Bible Quiz) — Проверяйте и укрепляйте свои знания Священного Писания с помощью интерактивных тестов.
• Генератор духовных открыток — Создавайте красивые открытки с цитатами и делитесь ими в социальных сетях и мессенджерах.
• Избранное, поиск и оффлайн-доступ — Быстрый поиск по всей Библии и Нарекаци, закладки, тактильная отдача (Haptics) и полная автономная работа без интернета.
• Полная конфиденциальность — Никакого сбора личных данных, аккаунтов или навязчивой рекламы."""

# Combined 3-language description (Armenian -> English -> Russian)
combined_desc = f"""🇦🇲 ՀԱՅԵՐԵՆ (ARMENIAN):
{hy_text}

────────────────────────────────────────────
🇬🇧 ENGLISH:
{en_text}

────────────────────────────────────────────
🇷🇺 РУССКИЙ:
{ru_text}"""

# Short descriptions for Play Store / Subtitles
hy_short = "Աստվածաշունչ, Կողպեքրանի վիդջեթ, Նարեկացի 95 գլուխ աուդիոյով և ԱԲ Օգնական:"
en_short = "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide."
ru_short = "Армянская Библия, виджет локскрина, 95 глав Нарекаци с аудио и ИИ-помощник."

# Promotional text
promo_hy = "Աստվածաշնչի ոգեշնչող տողեր ձեր iPhone-ի կողպեքրանին ամեն օր:"
promo_en = "Daily inspiring Bible verses directly on your iPhone Lock Screen!"
promo_ru = "Вдохновляющие стихи из Библии на экране блокировки вашего iPhone каждый день!"

# Keywords (max 100 chars for Apple)
keywords_en = "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz"
keywords_hy = "աստվածաշունչ,նարեկացի,վիդջեթ,աղոթք,հայերեն,սուրբ գիրք,նարեկ,քրիստոնեություն,լույս"
keywords_ru = "библия,армянская библия,нарекаци,виджет,локскрин,молитва,нарек,стих дня,христианство"

# Metadata configs for Fastlane iOS
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

# Metadata configs for Fastlane Android
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

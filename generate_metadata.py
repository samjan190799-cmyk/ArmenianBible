import os
import sys
import shutil

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

# ==========================================
# 1. ТЕКСТЫ ОПИСАНИЙ ДЛЯ 8+ ЯЗЫКОВ И СТРАН
# ==========================================

# --- Հայերեն (Armenian) ---
hy_text = """«Luys: Armenian Bible» — ոգեշնչող հոգևոր հավելված, որը բերում է Աստծո Խոսքը ձեր iPhone-ի Կողպեքրանին (Lock Screen) և Գլխավոր էկրանին:

✨ ԱՌԱՆՁՆԱՀԱՏԿՈՒԹՅՈՒՆՆԵՐԸ.
• Կողպեքրանի Վիդջեթներ — Աստվածաշնչի ոգեշնչող տողեր ամեն ժամ ավտոմատ թարմացմամբ և անկախ ռոտացիայով:
• Ամբողջական Սուրբ Գիրք — Հին և Նոր Կտակարանների բոլոր գրքերը (Արարատ և Էջմիածնի թարգմանություններ):
• Գրիգոր Նարեկացի՝ «Մատյան Ողբերգության» — Բոլոր 95 գլուխները ստուդիական աուդիոյով (Սոս Սարգսյան և Օլեգ Մոլենկո):
• ԱԲ Հոգևոր Օգնական (AI Guide) — Խորը մեկնաբանություններ և պատասխաններ (Gemini, ChatGPT, Claude):
• Աստվածաշնչյան Վիկտորինա — Ինտերակտիվ թեստեր գիտելիքների ամրապնդման համար:
• Հոգևոր Պաստառներ և Էջանիշեր — Բացառիկ հայկական խաչքարերով պաստառների ստեղծում:
• 100% Անցանց և Գաղտնի — Աշխատում է առանց ինտերնետի, առանց գովազդի և տվյալների հավաքագրման:"""

whats_new_hy = """- Armenian Bible Premium: Բաժանորդագրություն և անվճար հասանելիություն նախկին գնորդների համար
- Գրիգոր Նարեկացի «Մատյան Ողբերգության»՝ Բոլոր 95 գլուխները ստուդիական աուդիոյով
- ԱԲ Հոգևոր Օգնական՝ Աստվածաշնչի մեկնաբանություններ և պատասխաններ
- Կողպեքրանի և Գլխավոր էկրանի վիդջեթների խոշոր տառատեսակներ և անկախ ռոտացիա
- Հոգևոր Պաստառներ՝ Բացառիկ հայկական խաչքարեր և ֆոներ"""

# --- English (USA, UK, Canada, Global) ---
en_text = """\"Luys: Armenian Bible\" brings the inspiring Word of God directly to your iOS Lock Screen and Home Screen.

✨ KEY FEATURES:
• Lock Screen & Home Widgets — Inspiring Bible verses with automatic hourly updates and independent rotation.
• Complete Holy Bible — Old & New Testaments in Armenian, English, and Russian.
• Saint Gregory of Narek — Book of Lamentations — Full 95 chapters with studio audio recitations (Sos Sargsyan & Oleg Molenko).
• AI Spiritual Guide — Deep biblical reflections powered by Gemini, ChatGPT, and Claude.
• Bible Quiz & Trivia — Strengthen your faith with interactive knowledge tests.
• Spiritual Wallpapers & Bookmarks — Create elegant quote cards with ancient Armenian khachkars.
• 100% Offline & Private — No tracking, no ads, works fully offline."""

whats_new_en = """- Armenian Bible Premium: StoreKit 2 subscriptions & Grandfathering for early adopters
- Saint Gregory of Narek: Complete 95 audio chapters with studio narrations
- AI Spiritual Guide: Deep biblical reflections & interpretations
- Lock Screen & Home Screen widgets: High-legibility typography and independent verse rotation
- Spiritual Wallpapers: Exclusive Armenian Christian wallpapers & khachkars"""

# --- Русский (Russia, CIS, Diaspora) ---
ru_text = """«Luys: Armenian Bible» — вдохновляющие строки Священного Писания прямо на Экране блокировки (Lock Screen) и Главном экране вашего iPhone.

✨ ГЛАВНЫЕ ВОЗМОЖНОСТИ:
• Виджеты экрана блокировки и экрана «Домой» — Библейские стихи с автообновлением каждый час и независимой ротацией.
• Полный текст Библии — Ветхий и Новый Завет на армянском, русском и английском языках.
• Григор Нарекаци — «Книга скорбных песнопений» — Все 95 глав со студийной озвучкой (Сос Саргсян и Олег Моленко).
• ИИ-помощник (AI Guide) — Духовные ответы и толкования (Gemini, ChatGPT, Claude).
• Библейская викторина — Интерактивные тесты на знание Священного Писания.
• Духовные обои и открытки — Создание премиальных карточек со стихами дня и древними хачкарами.
• 100% Оффлайн и Конфиденциальность — Без интернета, рекламы и сбора данных."""

whats_new_ru = """- Armenian Bible Premium: Подписки StoreKit 2 и пожизненный Premium для ранних покупателей
- Григор Нарекаци «Книга скорбных песнопений»: Все 95 глав со студийной озвучкой
- Духовный ИИ-помощник: Ответы на вопросы веры и толкования Священного Писания
- Виджеты экрана блокировки и Главного экрана: Крупный четкий шрифт и независимая ротация
- Духовные обои: Эксклюзивные армянские фоны с древними хачкарами и стихом дня"""

# --- Français (France, Belgium, Switzerland, Canada) ---
fr_text = """« Luys: Bible Arménienne » apporte la Parole inspirante de Dieu directement sur votre écran de verrouillage (Lock Screen) et l'écran d'accueil de votre iPhone.

✨ PRINCIPALES FONCTIONNALITÉS :
• Widgets pour écran de verrouillage : Versets bibliques inspirants avec mise à jour automatique toutes les heures et rotation indépendante.
• Bible Sainte Complète : Ancien et Nouveau Testament en arménien, français, anglais et russe.
• Saint Grégoire de Narek — « Le Livre des Lamentations » : Les 95 chapitres avec enregistrements audio studio.
• Guide Spirituel IA (AI Guide) : Réponses spirituelles et réflexions bibliques approfondies (Gemini, ChatGPT, Claude).
• Quiz biblique et culture : Testez et enrichissez votre foi avec des quiz interactifs.
• Fonds d'écran spirituels et khatchkars : Créez de superbes cartes avec les anciens khatchkars arméniens.
• 100% Hors-ligne et Confidentiel : Fonctionne sans connexion, sans publicité ni collecte de données."""

whats_new_fr = """- Armenian Bible Premium : Abonnements StoreKit 2 et accès à vie pour les premiers acheteurs
- Saint Grégoire de Narek : 95 chapitres audio en studio et Livre des Lamentations
- Guide Spirituel IA : Réponses et interprétations des textes sacrés
- Widgets d'écran de verrouillage et d'accueil : Typographie haute lisibilité et rotation indépendante
- Fonds d'écran spirituels : Khatchkars arméniens exclusifs et verset du jour"""

# --- Español (Spain, Argentina, Mexico, Latin America, USA) ---
es_text = """« Luys: Biblia Armenia » lleva la Palabra inspiradora de Dios directamente a tu Pantalla de bloqueo (Lock Screen) y Pantalla de inicio en tu iPhone.

✨ CARACTERÍSTICAS PRINCIPALES:
• Widgets de Pantalla de Bloqueo: Versículos bíblicos con actualización automática cada hora y rotación independiente.
• Santa Biblia Completa: Antiguo y Nuevo Testamento en armenio, español, inglés y ruso.
• San Gregorio de Narek — «Libro de las Lamentaciones»: Los 95 capítulos con audio de estudio profesional.
• Guía Espiritual IA (AI Guide): Respuestas espirituales y profundas reflexiones bíblicas (Gemini, ChatGPT, Claude).
• Trivia y Quiz Bíblico: Fortalece tu fe con cuestionarios interactivos.
• Fondos de Pantalla Espirituales y Khachkars: Crea tarjetas elegantes con antiguos jachkares armenios.
• 100% Sin Conexión y Privado: Funciona sin internet, sin anuncios y sin recopilación de datos."""

whats_new_es = """- Armenian Bible Premium: Suscripciones StoreKit 2 y acceso vitalicio para primeros compradores
- San Gregorio de Narek: 95 capítulos completos con audio de estudio
- Guía Espiritual IA: Respuestas y reflexiones sobre las Sagradas Escrituras
- Widgets de pantalla de bloqueo e inicio: Tipografía clara y rotación independiente
- Fondos de pantalla espirituales: Exclusivos jachkares armenios y versículo diario"""

# --- Deutsch (Germany, Austria, Switzerland) ---
de_text = """« Luys: Armenische Bibel » bringt das inspirierende Wort Gottes direkt auf Ihren iPhone Sperrbildschirm (Lock Screen) und Home-Bildschirm.

✨ HAUPTFUNKTIONEN:
• Sperrbildschirm-Widgets: Inspirierende Bibelverse mit stündlicher automatischer Aktualisierung und unabhängiger Rotation.
• Vollständige Heilige Schrift: Altes und Neues Testament auf Armenisch, Deutsch, Englisch und Russisch.
• Hl. Gregor von Narek — «Buch der Klagelieder»: Alle 95 Kapitel mit Studio-Audioaufnahmen.
• KI-Seelsorger (AI Guide): Geistliche Antworten und biblische Reflexionen (Gemini, ChatGPT, Claude).
• Bibel-Quiz & Wissenstest: Vertiefen Sie Ihren Glauben mit interaktiven Tests.
• Geistliche Hintergrundbilder & Khachkars: Erstellen Sie elegante Verskarten mit armenischen Chatschkaren.
• 100% Offline & Privat: Funktioniert ohne Internet, ohne Werbung und ohne Datenspeicherung."""

whats_new_de = """- Armenian Bible Premium: StoreKit 2 Abonnements und lebenslanger Zugriff für frühe Käufer
- Hl. Gregor von Narek: Alle 95 Audiokapitel in Studioqualität
- KI-Seelsorger: Antworten auf Glaubensfragen und Bibelinterpretationen
- Widgets für Sperr- und Home-Bildschirm: Große Typografie und unabhängige Versrotation
- Geistliche Wallpaper: Exklusive armenische Chatschkare und Tagesverse"""

# --- Português (Brazil, Portugal) ---
pt_text = """« Luys: Bíblia Armênia » traz a Palavra inspiradora de Deus diretamente para a Tela Bloqueada (Lock Screen) e Tela de Início do seu iPhone.

✨ PRINCIPAIS RECURSOS:
• Widgets para Tela Bloqueada: Versículos bíblicos com atualização automática de hora em hora e rotação independente.
• Bíblia Sagrada Completa: Antigo e Novo Testamento em armênio, português, inglês e russo.
• São Gregório de Narek — «Livro das Lamentações»: Todos os 95 capítulos com áudio de estúdio.
• Guia Espiritual IA (AI Guide): Respostas espirituais e reflexões bíblicas profundas (Gemini, ChatGPT, Claude).
• Quiz e Quiz Bíblico: Fortaleça sua fé com testes interativos.
• Papéis de Parede Espirituais e Khachkars: Crie belos cartões com antigos khachkars armênios.
• 100% Offline e Privado: Funciona sem internet, sem anúncios e sem coleta de dados."""

whats_new_pt = """- Armenian Bible Premium: Assinaturas StoreKit 2 e acesso vitalício para primeiros compradores
- São Gregório de Narek: 95 capítulos completos em áudio de estúdio
- Guia Espiritual IA: Respostas e reflexões sobre as Escrituras
- Widgets para tela bloqueada e inicial: Tipografia clara e rotação independente
- Papéis de parede espirituais: Khachkars armênios exclusivos e versículo do dia"""

# --- العربية (Middle East, Lebanon, Syria, UAE, Egypt) ---
ar_text = """تطبيق « Luys: Armenian Bible » يجلب كلمة الله الملهمة مباشرة إلى شاشة القفل (Lock Screen) والشاشة الرئيسية لجهاز iPhone الخاص بك.

✨ الميزات الرئيسية:
• ودجات شاشة القفل: آيات ملهمة مع تحديث تلقائي كل ساعة وتدوير مستقل.
• الكتاب المقدس الكامل: العهدين القديم والجديد باللغات الأرمنية والعربية والإنجليزية والروسية.
• القديس غريغور ناريكاتسي — «كتاب المراثي»: جميع الفصول الـ 95 مع تسجيلات صوتية استوديو.
• المرشد الروحي بالذكاء الاصطناعي (AI Guide): إجابات وتأملات كتابية عميقة.
• مسابقات واختبارات الكتاب المقدس: اختبر معلوماتك وعزز إيمانك.
• خلفيات روحية وخشكار: بطاقات اقتباس أنيقة مع شواهد الخشكار الأرمنية القديمة.
• 100% بدون إنترنت وخصوصية تامة: يعمل بدون شبكة، بدون إعلانات ولا جمع بيانات."""

whats_new_ar = """- Armenian Bible Premium: اشتراكات StoreKit 2 ووصول مدى الحياة للمشترين الأوائل
- القديس غريغور ناريكاتسي: جميع الفصول الـ 95 بتسجيلات صوتية استوديو
- المرشد الروحي بالذكاء الاصطناعي: تأملات وإجابات على أسئلة الإيمان
- ودجات شاشة القفل والشاشة الرئيسية: خطوط واضحة وتدوير مستقل للآيات
- خلفيات روحية: شواهد خشكار أرمنية حصرية مع آية اليوم"""

# Объединенное описание для default / en-US
combined_desc = f"""🇦🇲 ՀԱՅԵՐԵՆ:
{hy_text}

─────────────────────────
🇬🇧 ENGLISH:
{en_text}

─────────────────────────
🇷🇺 РУССКИЙ:
{ru_text}"""

whats_new_combined = f"""{whats_new_en}

{whats_new_hy}

{whats_new_ru}"""

# ==========================================
# 2. МЕТАДАННЫЕ ДЛЯ APPLE APP STORE (FASTLANE)
# ==========================================

locales_ios = {
    "default": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & AI",
        "description.txt": combined_desc,
        "keywords.txt": "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz",
        "promotional_text.txt": "Daily inspiring Bible verses directly on your iPhone Lock Screen and Home Screen!",
        "release_notes.txt": whats_new_combined,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "en-US": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & AI",
        "description.txt": en_text,
        "keywords.txt": "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz",
        "promotional_text.txt": "Daily inspiring Bible verses directly on your iPhone Lock Screen and Home Screen!",
        "release_notes.txt": whats_new_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "en-GB": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & AI",
        "description.txt": en_text,
        "keywords.txt": "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz",
        "promotional_text.txt": "Daily inspiring Bible verses directly on your iPhone Lock Screen and Home Screen!",
        "release_notes.txt": whats_new_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "en-CA": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & AI",
        "description.txt": en_text,
        "keywords.txt": "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz",
        "promotional_text.txt": "Daily inspiring Bible verses directly on your iPhone Lock Screen and Home Screen!",
        "release_notes.txt": whats_new_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "en-AU": {
        "name.txt": "Luys: Armenian Bible & Widget",
        "subtitle.txt": "Holy Bible, Narekatsi & AI",
        "description.txt": en_text,
        "keywords.txt": "bible,armenian bible,astvatsashunch,lock screen widget,narek,narekatsi,christian,verse,widget,quiz",
        "promotional_text.txt": "Daily inspiring Bible verses directly on your iPhone Lock Screen and Home Screen!",
        "release_notes.txt": whats_new_en,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "hy": {
        "name.txt": "Luys: Աստվածաշունչ և Վիդջեթ",
        "subtitle.txt": "Սուրբ Գիրք, Նարեկացի և ԱԲ",
        "description.txt": hy_text,
        "keywords.txt": "աստվածաշունչ,նարեկացի,վիդջեթ,աղոթք,հայերեն,սուրբ գիրք,նարեկ,քրիստոնեություն,լույս",
        "promotional_text.txt": "Աստվածաշնչի ոգեշնչող տողեր ձեր iPhone-ի կողպեքրանին ամեն օր:",
        "release_notes.txt": whats_new_hy,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "ru": {
        "name.txt": "Luys: Армянская Библия",
        "subtitle.txt": "Библия, Нарекаци и ИИ",
        "description.txt": ru_text,
        "keywords.txt": "библия,армянская библия,нарекаци,виджет,локскрин,молитва,нарек,стих дня,христианство",
        "promotional_text.txt": "Вдохновляющие стихи из Библии на экране блокировки вашего iPhone каждый день!",
        "release_notes.txt": whats_new_ru,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "fr-FR": {
        "name.txt": "Luys: Bible Arménienne Widget",
        "subtitle.txt": "Sainte Bible, Narek et IA",
        "description.txt": fr_text,
        "keywords.txt": "bible,bible armenienne,narek,widget ecran verrouille,verset du jour,eglise armenienne,priere,chretien",
        "promotional_text.txt": "Des versets bibliques inspirants chaque jour sur votre écran de verrouillage iPhone !",
        "release_notes.txt": whats_new_fr,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "es-ES": {
        "name.txt": "Luys: Biblia Armenia y Widget",
        "subtitle.txt": "Santa Biblia, Narekatsi e IA",
        "description.txt": es_text,
        "keywords.txt": "biblia,biblia armenia,narek,narekatsi,widget pantalla de bloqueo,versiculo,oracion,cristiano,iglesia",
        "promotional_text.txt": "¡Versículos bíblicos inspiradores directamente en tu pantalla de bloqueo de iPhone cada día!",
        "release_notes.txt": whats_new_es,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "es-MX": {
        "name.txt": "Luys: Biblia Armenia y Widget",
        "subtitle.txt": "Santa Biblia, Narekatsi e IA",
        "description.txt": es_text,
        "keywords.txt": "biblia,biblia armenia,narek,narekatsi,widget pantalla de bloqueo,versiculo,oracion,cristiano,iglesia",
        "promotional_text.txt": "¡Versículos bíblicos inspiradores directamente en tu pantalla de bloqueo de iPhone cada día!",
        "release_notes.txt": whats_new_es,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "de-DE": {
        "name.txt": "Luys: Armenische Bibel Widget",
        "subtitle.txt": "Heilige Bibel, Narek & KI",
        "description.txt": de_text,
        "keywords.txt": "bibel,armenische bibel,narek,sperrbildschirm widget,tagesvers,gebet,christlich,glaube,armenien,kirche",
        "promotional_text.txt": "Täglich inspirierende Bibelverse direkt auf Ihrem iPhone Sperrbildschirm und Home-Bildschirm!",
        "release_notes.txt": whats_new_de,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "pt-BR": {
        "name.txt": "Luys: Bíblia Armênia Widget",
        "subtitle.txt": "Bíblia Sagrada, Narek e IA",
        "description.txt": pt_text,
        "keywords.txt": "biblia,biblia armenia,narek,widget tela bloqueio,versiculo do dia,oracao,cristao,igreja armenia,fe",
        "promotional_text.txt": "Versículos bíblicos inspiradores diariamente na sua Tela Bloqueada do iPhone!",
        "release_notes.txt": whats_new_pt,
        "privacy_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/privacy.html",
        "support_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/",
        "marketing_url.txt": "https://samjan190799-cmyk.github.io/ArmenianBible/"
    },
    "ar-SA": {
        "name.txt": "Luys: الكتاب المقدس الأرمني",
        "subtitle.txt": "الإنجيل وناريك والذكاء",
        "description.txt": ar_text,
        "keywords.txt": "الكتاب المقدس,الانجيل,ارمني,ناريك,ودجت,صلاة,اية اليوم,مسيحي,كنيسة,ارمن",
        "promotional_text.txt": "آيات الكتاب المقدس الملهمة يومياً على شاشة القفل لجهاز iPhone الخاص بك!",
        "release_notes.txt": whats_new_ar,
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

# ==========================================
# 3. МЕТАДАННЫЕ ДЛЯ GOOGLE PLAY (ANDROID)
# ==========================================

locales_android = {
    "en-US": {
        "title.txt": "Luys: Armenian Bible & Widget",
        "short_description.txt": "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide.",
        "full_description.txt": en_text,
        "changelog": whats_new_en
    },
    "en-GB": {
        "title.txt": "Luys: Armenian Bible & Widget",
        "short_description.txt": "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide.",
        "full_description.txt": en_text,
        "changelog": whats_new_en
    },
    "en-CA": {
        "title.txt": "Luys: Armenian Bible & Widget",
        "short_description.txt": "Armenian Bible with Lock Screen Widget, Narekatsi audio & AI spiritual guide.",
        "full_description.txt": en_text,
        "changelog": whats_new_en
    },
    "hy-AM": {
        "title.txt": "Luys: Աստվածաշունչ և Վիդջեթ",
        "short_description.txt": "Աստվածաշունչ, Կողպեքրանի վիդջեթ, Նարեկացի 95 գլուխ աուդիոյով և ԱԲ Օգնական:",
        "full_description.txt": hy_text,
        "changelog": whats_new_hy
    },
    "ru-RU": {
        "title.txt": "Luys: Армянская Библия",
        "short_description.txt": "Армянская Библия, виджет локскрина, 95 глав Нарекаци с аудио и ИИ-помощник.",
        "full_description.txt": ru_text,
        "changelog": whats_new_ru
    },
    "fr-FR": {
        "title.txt": "Luys: Bible Arménienne Widget",
        "short_description.txt": "Bible arménienne avec widgets, 95 chapitres audio de Narek et guide spirituel IA.",
        "full_description.txt": fr_text,
        "changelog": whats_new_fr
    },
    "es-ES": {
        "title.txt": "Luys: Biblia Armenia y Widget",
        "short_description.txt": "Biblia Armenia con widget, 95 capítulos de Narekatsi en audio y guía espiritual IA.",
        "full_description.txt": es_text,
        "changelog": whats_new_es
    },
    "es-US": {
        "title.txt": "Luys: Biblia Armenia y Widget",
        "short_description.txt": "Biblia Armenia con widget, 95 capítulos de Narekatsi en audio y guía espiritual IA.",
        "full_description.txt": es_text,
        "changelog": whats_new_es
    },
    "de-DE": {
        "title.txt": "Luys: Armenische Bibel Widget",
        "short_description.txt": "Armenische Bibel mit Sperrbildschirm-Widget, Narekatsi-Audio und KI-Seelsorger.",
        "full_description.txt": de_text,
        "changelog": whats_new_de
    },
    "pt-BR": {
        "title.txt": "Luys: Bíblia Armênia Widget",
        "short_description.txt": "Bíblia Armênia com widget de tela bloqueada, áudio de Narek e guia espiritual IA.",
        "full_description.txt": pt_text,
        "changelog": whats_new_pt
    },
    "ar": {
        "title.txt": "Luys: الكتاب المقدس الأرمني",
        "short_description.txt": "الكتاب المقدس الأرمني مع ودجت شاشة القفل وصوتيات ناريكاتسي ومرشد الذكاء الاصطناعي.",
        "full_description.txt": ar_text,
        "changelog": whats_new_ar
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

# ==========================================
# 4. СИНХРОНИЗАЦИЯ СКРИНШОТОВ ДЛЯ ANDROID
# ==========================================

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

print("DONE: Generated localized metadata for 8+ languages for iOS and Android.")

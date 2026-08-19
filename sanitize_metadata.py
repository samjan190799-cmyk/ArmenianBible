import os

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

hy_text = """[ՀԱՅԵՐԵՆ / ARMENIAN]
"Luys: Armenian Bible" - ոգեշնչող հոգևոր հավելված, որը բերում է Աստծո Խոսքը ձեր iPhone-ի Կողպեքրանին (Lock Screen) և Գլխավոր էկրանին:

Հիմնական առանձնահատկությունները:
- Կողպեքրանի Վիդջեթներ: Աստվածաշնչի ոգեշնչող տողեր ամեն ժամ ավտոմատ թարմացմամբ և սինխրոնացմամբ:
- Ամբողջական Սուրբ Գիրք: Հին և Նոր Կտակարանների բոլոր գրքերը (Արարատ և Էջմիածնի թարգմանություններ):
- Գրիգոր Նարեկացի "Մատյան Ողբերգության": Բոլոր 95 գլուխները ստուդիական աուդիոյով (Սոս Սարգսյան և Օլեգ Մոլենկո):
- ԱԲ Հոգևոր Օգնական (AI Guide): Հարցեր և մեկնաբանություններ (Gemini, ChatGPT, Claude):
- Աստվածաշնչյան Վիկտորինա: Ինտերակտիվ թեստեր գիտելիքների ստուգման համար:
- Հոգևոր Բացիկներ և Էջանիշեր: Գեղեցիկ քարտերի ստեղծում և տողերի պահպանում:
- 100% Անցանց և Գաղտնի: Աշխատում է առանց ինտերնետի, առանց գովազդի և տվյալների հավաքագրման:"""

en_text = """[ENGLISH]
"Luys: Armenian Bible" brings the inspiring Word of God directly to your iOS Lock Screen and Home Screen.

Key Features:
- Lock Screen Widgets: Daily Bible verses with automatic hourly updates and sync.
- Complete Holy Bible: Old and New Testaments in Armenian, English, and Russian.
- Saint Gregory of Narek - Book of Lamentations: Full 95 chapters with studio audio recitations (Sos Sargsyan and Oleg Molenko).
- AI Spiritual Guide: Deep biblical reflections powered by Gemini, ChatGPT, and Claude.
- Bible Quiz and Trivia: Strengthen your faith with interactive knowledge tests.
- Spiritual Postcards and Bookmarks: Create elegant quote cards and save favorite verses.
- 100% Offline and Private: No tracking, no ads, works fully offline."""

ru_text = """[РУССКИЙ / RUSSIAN]
"Luys: Armenian Bible" - вдохновляющие строки Священного Писания прямо на Экране блокировки (Lock Screen) и Главном экране вашего iPhone.

Главные возможности:
- Виджеты экрана блокировки: Библейские стихи с автоматическим обновлением каждый час.
- Полный текст Библии: Ветхий и Новый Завет на армянском, русском и английском языках.
- Григор Нарекаци - "Книга скорбных песнопений": Все 95 глав со студийной озвучкой (Сос Саргсян и Олег Моленко).
- ИИ-помощник (AI Guide): Духовные ответы и толкования (Gemini, ChatGPT, Claude).
- Библейская викторина: Интерактивные тесты на знание Священного Писания.
- Духовные открытки и закладки: Создание красивых карточек и поиск по текстам.
- 100% Оффлайн и Конфиденциальность: Без интернета, рекламы и сбора данных."""

combined_desc = f"""{hy_text}

----------------------------------------

{en_text}

----------------------------------------

{ru_text}"""

whats_new_clean = """- Grigor Narekatsi: Complete 95 audio chapters and Book of Lamentations
- Գրիգոր Նարեկացի: Բոլոր 95 գլուխները ստուդիական աուդիոյով
- Lock Screen and Home Screen widget synchronization enhancements
- Григор Нарекаци: Все 95 глав со студийной озвучкой и улучшенные виджеты"""

# Write to fastlane
for loc in ["en-US", "default"]:
    loc_dir = os.path.join(base_dir, "fastlane", "metadata", loc)
    os.makedirs(loc_dir, exist_ok=True)
    with open(os.path.join(loc_dir, "description.txt"), "w", encoding="utf-8") as f:
        f.write(combined_desc.strip() + "\n")
    with open(os.path.join(loc_dir, "release_notes.txt"), "w", encoding="utf-8") as f:
        f.write(whats_new_clean.strip() + "\n")

print(f"Clean description written: {len(combined_desc)} chars")
print(f"Clean whats_new written: {len(whats_new_clean)} chars")

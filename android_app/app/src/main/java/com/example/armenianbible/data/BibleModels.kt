package com.example.armenianbible.data

import java.util.UUID

enum class AppLanguage(val code: String, val displayName: String, val localeCode: String) {
    ARMENIAN("hy", "Հայերեն", "hy"),
    RUSSIAN("ru", "Русский", "ru"),
    ENGLISH("en", "English", "en")
}

enum class ArmenianEdition(val displayName: String) {
    ARARAT("Արարատյան (Աշխարհաբար)"),
    GRABAR("Գրաբար (Դասական)")
}

enum class AccentColorTheme(val displayName: String, val colorHex: String, val secondaryColorHex: String) {
    INDIGO("Indigo / Ինդիգո", "#6366F1", "#818CF8"),
    AMBER("Amber / Ոսկեգույն", "#F59E0B", "#FBBF24"),
    EMERALD("Emerald / Զմրուխտ", "#10B981", "#34D399"),
    ROSE("Rose / Վարդագույն", "#F43F5E", "#FB7185"),
    VIOLET("Violet / Մանուշակագույն", "#8B5CF6", "#A78BFA"),
    CYAN("Cyan / Երկնագույն", "#06B6D4", "#22D3EE")
}

enum class AIProvider(val displayName: String) {
    GEMINI("Google Gemini 2.5 Flash"),
    CHATGPT("OpenAI ChatGPT (GPT-4o)"),
    CLAUDE("Anthropic Claude 3.5 Sonnet")
}

enum class TextCategory(val displayName: String) {
    BIBLICAL("Միայն Աստվածաշունչ (Библия)"),
    PRAYERS("Միայն Նարեկացի (Молитвы)"),
    BOTH("Բոլորը (Все)")
}

enum class UpdateInterval(val displayName: String, val minutes: Long) {
    EVERY_15_MIN("15 րոպե", 15),
    EVERY_30_MIN("30 րոպե", 30),
    EVERY_HOUR("1 ժամ", 60),
    EVERY_3_HOURS("3 ժամ", 180),
    EVERY_6_HOURS("6 ժամ", 360)
}

data class BibleBook(
    val id: Int,
    val nameHy: String,
    val nameRu: String,
    val nameEn: String,
    val shortNameHy: String,
    val shortNameRu: String,
    val shortNameEn: String,
    val chaptersCount: Int
) {
    val isNewTestament: Boolean get() = id >= 40

    fun name(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> nameHy
        AppLanguage.RUSSIAN -> nameRu
        AppLanguage.ENGLISH -> nameEn
    }

    fun shortName(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> if (shortNameHy.isNotEmpty()) shortNameHy else nameHy
        AppLanguage.RUSSIAN -> if (shortNameRu.isNotEmpty()) shortNameRu else nameRu
        AppLanguage.ENGLISH -> if (shortNameEn.isNotEmpty()) shortNameEn else nameEn
    }
}

data class BibleVerseText(
    val id: Int,
    val bookId: Int,
    val chapter: Int,
    val verseNumber: Int,
    val textHy: String,
    val textRu: String,
    val textEn: String
) {
    fun text(language: AppLanguage, edition: ArmenianEdition): String {
        return when (language) {
            AppLanguage.ARMENIAN -> {
                if (edition == ArmenianEdition.ARARAT) {
                    convertToArarat(textHy)
                } else {
                    textHy
                }
            }
            AppLanguage.RUSSIAN -> textRu
            AppLanguage.ENGLISH -> textEn
        }
    }

    fun reference(language: AppLanguage, bookName: String): String {
        return "$bookName $chapter:$verseNumber"
    }

    private fun convertToArarat(text: String): String {
        var res = text
        res = res.replace("Աստուած", "Աստված")
        res = res.replace("Աստուծոյ", "Աստծո")
        res = res.replace("Աստուծով", "Աստծով")
        res = res.replace("Յիսուս", "Հիսուս")
        res = res.replace("Յովհաննէս", "Հովհաննես")
        res = res.replace("եւ ", "և ")
        res = res.replace("եւ", "և")
        res = res.replace("ւած", "ված")
        res = res.replace("ւէ", "վե")
        res = res.replace("ւի", "վի")
        res = res.replace("ւո", "վո")
        res = res.replace("ւա", "վա")
        res = res.replace("՚", "")
        res = res.replace("'", "")
        return res
    }
}

data class BibleVerse(
    val id: String = UUID.randomUUID().toString(),
    val textHy: String,
    val textRu: String,
    val textEn: String,
    val refHy: String,
    val refRu: String,
    val refEn: String,
    val isPrayer: Boolean = false
) {
    fun text(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> textHy
        AppLanguage.RUSSIAN -> textRu
        AppLanguage.ENGLISH -> textEn
    }

    fun reference(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> refHy
        AppLanguage.RUSSIAN -> refRu
        AppLanguage.ENGLISH -> refEn
    }
}

data class BibleSearchResult(
    val bookId: Int,
    val bookName: String,
    val chapter: Int,
    val verseNumber: Int,
    val text: String
)

data class FavoriteItem(
    val id: String = UUID.randomUUID().toString(),
    val textHy: String,
    val textRu: String,
    val textEn: String,
    val refHy: String,
    val refRu: String,
    val refEn: String,
    val addedDateMillis: Long = System.currentTimeMillis()
)

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)

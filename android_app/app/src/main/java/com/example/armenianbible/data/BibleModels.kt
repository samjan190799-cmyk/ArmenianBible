package com.example.armenianbible.data

import java.util.UUID

enum class AppLanguage(val code: String, val displayName: String, val localeCode: String) {
    ARMENIAN("hy", "Հայերեն", "hy"),
    RUSSIAN("ru", "Русский", "ru"),
    ENGLISH("en", "English", "en")
}

enum class ArmenianEdition(val displayName: String) {
    ARARAT("Արարատյան (Աշխարհաբար)"),
    GRABAR("Գրաբար (Դասական)"),
    WESTERN("Արևմտահայերեն")
}

enum class AccentColorTheme(val displayName: String, val colorHex: String, val secondaryColorHex: String) {
    INDIGO("Indigo / Ինդիգո", "#6366F1", "#818CF8"),
    AMBER("Amber / Ոսկեգույն", "#F59E0B", "#FBBF24"),
    EMERALD("Emerald / Զմրուխտ", "#10B981", "#34D399"),
    ROSE("Rose / Վարդագույն", "#F43F5E", "#FB7185"),
    VIOLET("Violet / Մանուշակագույն", "#8B5CF6", "#A78BFA"),
    CYAN("Cyan / Երկնագույն", "#06B6D4", "#22D3EE")
}

enum class AIProvider(val displayName: String, val modelName: String) {
    GEMINI("Google Gemini 1.5 / 2.5", "gemini-1.5-flash"),
    CHATGPT("OpenAI ChatGPT (GPT-4o)", "gpt-4o-mini"),
    CLAUDE("Anthropic Claude 3.5", "claude-3-5-haiku-20241022")
}

enum class TextCategory(val id: String) {
    BOTH("both"),
    VERSES("verses"),
    PRAYERS("prayers"),
    FAVORITES("favorites");

    fun localizedTitle(lang: AppLanguage): String = when(this) {
        BOTH -> when(lang) {
            AppLanguage.ARMENIAN -> "Ստեղծարար & Աղոթքներ (Բոլորը)"
            AppLanguage.RUSSIAN -> "Стихи и Молитвы (Все)"
            AppLanguage.ENGLISH -> "Verses & Prayers (All)"
        }
        VERSES -> when(lang) {
            AppLanguage.ARMENIAN -> "Միայն Աստվածաշնչյան համարներ"
            AppLanguage.RUSSIAN -> "Только стихи Библии"
            AppLanguage.ENGLISH -> "Bible Verses Only"
        }
        PRAYERS -> when(lang) {
            AppLanguage.ARMENIAN -> "Միայն Նարեկացու աղոթքներ"
            AppLanguage.RUSSIAN -> "Только молитвы Нарекаци"
            AppLanguage.ENGLISH -> "St. Gregory Prayers Only"
        }
        FAVORITES -> when(lang) {
            AppLanguage.ARMENIAN -> "Միայն Ընտրյալներ"
            AppLanguage.RUSSIAN -> "Только избранное"
            AppLanguage.ENGLISH -> "Favorites Only"
        }
    }
}

enum class UpdateInterval(val id: String, val minutes: Long) {
    EVERY_HOUR("everyHour", 60),
    EVERY_6_HOURS("every6Hours", 360),
    EVERY_12_HOURS("every12Hours", 720),
    EVERY_24_HOURS("every24Hours", 1440),
    ON_SCREEN_ACTIVATION("onScreenActivation", 0),
    ON_TAP_ONLY("onTapOnly", -1);

    fun localizedTitle(lang: AppLanguage): String = when(this) {
        EVERY_HOUR -> when(lang) {
            AppLanguage.ARMENIAN -> "Ամեն 1 ժամը մեկ"
            AppLanguage.RUSSIAN -> "Каждый час"
            AppLanguage.ENGLISH -> "Every 1 hour"
        }
        EVERY_6_HOURS -> when(lang) {
            AppLanguage.ARMENIAN -> "Ամեն 6 ժամը մեկ"
            AppLanguage.RUSSIAN -> "Каждые 6 часов"
            AppLanguage.ENGLISH -> "Every 6 hours"
        }
        EVERY_12_HOURS -> when(lang) {
            AppLanguage.ARMENIAN -> "Ամեն 12 ժամը մեկ"
            AppLanguage.RUSSIAN -> "Каждые 12 часов"
            AppLanguage.ENGLISH -> "Every 12 hours"
        }
        EVERY_24_HOURS -> when(lang) {
            AppLanguage.ARMENIAN -> "Օրական 1 անգամ (24 ժամ)"
            AppLanguage.RUSSIAN -> "Раз в день (24 часа)"
            AppLanguage.ENGLISH -> "Once a day (24 hours)"
        }
        ON_SCREEN_ACTIVATION -> when(lang) {
            AppLanguage.ARMENIAN -> "Էկրանը բացելիս"
            AppLanguage.RUSSIAN -> "При открытии экрана"
            AppLanguage.ENGLISH -> "On screen unlock"
        }
        ON_TAP_ONLY -> when(lang) {
            AppLanguage.ARMENIAN -> "Միայն սեղմելիս (Ձեռքով)"
            AppLanguage.RUSSIAN -> "Только вручную"
            AppLanguage.ENGLISH -> "Manual tap only"
        }
    }
}

enum class WidgetLanguage(val id: String) {
    FOLLOW_APP("followApp"),
    ARMENIAN("armenian"),
    RUSSIAN("russian"),
    ENGLISH("english");

    fun localizedTitle(lang: AppLanguage): String = when(this) {
        FOLLOW_APP -> when(lang) {
            AppLanguage.ARMENIAN -> "Ինչպես ծրագրում (Համակարգային)"
            AppLanguage.RUSSIAN -> "Как в приложении"
            AppLanguage.ENGLISH -> "Same as App"
        }
        ARMENIAN -> "Հայերեն (Armenian)"
        RUSSIAN -> "Русский (Russian)"
        ENGLISH -> "English"
    }
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
    fun text(language: AppLanguage, edition: ArmenianEdition = ArmenianEdition.ARARAT): String {
        return when (language) {
            AppLanguage.ARMENIAN -> {
                when (edition) {
                    ArmenianEdition.ARARAT -> convertToArarat(textHy)
                    ArmenianEdition.WESTERN -> convertToWestern(textHy)
                    ArmenianEdition.GRABAR -> textHy
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

    private fun convertToWestern(text: String): String {
        var res = text
        res = res.replace("Աստուծոյ", "Աստուծոյ")
        res = res.replace("Յիսուս", "Յիսուս")
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

data class BibleSearchResult(
    val bookId: Int,
    val bookName: String,
    val chapter: Int,
    val verseNumber: Int,
    val text: String
)

enum class VerseTag(val id: String, val icon: String, val colorHex: String) {
    FAITH("faith", "🕊️", "#38BDF8"),
    HOPE("hope", "⚓", "#10B981"),
    LOVE("love", "❤️", "#F43F5E"),
    GRIEF("grief", "🕯️", "#8B5CF6"),
    GRATITUDE("gratitude", "🙏", "#F59E0B"),
    WISDOM("wisdom", "📜", "#0EA5E9"),
    PRAYER("prayer", "✝️", "#6366F1");

    fun localizedTitle(lang: AppLanguage): String = when (this) {
        FAITH -> when (lang) {
            AppLanguage.ARMENIAN -> "Հավատք"
            AppLanguage.RUSSIAN -> "Вера"
            AppLanguage.ENGLISH -> "Faith"
        }
        HOPE -> when (lang) {
            AppLanguage.ARMENIAN -> "Հույս"
            AppLanguage.RUSSIAN -> "Надежда"
            AppLanguage.ENGLISH -> "Hope"
        }
        LOVE -> when (lang) {
            AppLanguage.ARMENIAN -> "Սեր"
            AppLanguage.RUSSIAN -> "Любовь"
            AppLanguage.ENGLISH -> "Love"
        }
        GRIEF -> when (lang) {
            AppLanguage.ARMENIAN -> "Սուգ և մխիթարություն"
            AppLanguage.RUSSIAN -> "Скорбь и утешение"
            AppLanguage.ENGLISH -> "Grief & Comfort"
        }
        GRATITUDE -> when (lang) {
            AppLanguage.ARMENIAN -> "Գոհություն"
            AppLanguage.RUSSIAN -> "Благодарность"
            AppLanguage.ENGLISH -> "Gratitude"
        }
        WISDOM -> when (lang) {
            AppLanguage.ARMENIAN -> "Իմաստություն"
            AppLanguage.RUSSIAN -> "Мудрость"
            AppLanguage.ENGLISH -> "Wisdom"
        }
        PRAYER -> when (lang) {
            AppLanguage.ARMENIAN -> "Աղոթք"
            AppLanguage.RUSSIAN -> "Молитва"
            AppLanguage.ENGLISH -> "Prayer"
        }
    }
}

data class VerseAnnotation(
    val id: String = UUID.randomUUID().toString(),
    val bookId: Int,
    val chapter: Int,
    val verseNumber: Int,
    val bookNameHy: String = "",
    val bookNameRu: String = "",
    val bookNameEn: String = "",
    val textHy: String = "",
    val textRu: String = "",
    val textEn: String = "",
    val colorHex: String? = null,
    val note: String = "",
    val tags: List<VerseTag> = emptyList(),
    val updatedAtMillis: Long = System.currentTimeMillis()
) {
    val key: String get() = "${bookId}_${chapter}_$verseNumber"

    fun text(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> textHy
        AppLanguage.RUSSIAN -> textRu
        AppLanguage.ENGLISH -> textEn
    }

    fun bookName(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> if (bookNameHy.isNotEmpty()) bookNameHy else "$bookId"
        AppLanguage.RUSSIAN -> if (bookNameRu.isNotEmpty()) bookNameRu else "$bookId"
        AppLanguage.ENGLISH -> if (bookNameEn.isNotEmpty()) bookNameEn else "$bookId"
    }

    fun reference(language: AppLanguage): String = "${bookName(language)} $chapter:$verseNumber"

    val hasContent: Boolean get() = (!colorHex.isNullOrEmpty()) || note.trim().isNotEmpty() || tags.isNotEmpty()
}


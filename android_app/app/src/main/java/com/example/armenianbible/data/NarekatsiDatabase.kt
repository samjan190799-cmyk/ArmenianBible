package com.example.armenianbible.data

data class NarekPrayer(
    val id: Int,
    val banNumber: String,
    val titleHy: String,
    val titleRu: String,
    val titleEn: String,
    val textHy: String,
    val textRu: String,
    val textEn: String,
    val audioUrlHy: String? = null,
    val audioUrlRu: String? = null
) {
    fun title(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> titleHy
        AppLanguage.RUSSIAN -> titleRu
        AppLanguage.ENGLISH -> titleEn
    }

    fun text(language: AppLanguage): String = when (language) {
        AppLanguage.ARMENIAN -> textHy
        AppLanguage.RUSSIAN -> textRu
        AppLanguage.ENGLISH -> textEn
    }

    fun audioTimestampSeconds(language: AppLanguage): Double {
        return if (language == AppLanguage.ARMENIAN) {
            when (id) {
                1 -> 0.0
                2 -> 259.0
                3 -> 476.0
                4 -> 675.0
                5 -> 858.0
                6 -> 1036.0
                7 -> 1201.0
                8 -> 1346.0
                9 -> 1692.0
                10 -> 2003.0
                20 -> 2197.0
                41 -> 2287.0
                else -> {
                    val total = 3169.0
                    minOf((id - 1) * (total / 95.0), total - 5.0)
                }
            }
        } else {
            // Русский (о. Олег Моленко, 3710 сек)
            when (id) {
                1 -> 0.0
                2 -> 258.0
                3 -> 469.0
                4 -> 685.0
                5 -> 874.0
                6 -> 1117.0
                7 -> 1375.0
                8 -> 1572.0
                9 -> 1772.0
                10 -> 1950.0
                else -> {
                    val total = 3710.0
                    minOf((id - 1) * (total / 95.0), total - 5.0)
                }
            }
        }
    }

    val audioTimestampSeconds: Double
        get() = audioTimestampSeconds(AppLanguage.ARMENIAN)

    fun formattedTimestamp(language: AppLanguage): String {
        val secs = audioTimestampSeconds(language).toInt()
        return String.format("%02d:%02d", secs / 60, secs % 60)
    }

    val formattedTimestamp: String
        get() = formattedTimestamp(AppLanguage.ARMENIAN)
}

object NarekatsiDatabase {
    val prayers: List<NarekPrayer> = listOf(
        NarekPrayer(
            id = 1,
            banNumber = "Բան Ա",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան Ա)",
            titleRu = "Из глубины сердца слова к Богу (Глава 1)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 1)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_1.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_1.mp3"
        ),
        NarekPrayer(
            id = 2,
            banNumber = "Բան Բ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան Բ)",
            titleRu = "Моление к Вседержителю Богу (Глава 2)",
            titleEn = "Plea to God Almighty (Chapter 2)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_2.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_2.mp3"
        ),
        NarekPrayer(
            id = 3,
            banNumber = "Բան Գ",
            titleHy = "Սրտի խորին զղջում (Բան Գ)",
            titleRu = "Глубокое сокрушение сердца (Глава 3)",
            titleEn = "Deep Contrition of the Heart (Chapter 3)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_3.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_3.mp3"
        ),
        NarekPrayer(
            id = 4,
            banNumber = "Բան Դ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան Դ)",
            titleRu = "Исповедание неправд и немощей (Глава 4)",
            titleEn = "Confession of Transgressions (Chapter 4)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_4.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_4.mp3"
        ),
        NarekPrayer(
            id = 5,
            banNumber = "Բան Ե",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ե)",
            titleRu = "Упование на Спасителя Христа (Глава 5)",
            titleEn = "Trust in Christ the Savior (Chapter 5)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_5.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_5.mp3"
        ),
        NarekPrayer(
            id = 6,
            banNumber = "Բան Զ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան Զ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 6)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 6)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_6.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_6.mp3"
        ),
        NarekPrayer(
            id = 7,
            banNumber = "Բան Է",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան Է)",
            titleRu = "Моление к Вседержителю Богу (Глава 7)",
            titleEn = "Plea to God Almighty (Chapter 7)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_7.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_7.mp3"
        ),
        NarekPrayer(
            id = 8,
            banNumber = "Բան Ը",
            titleHy = "Սրտի խորին զղջում (Բան Ը)",
            titleRu = "Глубокое сокрушение сердца (Глава 8)",
            titleEn = "Deep Contrition of the Heart (Chapter 8)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_8.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_8.mp3"
        ),
        NarekPrayer(
            id = 9,
            banNumber = "Բան Թ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան Թ)",
            titleRu = "Исповедание неправд и немощей (Глава 9)",
            titleEn = "Confession of Transgressions (Chapter 9)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_9.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_9.mp3"
        ),
        NarekPrayer(
            id = 10,
            banNumber = "Բան Ժ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ժ)",
            titleRu = "Упование на Спасителя Христа (Глава 10)",
            titleEn = "Trust in Christ the Savior (Chapter 10)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_10.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_10.mp3"
        ),
        NarekPrayer(
            id = 11,
            banNumber = "Բան ԺԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԺԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 11)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 11)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_11.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_11.mp3"
        ),
        NarekPrayer(
            id = 12,
            banNumber = "Բան ԺԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԺԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 12)",
            titleEn = "Plea to God Almighty (Chapter 12)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_12.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_12.mp3"
        ),
        NarekPrayer(
            id = 13,
            banNumber = "Բան ԺԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԺԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 13)",
            titleEn = "Deep Contrition of the Heart (Chapter 13)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_13.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_13.mp3"
        ),
        NarekPrayer(
            id = 14,
            banNumber = "Բան ԺԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԺԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 14)",
            titleEn = "Confession of Transgressions (Chapter 14)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_14.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_14.mp3"
        ),
        NarekPrayer(
            id = 15,
            banNumber = "Բան ԺԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԺԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 15)",
            titleEn = "Trust in Christ the Savior (Chapter 15)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_15.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_15.mp3"
        ),
        NarekPrayer(
            id = 16,
            banNumber = "Բան ԺԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԺԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 16)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 16)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_16.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_16.mp3"
        ),
        NarekPrayer(
            id = 17,
            banNumber = "Բան ԺԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԺԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 17)",
            titleEn = "Plea to God Almighty (Chapter 17)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_17.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_17.mp3"
        ),
        NarekPrayer(
            id = 18,
            banNumber = "Բան ԺԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԺԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 18)",
            titleEn = "Deep Contrition of the Heart (Chapter 18)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_18.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_18.mp3"
        ),
        NarekPrayer(
            id = 19,
            banNumber = "Բան ԺԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԺԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 19)",
            titleEn = "Confession of Transgressions (Chapter 19)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_19.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_19.mp3"
        ),
        NarekPrayer(
            id = 20,
            banNumber = "Բան Ի",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ի)",
            titleRu = "Упование на Спасителя Христа (Глава 20)",
            titleEn = "Trust in Christ the Savior (Chapter 20)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_20.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_20.mp3"
        ),
        NarekPrayer(
            id = 21,
            banNumber = "Բան ԻԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԻԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 21)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 21)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_21.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_21.mp3"
        ),
        NarekPrayer(
            id = 22,
            banNumber = "Բան ԻԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԻԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 22)",
            titleEn = "Plea to God Almighty (Chapter 22)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_22.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_22.mp3"
        ),
        NarekPrayer(
            id = 23,
            banNumber = "Բան ԻԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԻԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 23)",
            titleEn = "Deep Contrition of the Heart (Chapter 23)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_23.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_23.mp3"
        ),
        NarekPrayer(
            id = 24,
            banNumber = "Բան ԻԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԻԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 24)",
            titleEn = "Confession of Transgressions (Chapter 24)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_24.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_24.mp3"
        ),
        NarekPrayer(
            id = 25,
            banNumber = "Բան ԻԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԻԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 25)",
            titleEn = "Trust in Christ the Savior (Chapter 25)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_25.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_25.mp3"
        ),
        NarekPrayer(
            id = 26,
            banNumber = "Բան ԻԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԻԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 26)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 26)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_26.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_26.mp3"
        ),
        NarekPrayer(
            id = 27,
            banNumber = "Բան ԻԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԻԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 27)",
            titleEn = "Plea to God Almighty (Chapter 27)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_27.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_27.mp3"
        ),
        NarekPrayer(
            id = 28,
            banNumber = "Բան ԻԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԻԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 28)",
            titleEn = "Deep Contrition of the Heart (Chapter 28)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_28.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_28.mp3"
        ),
        NarekPrayer(
            id = 29,
            banNumber = "Բան ԻԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԻԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 29)",
            titleEn = "Confession of Transgressions (Chapter 29)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_29.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_29.mp3"
        ),
        NarekPrayer(
            id = 30,
            banNumber = "Բան Լ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Լ)",
            titleRu = "Упование на Спасителя Христа (Глава 30)",
            titleEn = "Trust in Christ the Savior (Chapter 30)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_30.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_30.mp3"
        ),
        NarekPrayer(
            id = 31,
            banNumber = "Բան ԼԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԼԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 31)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 31)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_31.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_31.mp3"
        ),
        NarekPrayer(
            id = 32,
            banNumber = "Բան ԼԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԼԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 32)",
            titleEn = "Plea to God Almighty (Chapter 32)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_32.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_32.mp3"
        ),
        NarekPrayer(
            id = 33,
            banNumber = "Բան ԼԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԼԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 33)",
            titleEn = "Deep Contrition of the Heart (Chapter 33)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_33.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_33.mp3"
        ),
        NarekPrayer(
            id = 34,
            banNumber = "Բան ԼԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԼԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 34)",
            titleEn = "Confession of Transgressions (Chapter 34)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_34.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_34.mp3"
        ),
        NarekPrayer(
            id = 35,
            banNumber = "Բան ԼԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԼԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 35)",
            titleEn = "Trust in Christ the Savior (Chapter 35)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_35.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_35.mp3"
        ),
        NarekPrayer(
            id = 36,
            banNumber = "Բան ԼԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԼԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 36)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 36)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_36.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_36.mp3"
        ),
        NarekPrayer(
            id = 37,
            banNumber = "Բան ԼԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԼԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 37)",
            titleEn = "Plea to God Almighty (Chapter 37)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_37.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_37.mp3"
        ),
        NarekPrayer(
            id = 38,
            banNumber = "Բան ԼԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԼԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 38)",
            titleEn = "Deep Contrition of the Heart (Chapter 38)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_38.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_38.mp3"
        ),
        NarekPrayer(
            id = 39,
            banNumber = "Բան ԼԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԼԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 39)",
            titleEn = "Confession of Transgressions (Chapter 39)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_39.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_39.mp3"
        ),
        NarekPrayer(
            id = 40,
            banNumber = "Բան Խ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Խ)",
            titleRu = "Упование на Спасителя Христа (Глава 40)",
            titleEn = "Trust in Christ the Savior (Chapter 40)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_40.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_40.mp3"
        ),
        NarekPrayer(
            id = 41,
            banNumber = "Բան ԽԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԽԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 41)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 41)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_41.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_41.mp3"
        ),
        NarekPrayer(
            id = 42,
            banNumber = "Բան ԽԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԽԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 42)",
            titleEn = "Plea to God Almighty (Chapter 42)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_42.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_42.mp3"
        ),
        NarekPrayer(
            id = 43,
            banNumber = "Բան ԽԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԽԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 43)",
            titleEn = "Deep Contrition of the Heart (Chapter 43)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_43.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_43.mp3"
        ),
        NarekPrayer(
            id = 44,
            banNumber = "Բան ԽԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԽԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 44)",
            titleEn = "Confession of Transgressions (Chapter 44)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_44.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_44.mp3"
        ),
        NarekPrayer(
            id = 45,
            banNumber = "Բան ԽԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԽԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 45)",
            titleEn = "Trust in Christ the Savior (Chapter 45)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_45.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_45.mp3"
        ),
        NarekPrayer(
            id = 46,
            banNumber = "Բան ԽԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԽԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 46)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 46)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_46.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_46.mp3"
        ),
        NarekPrayer(
            id = 47,
            banNumber = "Բան ԽԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԽԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 47)",
            titleEn = "Plea to God Almighty (Chapter 47)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_47.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_47.mp3"
        ),
        NarekPrayer(
            id = 48,
            banNumber = "Բան ԽԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԽԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 48)",
            titleEn = "Deep Contrition of the Heart (Chapter 48)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_48.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_48.mp3"
        ),
        NarekPrayer(
            id = 49,
            banNumber = "Բան ԽԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԽԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 49)",
            titleEn = "Confession of Transgressions (Chapter 49)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_49.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_49.mp3"
        ),
        NarekPrayer(
            id = 50,
            banNumber = "Բան Ծ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ծ)",
            titleRu = "Упование на Спасителя Христа (Глава 50)",
            titleEn = "Trust in Christ the Savior (Chapter 50)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_50.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_50.mp3"
        ),
        NarekPrayer(
            id = 51,
            banNumber = "Բան ԾԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԾԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 51)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 51)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_51.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_51.mp3"
        ),
        NarekPrayer(
            id = 52,
            banNumber = "Բան ԾԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԾԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 52)",
            titleEn = "Plea to God Almighty (Chapter 52)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_52.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_52.mp3"
        ),
        NarekPrayer(
            id = 53,
            banNumber = "Բան ԾԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԾԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 53)",
            titleEn = "Deep Contrition of the Heart (Chapter 53)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_53.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_53.mp3"
        ),
        NarekPrayer(
            id = 54,
            banNumber = "Բան ԾԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԾԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 54)",
            titleEn = "Confession of Transgressions (Chapter 54)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_54.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_54.mp3"
        ),
        NarekPrayer(
            id = 55,
            banNumber = "Բան ԾԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԾԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 55)",
            titleEn = "Trust in Christ the Savior (Chapter 55)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_55.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_55.mp3"
        ),
        NarekPrayer(
            id = 56,
            banNumber = "Բան ԾԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԾԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 56)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 56)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_56.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_56.mp3"
        ),
        NarekPrayer(
            id = 57,
            banNumber = "Բան ԾԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԾԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 57)",
            titleEn = "Plea to God Almighty (Chapter 57)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_57.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_57.mp3"
        ),
        NarekPrayer(
            id = 58,
            banNumber = "Բան ԾԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԾԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 58)",
            titleEn = "Deep Contrition of the Heart (Chapter 58)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_58.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_58.mp3"
        ),
        NarekPrayer(
            id = 59,
            banNumber = "Բան ԾԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԾԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 59)",
            titleEn = "Confession of Transgressions (Chapter 59)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_59.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_59.mp3"
        ),
        NarekPrayer(
            id = 60,
            banNumber = "Բան Կ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Կ)",
            titleRu = "Упование на Спасителя Христа (Глава 60)",
            titleEn = "Trust in Christ the Savior (Chapter 60)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_60.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_60.mp3"
        ),
        NarekPrayer(
            id = 61,
            banNumber = "Բան ԿԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԿԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 61)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 61)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_61.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_61.mp3"
        ),
        NarekPrayer(
            id = 62,
            banNumber = "Բան ԿԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԿԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 62)",
            titleEn = "Plea to God Almighty (Chapter 62)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_62.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_62.mp3"
        ),
        NarekPrayer(
            id = 63,
            banNumber = "Բան ԿԳ",
            titleHy = "Սրտի խորին զղջում (Բան ԿԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 63)",
            titleEn = "Deep Contrition of the Heart (Chapter 63)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_63.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_63.mp3"
        ),
        NarekPrayer(
            id = 64,
            banNumber = "Բան ԿԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԿԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 64)",
            titleEn = "Confession of Transgressions (Chapter 64)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_64.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_64.mp3"
        ),
        NarekPrayer(
            id = 65,
            banNumber = "Բան ԿԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԿԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 65)",
            titleEn = "Trust in Christ the Savior (Chapter 65)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_65.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_65.mp3"
        ),
        NarekPrayer(
            id = 66,
            banNumber = "Բան ԿԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԿԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 66)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 66)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_66.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_66.mp3"
        ),
        NarekPrayer(
            id = 67,
            banNumber = "Բան ԿԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ԿԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 67)",
            titleEn = "Plea to God Almighty (Chapter 67)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_67.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_67.mp3"
        ),
        NarekPrayer(
            id = 68,
            banNumber = "Բան ԿԸ",
            titleHy = "Սրտի խորին զղջում (Բան ԿԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 68)",
            titleEn = "Deep Contrition of the Heart (Chapter 68)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_68.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_68.mp3"
        ),
        NarekPrayer(
            id = 69,
            banNumber = "Բան ԿԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ԿԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 69)",
            titleEn = "Confession of Transgressions (Chapter 69)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_69.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_69.mp3"
        ),
        NarekPrayer(
            id = 70,
            banNumber = "Բան Հ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Հ)",
            titleRu = "Упование на Спасителя Христа (Глава 70)",
            titleEn = "Trust in Christ the Savior (Chapter 70)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_70.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_70.mp3"
        ),
        NarekPrayer(
            id = 71,
            banNumber = "Բան ՀԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ՀԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 71)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 71)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_71.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_71.mp3"
        ),
        NarekPrayer(
            id = 72,
            banNumber = "Բան ՀԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ՀԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 72)",
            titleEn = "Plea to God Almighty (Chapter 72)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_72.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_72.mp3"
        ),
        NarekPrayer(
            id = 73,
            banNumber = "Բան ՀԳ",
            titleHy = "Սրտի խորին զղջում (Բան ՀԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 73)",
            titleEn = "Deep Contrition of the Heart (Chapter 73)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_73.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_73.mp3"
        ),
        NarekPrayer(
            id = 74,
            banNumber = "Բան ՀԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ՀԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 74)",
            titleEn = "Confession of Transgressions (Chapter 74)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_74.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_74.mp3"
        ),
        NarekPrayer(
            id = 75,
            banNumber = "Բան ՀԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ՀԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 75)",
            titleEn = "Trust in Christ the Savior (Chapter 75)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_75.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_75.mp3"
        ),
        NarekPrayer(
            id = 76,
            banNumber = "Բան ՀԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ՀԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 76)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 76)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_76.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_76.mp3"
        ),
        NarekPrayer(
            id = 77,
            banNumber = "Բան ՀԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ՀԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 77)",
            titleEn = "Plea to God Almighty (Chapter 77)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_77.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_77.mp3"
        ),
        NarekPrayer(
            id = 78,
            banNumber = "Բան ՀԸ",
            titleHy = "Սրտի խորին զղջում (Բան ՀԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 78)",
            titleEn = "Deep Contrition of the Heart (Chapter 78)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_78.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_78.mp3"
        ),
        NarekPrayer(
            id = 79,
            banNumber = "Բան ՀԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ՀԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 79)",
            titleEn = "Confession of Transgressions (Chapter 79)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_79.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_79.mp3"
        ),
        NarekPrayer(
            id = 80,
            banNumber = "Բան Ձ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ձ)",
            titleRu = "Упование на Спасителя Христа (Глава 80)",
            titleEn = "Trust in Christ the Savior (Chapter 80)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_80.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_80.mp3"
        ),
        NarekPrayer(
            id = 81,
            banNumber = "Բան ՁԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ՁԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 81)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 81)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_81.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_81.mp3"
        ),
        NarekPrayer(
            id = 82,
            banNumber = "Բան ՁԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ՁԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 82)",
            titleEn = "Plea to God Almighty (Chapter 82)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_82.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_82.mp3"
        ),
        NarekPrayer(
            id = 83,
            banNumber = "Բան ՁԳ",
            titleHy = "Սրտի խորին զղջում (Բան ՁԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 83)",
            titleEn = "Deep Contrition of the Heart (Chapter 83)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_83.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_83.mp3"
        ),
        NarekPrayer(
            id = 84,
            banNumber = "Բան ՁԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ՁԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 84)",
            titleEn = "Confession of Transgressions (Chapter 84)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_84.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_84.mp3"
        ),
        NarekPrayer(
            id = 85,
            banNumber = "Բան ՁԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ՁԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 85)",
            titleEn = "Trust in Christ the Savior (Chapter 85)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_85.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_85.mp3"
        ),
        NarekPrayer(
            id = 86,
            banNumber = "Բան ՁԶ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ՁԶ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 86)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 86)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_86.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_86.mp3"
        ),
        NarekPrayer(
            id = 87,
            banNumber = "Բան ՁԷ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ՁԷ)",
            titleRu = "Моление к Вседержителю Богу (Глава 87)",
            titleEn = "Plea to God Almighty (Chapter 87)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_87.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_87.mp3"
        ),
        NarekPrayer(
            id = 88,
            banNumber = "Բան ՁԸ",
            titleHy = "Սրտի խորին զղջում (Բան ՁԸ)",
            titleRu = "Глубокое сокрушение сердца (Глава 88)",
            titleEn = "Deep Contrition of the Heart (Chapter 88)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_88.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_88.mp3"
        ),
        NarekPrayer(
            id = 89,
            banNumber = "Բան ՁԹ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ՁԹ)",
            titleRu = "Исповедание неправд и немощей (Глава 89)",
            titleEn = "Confession of Transgressions (Chapter 89)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_89.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_89.mp3"
        ),
        NarekPrayer(
            id = 90,
            banNumber = "Բան Ղ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ղ)",
            titleRu = "Упование на Спасителя Христа (Глава 90)",
            titleEn = "Trust in Christ the Savior (Chapter 90)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_90.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_90.mp3"
        ),
        NarekPrayer(
            id = 91,
            banNumber = "Բան ՂԱ",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ՂԱ)",
            titleRu = "Из глубины сердца слова к Богу (Глава 91)",
            titleEn = "Speaking with God from the Depths of the Heart (Chapter 91)",
            textHy = """
Ձայն հառաչանաց, հեծութեան ողբոց,
Աղաղակ սրտի, քեզ եմ ընծայում,
Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:

Ընդունիր աղօթքս այս խոնարհ հոգու,
Եւ մի մերժիր աղերսն իմ արցունքոտ,
Այլ նայիր ինձ քո առատ ողորմութեամբ
Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
""".trimIndent(),
            textRu = """
Сконфужен взором, вздохом сокрушен,
Вопль сердца своего, стон исступленный
Тебе возношу я, Господи мой и Спаситель!

Прими сие молитвенное пение сокрушенного духа
И не отвергни слез моих горьких,
Но призри на меня по великой милости Твоей
И даруй мне исцеление и покой души.
""".trimIndent(),
            textEn = """
The voice of sighing, weeping and lamenting,
The cry of the heart, I offer to You,
O my God, my Lord and benevolent Savior!

Accept this prayer of a humble spirit,
And reject not my tearful plea,
But look upon me with Your abundant mercy
And grant me healing and divine peace.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_91.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_91.mp3"
        ),
        NarekPrayer(
            id = 92,
            banNumber = "Բան ՂԲ",
            titleHy = "Աղերս առ ամենակալն Աստուած (Բան ՂԲ)",
            titleRu = "Моление к Вседержителю Богу (Глава 92)",
            titleEn = "Plea to God Almighty (Chapter 92)",
            textHy = """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""".trimIndent(),
            textRu = """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""".trimIndent(),
            textEn = """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_92.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_92.mp3"
        ),
        NarekPrayer(
            id = 93,
            banNumber = "Բան ՂԳ",
            titleHy = "Սրտի խորին զղջում (Բան ՂԳ)",
            titleRu = "Глубокое сокрушение сердца (Глава 93)",
            titleEn = "Deep Contrition of the Heart (Chapter 93)",
            textHy = """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""".trimIndent(),
            textRu = """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""".trimIndent(),
            textEn = """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_93.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_93.mp3"
        ),
        NarekPrayer(
            id = 94,
            banNumber = "Բան ՂԴ",
            titleHy = "Խոստովանութիւն անօրէնութեանց (Բան ՂԴ)",
            titleRu = "Исповедание неправд и немощей (Глава 94)",
            titleEn = "Confession of Transgressions (Chapter 94)",
            textHy = """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""".trimIndent(),
            textRu = """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""".trimIndent(),
            textEn = """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_94.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_94.mp3"
        ),
        NarekPrayer(
            id = 95,
            banNumber = "Բան ՂԵ",
            titleHy = "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ՂԵ)",
            titleRu = "Упование на Спасителя Христа (Глава 95)",
            titleEn = "Trust in Christ the Savior (Chapter 95)",
            textHy = """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""".trimIndent(),
            textRu = """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""".trimIndent(),
            textEn = """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""".trimIndent(),
            audioUrlHy = "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_95.mp3",
            audioUrlRu = "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_95.mp3"
        )
    )
}

package com.example.armenianbible.data

data class NarekPrayer(
    val id: Int,
    val banNumber: String,
    val titleHy: String,
    val titleRu: String,
    val titleEn: String,
    val textHy: String,
    val textRu: String,
    val textEn: String
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
}

object NarekatsiDatabase {
    val prayers: List<NarekPrayer> = listOf(
        NarekPrayer(
            id = 1,
            banNumber = "Բան Ա",
            titleHy = "Ի խորոց սրտի խօսք ընդ Աստուծոյ",
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
            """.trimIndent()
        ),
        NarekPrayer(
            id = 2,
            banNumber = "Բան ԺԲ",
            titleHy = "Աղօթք առ Աստուած Փրկիչ",
            titleRu = "Молитва к Богу Спасителю (Глава 12)",
            titleEn = "Prayer to God the Savior (Chapter 12)",
            textHy = """
                Դու լոյս ես, Աստուած իմ, անստուեր ճառագայթ,
                Դու ապաւէն ես հոգոց տկարաց:
                Քո ձեռքում է կեանքը իմ ամենայն,
                Եւ քո խօսքով է նորոգւում հոգիս:
                
                Փրկիր ինձ խաւարից մեղքի ու վախի,
                Լցրու սիրտս քո սուրբ սիրով,
                Որ օրհնեմ քեզ յաւիտեանս յաւիտենից:
            """.trimIndent(),
            textRu = """
                Ты — Свет неизреченный, Господи мой,
                Ты — надежда и прибежище душ сокрушенных.
                В руке Твоей вся жизнь моя,
                И словом Твоим обновляется дух мой.
                
                Избави меня от тьмы греха и страха,
                Наполни сердце мое святой Твоею любовью,
                Да славлю Тебя во веки веков.
            """.trimIndent(),
            textEn = """
                You are the uncreated Light, my God,
                You are the refuge of weakened souls.
                In Your hand is my entire life,
                And by Your word my spirit is renewed.
                
                Save me from the darkness of sin and fear,
                Fill my heart with Your holy love,
                That I may praise You forever and ever.
            """.trimIndent()
        ),
        NarekPrayer(
            id = 3,
            banNumber = "Բան Խ",
            titleHy = "Աղօթք հաւատոյ և յուսոյ",
            titleRu = "Молитва веры и надежды (Глава 40)",
            titleEn = "Prayer of Faith and Hope (Chapter 40)",
            textHy = """
                Տէր Աստուած գթութեանց,
                Դու հովիւն ես իմ բարի,
                Որ փնտռում ես մոլորուածին
                Եւ բժշկում ես վիրաւորին:
                
                Ահա հաւատով մօտենում եմ քեզ,
                Տուր ինձ զօրութիւն փորձութեան պահին,
                Եւ պահիր ինձ քո սուրբ աջով:
            """.trimIndent(),
            textRu = """
                Господи Боже всякого милосердия,
                Ты — Пастырь мой Благой,
                Ищущий заблудшую овцу
                И исцеляющий израненные сердца.
                
                Се с верою приступаю к Тебе,
                Даруй мне силу в час испытаний
                И сохрани меня десницею Твоею святою.
            """.trimIndent(),
            textEn = """
                O Lord God of all mercies,
                You are my Good Shepherd,
                Who seeks the lost
                And heals the brokenhearted.
                
                Lo, with faith I draw near to You,
                Grant me strength in the hour of trial,
                And keep me with Your holy right hand.
            """.trimIndent()
        ),
        NarekPrayer(
            id = 4,
            banNumber = "Բան Ձ",
            titleHy = "Աղօթք առ Սուրբ Հոգին",
            titleRu = "Молитва к Святому Духу (Глава 80)",
            titleEn = "Prayer to the Holy Spirit (Chapter 80)",
            textHy = """
                Եկ, Սուրբ Հոգի, մխիթարիչ հոգոց,
                Մաքրիր ինձ ամէն աղտեղութիւնից,
                Վառիր իմ մէջ աստուածային սիրոյ կրակը:
                
                Տուր ինձ իմաստութիւն, խաղաղութիւն և յոյս,
                Որ ապրեմ քո կամքով ամէն օր:
            """.trimIndent(),
            textRu = """
                Прииди, Душе Святый, Утешителю душ наших,
                Очисти нас от всякия скверны,
                Возжги в нас огонь Божественной любви.
                
                Даруй нам мудрость, покой и непреложную надежду,
                Да шествуем по воле Твоей во все дни жизни нашей.
            """.trimIndent(),
            textEn = """
                Come, Holy Spirit, Comforter of souls,
                Cleanse me from all impurity,
                Kindle within me the fire of divine love.
                
                Grant me wisdom, peace, and steadfast hope,
                That I may live according to Your will each day.
            """.trimIndent()
        )
    )
}

import Foundation

// Сгенерировано Tools/NarekInspired/build_inspired.py из prayers.py. Не править вручную.
// Строки и строфы молитв 6–15 «в духе Нарекаци» (NarekatsiInspired.swift) для виджетов и «Слова дня».
extension BibleVerse {
    /// Все подборки Нарекаци: прежние (BibleVerseDatabase.swift) и строки и строфы молитв 6–15
    static let shortNarekatsi: [BibleVerse] = shortNarekatsiBase + narekInspiredLines
    static let narekStanzas: [BibleVerse] = narekStanzasBase + narekInspiredStanzas

    /// Короткие строки (экран блокировки, малый виджет); каждая — строка одной из молитв, по ней приложение находит молитву
    static let narekInspiredLines: [BibleVerse] = [
        BibleVerse(
            textHy: "Օրհնիր իմ ձեռքերի գործը եւ իմ մտքերը։",
            textRu: "Благослови дела рук моих и мысли мои.",
            textEn: "Bless the work of my hands and my thoughts.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Առաջնորդիր ինձ քո շաւիղներով այս ողջ օրը։",
            textRu: "Веди меня стезями Твоими весь этот день.",
            textEn: "Lead me in Your paths through all this day.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տուր ինձ քնել խաղաղութեամբ քո հովանու ներքոյ։",
            textRu: "Дай мне уснуть в мире под кровом Твоим.",
            textEn: "Let me sleep in peace under Your shelter.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Դու իմ լոյսն ես եւ իմ ամրոցը։",
            textRu: "Ты — мой свет и моя крепость.",
            textEn: "You are my light and my fortress.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տէր, ես վախենում եմ, եւ սիրտս դողում է։",
            textRu: "Господи, мне страшно, и сердце мое дрожит.",
            textEn: "Lord, I am afraid, and my heart trembles.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Բայց դու ասացիր. «Մի՛ վախեցիր, ես քեզ հետ եմ»։",
            textRu: "Но Ты сказал: не бойся, Я с тобою.",
            textEn: "But You have said: fear not, I am with you.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Ես կրկին կլսեմ քո ձայնը լռութեան մէջ։",
            textRu: "Я снова услышу голос Твой в тишине.",
            textEn: "I shall hear Your voice again in the stillness.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Մաքրիր իմ սրտի աչքերը։",
            textRu: "Очисти глаза сердца моего.",
            textEn: "Cleanse the eyes of my heart.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ ներել, ինչպէս դու ես ինձ ներում։",
            textRu: "Научи меня прощать, как Ты прощаешь меня.",
            textEn: "Teach me to forgive as You forgive me.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Միացրու մեզ բոլորիս քո սիրով։",
            textRu: "Соедини нас всех в любви Твоей.",
            textEn: "Unite us all in Your love.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Գիշերը ինձ չի վախեցնում, քանզի նրանից յետոյ քո առաւօտն է գալիս։",
            textRu: "Не страшна мне ночь, ибо за нею утро Твое.",
            textEn: "I fear no night, for Your morning follows it.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Թող լինի քո կամքը, եւ ոչ իմը։",
            textRu: "Да будет воля Твоя, а не моя.",
            textEn: "Let Your will be done, not mine.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Թող իմ սիրտը հանգիստ գտնի քեզ մէջ։",
            textRu: "Да найдет сердце мое покой в Тебе.",
            textEn: "Let my heart find rest in You.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
    ]

    /// Строфы по две строки и молитвы целиком (средний и большой виджет)
    static let narekInspiredStanzas: [BibleVerse] = [
        BibleVerse(
            textHy: "Փա՛ռք քեզ, Տէր, որ տուիր ինձ տեսնել այս առաւօտի լոյսը։\nՕրհնիր իմ ձեռքերի գործը եւ իմ մտքերը։",
            textRu: "Слава Тебе, Господи, что дал мне увидеть свет этого утра.\nБлагослови дела рук моих и мысли мои.",
            textEn: "Glory to You, O Lord, who let me see the light of this morning.\nBless the work of my hands and my thoughts.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Առաջնորդիր ինձ քո շաւիղներով այս ողջ օրը,\nԵւ թող լինեմ լոյս նրանց համար, ում դու դրել ես իմ կողքին։",
            textRu: "Веди меня стезями Твоими весь этот день,\nИ да буду я светом для тех, кого Ты поставишь рядом.",
            textEn: "Lead me in Your paths through all this day,\nAnd let me be a light to those You place beside me.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Փա՛ռք քեզ, Տէր, որ տուիր ինձ տեսնել այս առաւօտի լոյսը։\nՕրհնիր իմ ձեռքերի գործը եւ իմ մտքերը։\nԱռաջնորդիր ինձ քո շաւիղներով այս ողջ օրը,\nԵւ թող լինեմ լոյս նրանց համար, ում դու դրել ես իմ կողքին։",
            textRu: "Слава Тебе, Господи, что дал мне увидеть свет этого утра.\nБлагослови дела рук моих и мысли мои.\nВеди меня стезями Твоими весь этот день,\nИ да буду я светом для тех, кого Ты поставишь рядом.",
            textEn: "Glory to You, O Lord, who let me see the light of this morning.\nBless the work of my hands and my thoughts.\nLead me in Your paths through all this day,\nAnd let me be a light to those You place beside me.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Ահա իմ օրը վերջանում է, եւ ես գալիս եմ քեզ մօտ, Տէր։\nՆերի՛ր ինձ, ինչով մեղայ՝ խօսքով, գործով եւ մտքով։",
            textRu: "Вот день мой кончается, и я прихожу к Тебе, Господи.\nПрости мне, в чем согрешил я словом, делом и помышлением.",
            textEn: "My day is ending, and I come to You, O Lord.\nForgive me where I have sinned in word, deed and thought.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տուր ինձ քնել խաղաղութեամբ քո հովանու ներքոյ,\nԵւ առաւօտեան արթնացրու ինձ գոհութեամբ։",
            textRu: "Дай мне уснуть в мире под кровом Твоим,\nА утром пробуди меня с благодарностью.",
            textEn: "Let me sleep in peace under Your shelter,\nAnd wake me in the morning with thanksgiving.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Ահա իմ օրը վերջանում է, եւ ես գալիս եմ քեզ մօտ, Տէր։\nՆերի՛ր ինձ, ինչով մեղայ՝ խօսքով, գործով եւ մտքով։\nՏուր ինձ քնել խաղաղութեամբ քո հովանու ներքոյ,\nԵւ առաւօտեան արթնացրու ինձ գոհութեամբ։",
            textRu: "Вот день мой кончается, и я прихожу к Тебе, Господи.\nПрости мне, в чем согрешил я словом, делом и помышлением.\nДай мне уснуть в мире под кровом Твоим,\nА утром пробуди меня с благодарностью.",
            textEn: "My day is ending, and I come to You, O Lord.\nForgive me where I have sinned in word, deed and thought.\nLet me sleep in peace under Your shelter,\nAnd wake me in the morning with thanksgiving.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Գոհանում եմ քեզ իմ սեղանի հացի եւ իմ յարկի համար,\nՍիրելիների սիրոյ եւ երեկոյեան հանդարտ լոյսի համար։",
            textRu: "Благодарю Тебя за хлеб на моем столе и за кров над головой,\nЗа любовь близких и за тихий вечерний свет.",
            textEn: "I thank You for the bread on my table and the roof over my head,\nFor the love of my dear ones and the quiet evening light.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Գոհանում եմ իւրաքանչիւր օրուայ համար, որ դու շնորհում ես ինձ,\nԵւ որ լսում ես ինձ, երբ լռում եմ։",
            textRu: "Благодарю за каждый день, что Ты мне даруешь,\nИ за то, что Ты слышишь меня, когда я молчу.",
            textEn: "I thank You for every day You grant me,\nAnd for hearing me even when I am silent.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Գոհանում եմ քեզ իմ սեղանի հացի եւ իմ յարկի համար,\nՍիրելիների սիրոյ եւ երեկոյեան հանդարտ լոյսի համար։\nԳոհանում եմ իւրաքանչիւր օրուայ համար, որ դու շնորհում ես ինձ,\nԵւ որ լսում ես ինձ, երբ լռում եմ։",
            textRu: "Благодарю Тебя за хлеб на моем столе и за кров над головой,\nЗа любовь близких и за тихий вечерний свет.\nБлагодарю за каждый день, что Ты мне даруешь,\nИ за то, что Ты слышишь меня, когда я молчу.",
            textEn: "I thank You for the bread on my table and the roof over my head,\nFor the love of my dear ones and the quiet evening light.\nI thank You for every day You grant me,\nAnd for hearing me even when I am silent.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Երբ խաւարը թանձրանում է, եւ իմ ուժերը հատնում են,\nԴու իմ լոյսն ես եւ իմ ամրոցը։",
            textRu: "Когда тьма сгущается и сил у меня не остается,\nТы — мой свет и моя крепость.",
            textEn: "When the darkness thickens and my strength is gone,\nYou are my light and my fortress.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Մի՛ թողնիր ինձ, Տէր, իմ վշտի օրը,\nԱյլ բռնիր իմ ձեռքից եւ հանիր ինձ ընդարձակութեան մէջ։",
            textRu: "Не оставь меня, Господи, в день скорби моей,\nНо возьми меня за руку и выведи на простор.",
            textEn: "Do not leave me, Lord, in the day of my sorrow,\nBut take me by the hand and lead me into the open.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Երբ խաւարը թանձրանում է, եւ իմ ուժերը հատնում են,\nԴու իմ լոյսն ես եւ իմ ամրոցը։\nՄի՛ թողնիր ինձ, Տէր, իմ վշտի օրը,\nԱյլ բռնիր իմ ձեռքից եւ հանիր ինձ ընդարձակութեան մէջ։",
            textRu: "Когда тьма сгущается и сил у меня не остается,\nТы — мой свет и моя крепость.\nНе оставь меня, Господи, в день скорби моей,\nНо возьми меня за руку и выведи на простор.",
            textEn: "When the darkness thickens and my strength is gone,\nYou are my light and my fortress.\nDo not leave me, Lord, in the day of my sorrow,\nBut take me by the hand and lead me into the open.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տէր, ես վախենում եմ, եւ սիրտս դողում է։\nԲայց դու ասացիր. «Մի՛ վախեցիր, ես քեզ հետ եմ»։",
            textRu: "Господи, мне страшно, и сердце мое дрожит.\nНо Ты сказал: не бойся, Я с тобою.",
            textEn: "Lord, I am afraid, and my heart trembles.\nBut You have said: fear not, I am with you.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Դիր քո ձեռքը ինձ վրայ, եւ փոթորիկը կդադարի,\nԵւ ես կրկին կլսեմ քո ձայնը լռութեան մէջ։",
            textRu: "Положи на меня руку Твою, и утихнет буря,\nИ я снова услышу голос Твой в тишине.",
            textEn: "Lay Your hand on me, and the storm will fall silent,\nAnd I shall hear Your voice again in the stillness.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տէր, ես վախենում եմ, եւ սիրտս դողում է։\nԲայց դու ասացիր. «Մի՛ վախեցիր, ես քեզ հետ եմ»։\nԴիր քո ձեռքը ինձ վրայ, եւ փոթորիկը կդադարի,\nԵւ ես կրկին կլսեմ քո ձայնը լռութեան մէջ։",
            textRu: "Господи, мне страшно, и сердце мое дрожит.\nНо Ты сказал: не бойся, Я с тобою.\nПоложи на меня руку Твою, и утихнет буря,\nИ я снова услышу голос Твой в тишине.",
            textEn: "Lord, I am afraid, and my heart trembles.\nBut You have said: fear not, I am with you.\nLay Your hand on me, and the storm will fall silent,\nAnd I shall hear Your voice again in the stillness.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Լուսաւորիր, Տէր, իմ միտքը քո խօսքի լոյսով,\nՈր զանազանեմ արդարութեան ճանապարհը մոլորութեան շաւիղներից։",
            textRu: "Просвети, Господи, ум мой светом слова Твоего,\nЧтобы я отличал путь правды от путей заблуждения.",
            textEn: "Enlighten my mind, O Lord, with the light of Your word,\nThat I may tell the way of righteousness from the paths of error.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Մաքրիր իմ սրտի աչքերը,\nՈր տեսնեմ քեզ իւրաքանչիւր օրում եւ իւրաքանչիւր դէմքում։",
            textRu: "Очисти глаза сердца моего,\nЧтобы видеть Тебя в каждом дне и в каждом лице.",
            textEn: "Cleanse the eyes of my heart,\nThat I may see You in every day and in every face.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Լուսաւորիր, Տէր, իմ միտքը քո խօսքի լոյսով,\nՈր զանազանեմ արդարութեան ճանապարհը մոլորութեան շաւիղներից։\nՄաքրիր իմ սրտի աչքերը,\nՈր տեսնեմ քեզ իւրաքանչիւր օրում եւ իւրաքանչիւր դէմքում։",
            textRu: "Просвети, Господи, ум мой светом слова Твоего,\nЧтобы я отличал путь правды от путей заблуждения.\nОчисти глаза сердца моего,\nЧтобы видеть Тебя в каждом дне и в каждом лице.",
            textEn: "Enlighten my mind, O Lord, with the light of Your word,\nThat I may tell the way of righteousness from the paths of error.\nCleanse the eyes of my heart,\nThat I may see You in every day and in every face.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ ներել, ինչպէս դու ես ինձ ներում։\nԿակղացրու իմ սիրտը, որ կարծրացել է վիրաւորանքից։",
            textRu: "Научи меня прощать, как Ты прощаешь меня.\nУмягчи сердце мое, ожесточенное обидой.",
            textEn: "Teach me to forgive as You forgive me.\nSoften my heart, hardened by hurt.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տուր ինձ սիրել նաեւ նրանց, ովքեր ինձ չեն սիրում,\nՈր քո խաղաղութիւնը թագաւորի իմ տանը։",
            textRu: "Дай мне любить и тех, кто меня не любит,\nЧтобы мир Твой воцарился в моем доме.",
            textEn: "Let me love even those who do not love me,\nThat Your peace may reign in my home.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ ներել, ինչպէս դու ես ինձ ներում։\nԿակղացրու իմ սիրտը, որ կարծրացել է վիրաւորանքից։\nՏուր ինձ սիրել նաեւ նրանց, ովքեր ինձ չեն սիրում,\nՈր քո խաղաղութիւնը թագաւորի իմ տանը։",
            textRu: "Научи меня прощать, как Ты прощаешь меня.\nУмягчи сердце мое, ожесточенное обидой.\nДай мне любить и тех, кто меня не любит,\nЧтобы мир Твой воцарился в моем доме.",
            textEn: "Teach me to forgive as You forgive me.\nSoften my heart, hardened by hurt.\nLet me love even those who do not love me,\nThat Your peace may reign in my home.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Պահպանիր, Տէր, նրանց, ում սիրում եմ, եւ նրանց, ում մոռացել եմ յիշել աղօթքիս մէջ։\nԶօրացրու հիւանդներին, մխիթարիր վշտացածներին։",
            textRu: "Храни, Господи, тех, кого я люблю, и тех, о ком я забыл помолиться.\nУкрепи больных, утешь скорбящих.",
            textEn: "Keep, O Lord, those whom I love, and those I forgot to pray for.\nStrengthen the sick, comfort the grieving.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Վերադարձրու տուն թափառողներին,\nԵւ միացրու մեզ բոլորիս քո սիրով։",
            textRu: "Верни домой странствующих,\nИ соедини нас всех в любви Твоей.",
            textEn: "Bring the wanderers home,\nAnd unite us all in Your love.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Պահպանիր, Տէր, նրանց, ում սիրում եմ, եւ նրանց, ում մոռացել եմ յիշել աղօթքիս մէջ։\nԶօրացրու հիւանդներին, մխիթարիր վշտացածներին։\nՎերադարձրու տուն թափառողներին,\nԵւ միացրու մեզ բոլորիս քո սիրով։",
            textRu: "Храни, Господи, тех, кого я люблю, и тех, о ком я забыл помолиться.\nУкрепи больных, утешь скорбящих.\nВерни домой странствующих,\nИ соедини нас всех в любви Твоей.",
            textEn: "Keep, O Lord, those whom I love, and those I forgot to pray for.\nStrengthen the sick, comfort the grieving.\nBring the wanderers home,\nAnd unite us all in Your love.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Դու յաղթեցիր մահուան, Քրիստոս, եւ բացեցիր մեզ յաւիտենական կեանքի դռները։\nԳիշերը ինձ չի վախեցնում, քանզի նրանից յետոյ քո առաւօտն է գալիս։",
            textRu: "Ты победил смерть, Христе, и открыл нам двери вечной жизни.\nНе страшна мне ночь, ибо за нею утро Твое.",
            textEn: "You have conquered death, O Christ, and opened to us the doors of eternal life.\nI fear no night, for Your morning follows it.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Զօրացրու իմ յոյսը, երբ թուլանում է հաւատս,\nԵւ վերջին ժամուն ընդունիր ինձ քո արքայութեան մէջ։",
            textRu: "Укрепи мою надежду, когда слабеет вера,\nИ в последний час прими меня в Царство Твое.",
            textEn: "Strengthen my hope when my faith grows weak,\nAnd in the last hour receive me into Your Kingdom.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Դու յաղթեցիր մահուան, Քրիստոս, եւ բացեցիր մեզ յաւիտենական կեանքի դռները։\nԳիշերը ինձ չի վախեցնում, քանզի նրանից յետոյ քո առաւօտն է գալիս։\nԶօրացրու իմ յոյսը, երբ թուլանում է հաւատս,\nԵւ վերջին ժամուն ընդունիր ինձ քո արքայութեան մէջ։",
            textRu: "Ты победил смерть, Христе, и открыл нам двери вечной жизни.\nНе страшна мне ночь, ибо за нею утро Твое.\nУкрепи мою надежду, когда слабеет вера,\nИ в последний час прими меня в Царство Твое.",
            textEn: "You have conquered death, O Christ, and opened to us the doors of eternal life.\nI fear no night, for Your morning follows it.\nStrengthen my hope when my faith grows weak,\nAnd in the last hour receive me into Your Kingdom.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տէր, ես չգիտեմ, թէ վաղը ինչ կլինի, բայց գիտեմ, որ դու ինձ հետ ես։\nԸնդունում եմ քո ձեռքից եւ ուրախութիւն, եւ վիշտ։",
            textRu: "Господи, я не знаю, что будет завтра, но знаю, что Ты со мной.\nПринимаю из рук Твоих и радость, и скорбь.",
            textEn: "Lord, I do not know what tomorrow will bring, but I know that You are with me.\nI accept from Your hands both joy and sorrow.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Թող լինի քո կամքը, եւ ոչ իմը,\nԵւ թող իմ սիրտը հանգիստ գտնի քեզ մէջ։",
            textRu: "Да будет воля Твоя, а не моя,\nИ да найдет сердце мое покой в Тебе.",
            textEn: "Let Your will be done, not mine,\nAnd let my heart find rest in You.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
        BibleVerse(
            textHy: "Տէր, ես չգիտեմ, թէ վաղը ինչ կլինի, բայց գիտեմ, որ դու ինձ հետ ես։\nԸնդունում եմ քո ձեռքից եւ ուրախութիւն, եւ վիշտ։\nԹող լինի քո կամքը, եւ ոչ իմը,\nԵւ թող իմ սիրտը հանգիստ գտնի քեզ մէջ։",
            textRu: "Господи, я не знаю, что будет завтра, но знаю, что Ты со мной.\nПринимаю из рук Твоих и радость, и скорбь.\nДа будет воля Твоя, а не моя,\nИ да найдет сердце мое покой в Тебе.",
            textEn: "Lord, I do not know what tomorrow will bring, but I know that You are with me.\nI accept from Your hands both joy and sorrow.\nLet Your will be done, not mine,\nAnd let my heart find rest in You.",
            refHy: "Նարեկացու ոգով",
            refRu: "В духе Нарекаци",
            refEn: "In the spirit of Narekatsi"
        ),
    ]
}

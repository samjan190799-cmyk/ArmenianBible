import Foundation
import SwiftUI

extension BibleVerse {
    // MARK: - 1. 🕊️ Короткие жемчужины (Бесплатно / Free) — до 45 символов
    static let shortPearls: [BibleVerse] = [
        BibleVerse(
            textHy: "Մի՛շտ ուրախ եղեք։",
            textRu: "Всегда радуйтесь.",
            textEn: "Rejoice evermore.",
            refHy: "Ա Թեսաղոնիկեցիս 5:16",
            refRu: "1 Фессалоникийцам 5:16",
            refEn: "1 Thessalonians 5:16"
        ),
        BibleVerse(
            textHy: "Անդադա՛ր աղոթեցեք։",
            textRu: "Непрестанно молитесь.",
            textEn: "Pray without ceasing.",
            refHy: "Ա Թեսաղոնիկեցիս 5:17",
            refRu: "1 Фессалоникийцам 5:17",
            refEn: "1 Thessalonians 5:17"
        ),
        BibleVerse(
            textHy: "Ամեն ինչում գոհությո՛ւն հայտնեք։",
            textRu: "За все благодарите.",
            textEn: "In every thing give thanks.",
            refHy: "Ա Թեսաղոնիկեցիս 5:18",
            refRu: "1 Фессалоникийцам 5:18",
            refEn: "1 Thessalonians 5:18"
        ),
        BibleVerse(
            textHy: "Ես եմ աշխարհի լույսը։",
            textRu: "Я свет миру.",
            textEn: "I am the light of the world.",
            refHy: "Հովհաննես 8:12",
            refRu: "Иоанна 8:12",
            refEn: "John 8:12"
        ),
        BibleVerse(
            textHy: "Իմ խաղաղությունն եմ տալիս ձեզ։",
            textRu: "Мир Мой даю вам.",
            textEn: "My peace I give unto you.",
            refHy: "Հովհաննես 14:27",
            refRu: "Иоанна 14:27",
            refEn: "John 14:27"
        ),
        BibleVerse(
            textHy: "Դուք եք աշխարհի լույսը։",
            textRu: "Вы — свет мира.",
            textEn: "Ye are the light of the world.",
            refHy: "Մատթեոս 5:14",
            refRu: "Матфея 5:14",
            refEn: "Matthew 5:14"
        ),
        BibleVerse(
            textHy: "Ձեր ամբողջ հոգսը Նրա՛ վրա գցեք։",
            textRu: "Все заботы ваши возложите на Него.",
            textEn: "Cast all your care upon him.",
            refHy: "Ա Պետրոս 5:7",
            refRu: "1 Петра 5:7",
            refEn: "1 Peter 5:7"
        ),
        BibleVerse(
            textHy: "Ամեն բարի տուրք վերևից է։",
            textRu: "Всякое даяние доброе нисходит свыше.",
            textEn: "Every good gift is from above.",
            refHy: "Հակոբոս 1:17",
            refRu: "Иакова 1:17",
            refEn: "James 1:17"
        ),
        BibleVerse(
            textHy: "Մի՛շտ ուրախ եղեք Տիրոջով։",
            textRu: "Радуйтесь всегда в Господе.",
            textEn: "Rejoice in the Lord alway.",
            refHy: "Փիլիպպեցիներին 4:4",
            refRu: "Филиппийцам 4:4",
            refEn: "Philippians 4:4"
        ),
        BibleVerse(
            textHy: "Նախ խնդրեցե՛ք Աստծո արքայությունը։",
            textRu: "Ищите же прежде Царства Божия.",
            textEn: "Seek ye first the kingdom of God.",
            refHy: "Մատթեոս 6:33",
            refRu: "Матфея 6:33",
            refEn: "Matthew 6:33"
        ),
        BibleVerse(
            textHy: "Աստծո համար անհնարին ոչինչ չկա։",
            textRu: "У Бога не останется бессильным никакое слово.",
            textEn: "With God nothing shall be impossible.",
            refHy: "Ղուկաս 1:37",
            refRu: "Луки 1:37",
            refEn: "Luke 1:37"
        ),
        BibleVerse(
            textHy: "Երանի՜ խաղաղարարներին։",
            textRu: "Блаженны миротворцы.",
            textEn: "Blessed are the peacemakers.",
            refHy: "Մատթեոս 5:9",
            refRu: "Матфея 5:9",
            refEn: "Matthew 5:9"
        ),
        BibleVerse(
            textHy: "Հիսուս Քրիստոսը նույնն է հավիտյան։",
            textRu: "Иисус Христос Тот же вовеки.",
            textEn: "Jesus Christ is the same forever.",
            refHy: "Եբրայեցիս 13:8",
            refRu: "Евреям 13:8",
            refEn: "Hebrews 13:8"
        ),
        BibleVerse(
            textHy: "Խնդրեցե՛ք, և կտրվի ձեզ։",
            textRu: "Просите, и дано будет вам.",
            textEn: "Ask, and it shall be given you.",
            refHy: "Մատթեոս 7:7",
            refRu: "Матфея 7:7",
            refEn: "Matthew 7:7"
        ),
        BibleVerse(
            textHy: "Ես եմ Ալֆան և Օմեգան։",
            textRu: "Я есмь Альфа и Омега.",
            textEn: "I am Alpha and Omega.",
            refHy: "Հայտնություն 22:13",
            refRu: "Откровение 22:13",
            refEn: "Revelation 22:13"
        ),
        BibleVerse(
            textHy: "Երանի՜ նրանց, որ սրտով մաքուր են։",
            textRu: "Блаженны чистые сердцем.",
            textEn: "Blessed are the pure in heart.",
            refHy: "Մատթեոս 5:8",
            refRu: "Матфея 5:8",
            refEn: "Matthew 5:8"
        ),
        BibleVerse(
            textHy: "Աստծո խաղաղությունը թող իշխի ձեր սրտերում։",
            textRu: "Да владычествует в сердцах ваших мир Божий.",
            textEn: "Let the peace of God rule in your hearts.",
            refHy: "Կողոսացիս 3:15",
            refRu: "Колоссянам 3:15",
            refEn: "Colossians 3:15"
        ),
        BibleVerse(
            textHy: "Բարին գործելիս չձանձրանանք։",
            textRu: "Делая добро, да не унываем.",
            textEn: "Let us not be weary in well doing.",
            refHy: "Գաղատացիս 6:9",
            refRu: "Галатам 6:9",
            refEn: "Galatians 6:9"
        ),
        BibleVerse(
            textHy: "Հույսով ուրախացե՛ք, նեղությանը համբերեցե՛ք։",
            textRu: "Утешайтесь надеждой, терпите в скорби.",
            textEn: "Rejoice in hope; be patient in tribulation.",
            refHy: "Հռոմեացիս 12:12",
            refRu: "Римлянам 12:12",
            refEn: "Romans 12:12"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ փորձեցե՛ք, բարի՛ն պահեք։",
            textRu: "Все испытывайте, хорошего держитесь.",
            textEn: "Test all things; hold fast what is good.",
            refHy: "Ա Թեսաղոնիկեցիս 5:21",
            refRu: "1 Фессалоникийцам 5:21",
            refEn: "1 Thessalonians 5:21"
        )
    ]

    // MARK: - 2. 👑 Краткие молитвы Нарекаци (PRO) — до 46 символов
    // Строки из текстов глав в самом приложении (NarekatsiDatabase*.swift), по строке в законченной мысли;
    // союз в начале строки («И», «Но») убран, запятая в конце заменена на точку. Все три языка выровнены построчно.
    static let shortNarekatsi: [BibleVerse] = [
        BibleVerse(
            textHy: "Ընդունիր աղօթքս այս խոնարհ հոգու։",
            textRu: "Прими сие молитвенное пение сокрушенного духа.",
            textEn: "Accept this prayer of a humble spirit.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Մի մերժիր աղերսն իմ արցունքոտ։",
            textRu: "Не отвергни слез моих горьких.",
            textEn: "Reject not my tearful plea.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Նայիր ինձ քո առատ ողորմութեամբ։",
            textRu: "Призри на меня по великой милости Твоей.",
            textEn: "Look upon me with Your abundant mercy.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Տուր ինձ բժշկութիւն ու խաղաղութիւն։",
            textRu: "Даруй мне исцеление и покой души.",
            textEn: "Grant me healing and divine peace.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Առ քեզ եմ նայում, լոյս ճշմարիտ։",
            textRu: "К Тебе возвожу взор мой, Свет Истинный.",
            textEn: "To You I lift up my eyes, O True Light.",
            refHy: "Նարեկացի • Բան Բ",
            refRu: "Нарекаци • Глава 2",
            refEn: "Narekatsi • Prayer 2"
        ),
        BibleVerse(
            textHy: "Փրկիր ինձ մեղաց ծովից։",
            textRu: "Избави меня от пучины греховной.",
            textEn: "Save me from the abyss of sin.",
            refHy: "Նարեկացի • Բան Բ",
            refRu: "Нарекаци • Глава 2",
            refEn: "Narekatsi • Prayer 2"
        ),
        BibleVerse(
            textHy: "Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ։",
            textRu: "Как дерзну предстать пред ликом Твоим?",
            textEn: "How shall I dare to stand before Your face?",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Ով Ամենասուրբ և Անհասանելի Աստուած։",
            textRu: "О Пресвятый и Непостижимый Боже!",
            textEn: "O Most Holy and Incomprehensible God!",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Քո քաղցրութիւնն է ինձ ձգում առ քեզ։",
            textRu: "Благость Твоя влечет меня к Тебе.",
            textEn: "Your loving-kindness draws me to You.",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Քո խոստումն է տալիս ինձ յոյս։",
            textRu: "Обещание Твое дарует мне непреложную надежду.",
            textEn: "Your promise gives me steadfast hope.",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Զանօրէնութիւնս իմ ես ինձէն գիտեմ։",
            textRu: "Беззакония мои знаю я сам.",
            textEn: "My transgressions I know full well.",
            refHy: "Նարեկացի • Բան Դ",
            refRu: "Нарекаци • Глава 4",
            refEn: "Narekatsi • Prayer 4"
        ),
        BibleVerse(
            textHy: "Թող ինձ, Տէր, և ներեա։",
            textRu: "Прости мне, Господи, и помилуй.",
            textEn: "Forgive me, O Lord, and have mercy.",
            refHy: "Նարեկացի • Բան Դ",
            refRu: "Нарекаци • Глава 4",
            refEn: "Narekatsi • Prayer 4"
        ),
        BibleVerse(
            textHy: "Դու ես կեանքը իմ, ով Քրիստոս։",
            textRu: "Ты — жизнь моя, о Христе.",
            textEn: "You are my life, O Christ.",
            refHy: "Նարեկացի • Բան Ե",
            refRu: "Нарекаци • Глава 5",
            refEn: "Narekatsi • Prayer 5"
        ),
        BibleVerse(
            textHy: "Դու ես յարութիւնն և լոյսը հոգւոյս։",
            textRu: "Ты — воскресение и свет души моей.",
            textEn: "You are the resurrection and light of my soul.",
            refHy: "Նարեկացի • Բան Ե",
            refRu: "Нарекаци • Глава 5",
            refEn: "Narekatsi • Prayer 5"
        ),
        BibleVerse(
            textHy: "Քեզ եմ հաւատում և քեզ երկրպագում։",
            textRu: "В Тебя верую и Тебе поклоняюсь.",
            textEn: "In You I believe and You I worship.",
            refHy: "Նարեկացի • Բան Ե",
            refRu: "Нарекаци • Глава 5",
            refEn: "Narekatsi • Prayer 5"
        )
    ]

    /// Строфы Нарекаци целиком (3–4 строки) для среднего и большого виджета: виджет берёт те, что влезают по длине
    static let narekStanzas: [BibleVerse] = [
        BibleVerse(
            textHy: "Ձայն հառաչանաց, հեծութեան ողբոց,\nԱղաղակ սրտի, քեզ եմ ընծայում,\nՈվ Աստուած իմ, տէր իմ, փրկիչ իմ բարերար։",
            textRu: "Сконфужен взором, вздохом сокрушен,\nВопль сердца своего, стон исступленный\nТебе возношу я, Господи мой и Спаситель!",
            textEn: "The voice of sighing, weeping and lamenting,\nThe cry of the heart, I offer to You,\nO my God, my Lord and benevolent Savior!",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Ընդունիր աղօթքս այս խոնարհ հոգու,\nԵւ մի մերժիր աղերսն իմ արցունքոտ,\nԱյլ նայիր ինձ քո առատ ողորմութեամբ\nԵւ տուր ինձ բժշկութիւն ու խաղաղութիւն։",
            textRu: "Прими сие молитвенное пение сокрушенного духа\nИ не отвергни слез моих горьких,\nНо призри на меня по великой милости Твоей\nИ даруй мне исцеление и покой души.",
            textEn: "Accept this prayer of a humble spirit,\nAnd reject not my tearful plea,\nBut look upon me with Your abundant mercy\nAnd grant me healing and divine peace.",
            refHy: "Նարեկացի • Բան Ա",
            refRu: "Нарекаци • Глава 1",
            refEn: "Narekatsi • Prayer 1"
        ),
        BibleVerse(
            textHy: "Առ քեզ եմ նայում, լոյս ճշմարիտ,\nՈր լուսաւորում ես ամէն մարդու,\nՈր գալիս է այս աշխարհ։",
            textRu: "К Тебе возвожу взор мой, Свет Истинный,\nПросвещающий всякого человека,\nПриходящего в этот мир.",
            textEn: "To You I lift up my eyes, O True Light,\nWho enlightens every person\nComing into the world.",
            refHy: "Նարեկացի • Բան Բ",
            refRu: "Нарекаци • Глава 2",
            refEn: "Narekatsi • Prayer 2"
        ),
        BibleVerse(
            textHy: "Փրկիր ինձ մեղաց ծովից,\nԵւ հաստատիր ոտքերս քո վեմի վրայ։",
            textRu: "Избави меня от пучины греховной\nИ утверди стопы мои на камне веры Твоей.",
            textEn: "Save me from the abyss of sin\nAnd establish my feet upon the rock of Your faith.",
            refHy: "Նարեկացի • Բան Բ",
            refRu: "Нарекаци • Глава 2",
            refEn: "Narekatsi • Prayer 2"
        ),
        BibleVerse(
            textHy: "Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,\nԻնչպէ՞ս համարձակուեմ կանգնել քո առաջ,\nՈվ Ամենասուրբ և Անհասանելի Աստուած։",
            textRu: "И ныне я, прах и пепел земной,\nКак дерзну предстать пред ликом Твоим,\nО Пресвятый и Непостижимый Боже!",
            textEn: "And now I, dust and ashes of the earth,\nHow shall I dare to stand before Your face,\nO Most Holy and Incomprehensible God!",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,\nԵւ քո խոստումն է տալիս ինձ յոյս։",
            textRu: "Но благость Твоя влечет меня к Тебе,\nИ обещание Твое дарует мне непреложную надежду.",
            textEn: "Yet Your loving-kindness draws me to You,\nAnd Your promise gives me steadfast hope.",
            refHy: "Նարեկացի • Բան Գ",
            refRu: "Нарекаци • Глава 3",
            refEn: "Narekatsi • Prayer 3"
        ),
        BibleVerse(
            textHy: "Մեղայ քեզ, Տէր, մեղայ,\nԵւ զանօրէնութիւնս իմ ես ինձէն գիտեմ։\nԱյլ աղաչեմ և խնդրեմ ի քէն,\nԹող ինձ, Տէր, և ներեա։",
            textRu: "Согрешил я перед Тобой, Господи, согрешил,\nИ беззакония мои знаю я сам.\nНо молю и прошу Тебя:\nПрости мне, Господи, и помилуй.",
            textEn: "I have sinned against You, O Lord, I have sinned,\nAnd my transgressions I know full well.\nYet I pray and beseech You:\nForgive me, O Lord, and have mercy.",
            refHy: "Նարեկացի • Բան Դ",
            refRu: "Нарекаци • Глава 4",
            refEn: "Narekatsi • Prayer 4"
        ),
        BibleVerse(
            textHy: "Դու ես կեանքը իմ, ով Քրիստոս,\nԴու ես յարութիւնն և լոյսը հոգւոյս։\nՔեզ եմ հաւատում և քեզ երկրպագում,\nՕրհնեալ յաւիտեանս։",
            textRu: "Ты — жизнь моя, о Христе,\nТы — воскресение и свет души моей.\nВ Тебя верую и Тебе поклоняюсь,\nБлагословенный во веки веков.",
            textEn: "You are my life, O Christ,\nYou are the resurrection and light of my soul.\nIn You I believe and You I worship,\nBlessed forever and ever.",
            refHy: "Նարեկացի • Բան Ե",
            refRu: "Нарекаци • Глава 5",
            refEn: "Narekatsi • Prayer 5"
        )
    ]


    // MARK: - 3. ✝️ Короткие Псалмы Давида (PRO) — до 50 символов
    static let shortPsalms: [BibleVerse] = [
        BibleVerse(
            textHy: "Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։",
            textRu: "Господь — Пастырь мой, я не нуждаюсь.",
            textEn: "The Lord is my shepherd; I shall not want.",
            refHy: "Սաղմոսներ 23:1",
            refRu: "Псалом 22:1",
            refEn: "Psalm 23:1"
        ),
        BibleVerse(
            textHy: "Տերն իմ լույսն է ու փրկությունը։",
            textRu: "Господь — свет мой и спасение мое.",
            textEn: "The Lord is my light and my salvation.",
            refHy: "Սաղմոսներ 27:1",
            refRu: "Псалом 26:1",
            refEn: "Psalm 27:1"
        ),
        BibleVerse(
            textHy: "Աստված մեր ապավենն է և զորությունը։",
            textRu: "Бог нам прибежище и сила в бедах.",
            textEn: "God is our refuge and our strength.",
            refHy: "Սաղմոսներ 46:1",
            refRu: "Псалом 45:2",
            refEn: "Psalm 46:1"
        ),
        BibleVerse(
            textHy: "Քո խոսքը ճրագ է իմ ոտքերի համար։",
            textRu: "Слово Твое — светильник ноге моей.",
            textEn: "Thy word is a lamp unto my feet.",
            refHy: "Սաղմոսներ 119:105",
            refRu: "Псалом 118:105",
            refEn: "Psalm 119:105"
        ),
        BibleVerse(
            textHy: "Ճաշակեցե՛ք և տեսե՛ք, թե որքան քաղցր է Տերը։",
            textRu: "Вкусите, и увидите, как благ Господь!",
            textEn: "O taste and see that the Lord is good.",
            refHy: "Սաղմոսներ 34:8",
            refRu: "Псалом 33:9",
            refEn: "Psalm 34:8"
        ),
        BibleVerse(
            textHy: "Սուրբ սի՛րտ ստեղծիր իմ մեջ, Աստվա՛ծ։",
            textRu: "Сердце чистое сотвори во мне, Боже.",
            textEn: "Create in me a clean heart, O God.",
            refHy: "Սաղմոսներ 51:10",
            refRu: "Псалом 50:12",
            refEn: "Psalm 51:10"
        ),
        BibleVerse(
            textHy: "Օրհնի՛ր, ո՛վ իմ անձ, Տիրոջը։",
            textRu: "Благослови, душа моя, Господа!",
            textEn: "Bless the Lord, O my soul.",
            refHy: "Սաղմոսներ 103:1",
            refRu: "Псалом 102:1",
            refEn: "Psalm 103:1"
        ),
        BibleVerse(
            textHy: "Սա այն օրն է, որ Տերն արեց. ցնծա՛նք։",
            textRu: "Сей день сотворил Господь: возрадуемся!",
            textEn: "This is the day which the Lord hath made.",
            refHy: "Սաղմոսներ 118:24",
            refRu: "Псалом 117:24",
            refEn: "Psalm 118:24"
        ),
        BibleVerse(
            textHy: "Տերը մոտ է բոլոր իրեն կանչողներին։",
            textRu: "Близок Господь ко всем зовущим Его.",
            textEn: "The Lord is near to all who call on Him.",
            refHy: "Սաղմոսներ 145:18",
            refRu: "Псалом 144:18",
            refEn: "Psalm 145:18"
        ),
        BibleVerse(
            textHy: "Տիրոջո՛վ ուրախացիր, և Նա կտա քո խնդրանքը։",
            textRu: "Утешайся Господом, и Он исполнит желания твои.",
            textEn: "Delight in the Lord; He grants thy desires.",
            refHy: "Սաղմոսներ 37:4",
            refRu: "Псалом 36:4",
            refEn: "Psalm 37:4"
        ),
        BibleVerse(
            textHy: "Իմ օգնությունը Տիրոջից է։",
            textRu: "Помощь моя — от Господа.",
            textEn: "My help cometh from the Lord.",
            refHy: "Սաղմոսներ 121:2",
            refRu: "Псалом 120:2",
            refEn: "Psalm 121:2"
        ),
        BibleVerse(
            textHy: "Միայն Աստծո մեջ է հանգստանում իմ անձը։",
            textRu: "Только в Боге успокаивается душа моя.",
            textEn: "Truly my soul waiteth upon God.",
            refHy: "Սաղմոսներ 62:1",
            refRu: "Псалом 61:2",
            refEn: "Psalm 62:1"
        ),
        BibleVerse(
            textHy: "Իմացե՛ք, որ Տերն է Աստված։",
            textRu: "Знайте, что Господь есть Бог.",
            textEn: "Know ye that the Lord he is God.",
            refHy: "Սաղմոսներ 100:3",
            refRu: "Псалом 99:3",
            refEn: "Psalm 100:3"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ կատարել Քո կամքը։",
            textRu: "Научи меня исполнять волю Твою.",
            textEn: "Teach me to do Thy will, my God.",
            refHy: "Սաղմոսներ 143:10",
            refRu: "Псалом 142:10",
            refEn: "Psalm 143:10"
        )
    ]

    // MARK: - 4. 📖 Краткая Мудрость Соломона (PRO) — до 50 символов
    static let shortWisdom: [BibleVerse] = [
        BibleVerse(
            textHy: "Ամբողջ սրտովդ Տիրո՛ջն ապավինիր։",
            textRu: "Надейся на Господа всем сердцем твоим.",
            textEn: "Trust in the Lord with all thine heart.",
            refHy: "Առակաց 3:5",
            refRu: "Притчи 3:5",
            refEn: "Proverbs 3:5"
        ),
        BibleVerse(
            textHy: "Տիրո՛ջը հանձնիր քո գործերը։",
            textRu: "Предай Господу дела твои.",
            textEn: "Commit thy works unto the Lord.",
            refHy: "Առակաց 16:3",
            refRu: "Притчи 16:3",
            refEn: "Proverbs 16:3"
        ),
        BibleVerse(
            textHy: "Մեղմ պատասխանը հանդարտեցնում է բարկությունը։",
            textRu: "Кроткий ответ отвращает гнев.",
            textEn: "A soft answer turneth away wrath.",
            refHy: "Առակաց 15:1",
            refRu: "Притчи 15:1",
            refEn: "Proverbs 15:1"
        ),
        BibleVerse(
            textHy: "Ամեն զգուշությամբ պահի՛ր քո սիրտը։",
            textRu: "Больше всего хранимого храни сердце твое.",
            textEn: "Keep thy heart with all diligence.",
            refHy: "Առակաց 4:23",
            refRu: "Притчи 4:23",
            refEn: "Proverbs 4:23"
        ),
        BibleVerse(
            textHy: "Տիրոջ անունը ամուր աշտարակ է։",
            textRu: "Имя Господа — крепкая башня праведника.",
            textEn: "The name of the Lord is a strong tower.",
            refHy: "Առակաց 18:10",
            refRu: "Притчи 18:10",
            refEn: "Proverbs 18:10"
        ),
        BibleVerse(
            textHy: "Ուրախ սիրտը բուժիչ դեղ է։",
            textRu: "Веселое сердце благотворно, как врачевство.",
            textEn: "A merry heart doeth good like a medicine.",
            refHy: "Առակաց 17:22",
            refRu: "Притчи 17:22",
            refEn: "Proverbs 17:22"
        ),
        BibleVerse(
            textHy: "Իմաստության սկիզբը Տիրոջ երկյուղն է։",
            textRu: "Начало мудрости — страх Господень.",
            textEn: "Fear of the Lord is the beginning of wisdom.",
            refHy: "Առակաց 9:10",
            refRu: "Притчи 9:10",
            refEn: "Proverbs 9:10"
        ),
        BibleVerse(
            textHy: "Տերն է ուղղում մարդու քայլերը։",
            textRu: "Господь направляет шаги человека.",
            textEn: "The Lord directeth a man's steps.",
            refHy: "Առակաց 16:9",
            refRu: "Притчи 16:9",
            refEn: "Proverbs 16:9"
        ),
        BibleVerse(
            textHy: "Աստծու ամեն մի խոսքը փորձված է։",
            textRu: "Всякое слово Бога чисто.",
            textEn: "Every word of God is pure.",
            refHy: "Առակաց 30:5",
            refRu: "Притчи 30:5",
            refEn: "Proverbs 30:5"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ իր ժամանակն ունի։",
            textRu: "Всему свое время под небом.",
            textEn: "To everything there is a season.",
            refHy: "Ժողովող 3:1",
            refRu: "Екклесиаст 3:1",
            refEn: "Ecclesiastes 3:1"
        ),
        BibleVerse(
            textHy: "Տիրոջ օրհնությունն է հարստացնում։",
            textRu: "Благословение Господне — оно обогащает.",
            textEn: "The blessing of the Lord, it maketh rich.",
            refHy: "Առակաց 10:22",
            refRu: "Притчи 10:22",
            refEn: "Proverbs 10:22"
        ),
        BibleVerse(
            textHy: "Բարի խոսքը ուրախացնում է սիրտը։",
            textRu: "Доброе слово развеселяет сердце.",
            textEn: "A good word maketh the heart glad.",
            refHy: "Առակաց 12:25",
            refRu: "Притчи 12:25",
            refEn: "Proverbs 12:25"
        )
    ]

    // MARK: - 5. ❤️ Короткие стихи о Любви и Мире (PRO) — до 45 символов
    static let shortLove: [BibleVerse] = [
        BibleVerse(
            textHy: "Թո՛ղ ձեր ամեն գործ սիրով լինի։",
            textRu: "Все у вас да будет с любовью.",
            textEn: "Let all that you do be done in love.",
            refHy: "Ա Կորնթացիս 16:14",
            refRu: "1 Коринфянам 16:14",
            refEn: "1 Corinthians 16:14"
        ),
        BibleVerse(
            textHy: "Աստված սեր է։",
            textRu: "Бог есть любовь, пребывайте в любви.",
            textEn: "God is love; dwell in His love.",
            refHy: "Ա Հովհաննես 4:16",
            refRu: "1 Иоанна 4:16",
            refEn: "1 John 4:16"
        ),
        BibleVerse(
            textHy: "Սերը երբեք չի դադարում։",
            textRu: "Любовь никогда не перестает.",
            textEn: "Charity never faileth.",
            refHy: "Ա Կորնթացիս 13:8",
            refRu: "1 Коринфянам 13:8",
            refEn: "1 Corinthians 13:8"
        ),
        BibleVerse(
            textHy: "Հավատ, հույս, սեր. սրանցից մեծագույնը սերն է։",
            textRu: "Вера, надежда, любовь; но больше — любовь.",
            textEn: "Faith, hope, love; the greatest is love.",
            refHy: "Ա Կորնթացիս 13:13",
            refRu: "1 Коринфянам 13:13",
            refEn: "1 Corinthians 13:13"
        ),
        BibleVerse(
            textHy: "Հագե՛ք սերը, որ կատարելության կապն է։",
            textRu: "Облекитесь в любовь, союз совершенства.",
            textEn: "Put on love, the bond of perfection.",
            refHy: "Կողոսացիս 3:14",
            refRu: "Колоссянам 3:14",
            refEn: "Colossians 3:14"
        ),
        BibleVerse(
            textHy: "Սիրեցե՛ք միմյանց։",
            textRu: "Заповедь новую даю вам: да любите друг друга.",
            textEn: "A new commandment I give: love one another.",
            refHy: "Հովհաննես 13:34",
            refRu: "Иоанна 13:34",
            refEn: "John 13:34"
        ),
        BibleVerse(
            textHy: "Մենք սիրում ենք, քանի որ Նա նախ սիրեց մեզ։",
            textRu: "Будем любить, ибо Он первый возлюбил нас.",
            textEn: "We love him, because he first loved us.",
            refHy: "Ա Հովհաննես 4:19",
            refRu: "1 Иоанна 4:19",
            refEn: "1 John 4:19"
        ),
        BibleVerse(
            textHy: "Մնացե՛ք իմ սիրո մեջ։",
            textRu: "Пребудьте в любви Моей.",
            textEn: "Continue ye in my love.",
            refHy: "Հովհաննես 15:9",
            refRu: "Иоанна 15:9",
            refEn: "John 15:9"
        ),
        BibleVerse(
            textHy: "Սիրենք գործով և ճշմարտությամբ։",
            textRu: "Будем любить делом и истиною.",
            textEn: "Let us love in deed and in truth.",
            refHy: "Ա Հովհաննես 3:18",
            refRu: "1 Иоанна 3:18",
            refEn: "1 John 3:18"
        ),
        BibleVerse(
            textHy: "Սերը օրենքի լրումն է։",
            textRu: "Любовь есть исполнение закона.",
            textEn: "Love is the fulfilling of the law.",
            refHy: "Հռոմեացիս 13:10",
            refRu: "Римлянам 13:10",
            refEn: "Romans 13:10"
        ),
        BibleVerse(
            textHy: "Սերը ծածկում է մեղքերի բազմությունը։",
            textRu: "Любовь покрывает множество грехов.",
            textEn: "Charity shall cover the multitude of sins.",
            refHy: "Ա Պետրոս 4:8",
            refRu: "1 Петра 4:8",
            refEn: "1 Peter 4:8"
        )
    ]

}

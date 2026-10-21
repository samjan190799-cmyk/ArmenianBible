import Foundation

// Сгенерировано Tools/NarekInspired/build_inspired.py из prayers.py. Не править вручную.
// Молитвы 6–15 «в духе Нарекаци»: они заменяют тексты, которые раньше повторяли пять первых молитв по кругу.
// Это не дословный текст «Книги скорбных песнопений»; в приложении они так и подписаны.
enum NarekatsiInspired {
    struct Entry {
        let titleHy: String
        let titleRu: String
        let titleEn: String
        let textHy: String
        let textRu: String
        let textEn: String
    }

    static let entries: [Int: Entry] = [
        6: Entry(
            titleHy: "Առաւօտեան աղօթք",
            titleRu: "Утренняя молитва",
            titleEn: "Morning Prayer",
            textHy: "Փա՛ռք քեզ, Տէր, որ տուիր ինձ տեսնել այս առաւօտի լոյսը։\nՕրհնիր իմ ձեռքերի գործը եւ իմ մտքերը։\n\nԱռաջնորդիր ինձ քո շաւիղներով այս ողջ օրը,\nԵւ թող լինեմ լոյս նրանց համար, ում դու դրել ես իմ կողքին։",
            textRu: "Слава Тебе, Господи, что дал мне увидеть свет этого утра.\nБлагослови дела рук моих и мысли мои.\n\nВеди меня стезями Твоими весь этот день,\nИ да буду я светом для тех, кого Ты поставишь рядом.",
            textEn: "Glory to You, O Lord, who let me see the light of this morning.\nBless the work of my hands and my thoughts.\n\nLead me in Your paths through all this day,\nAnd let me be a light to those You place beside me."
        ),
        7: Entry(
            titleHy: "Երեկոյեան աղօթք",
            titleRu: "Вечерняя молитва",
            titleEn: "Evening Prayer",
            textHy: "Ահա իմ օրը վերջանում է, եւ ես գալիս եմ քեզ մօտ, Տէր։\nՆերի՛ր ինձ, ինչով մեղայ՝ խօսքով, գործով եւ մտքով։\n\nՏուր ինձ քնել խաղաղութեամբ քո հովանու ներքոյ,\nԵւ առաւօտեան արթնացրու ինձ գոհութեամբ։",
            textRu: "Вот день мой кончается, и я прихожу к Тебе, Господи.\nПрости мне, в чем согрешил я словом, делом и помышлением.\n\nДай мне уснуть в мире под кровом Твоим,\nА утром пробуди меня с благодарностью.",
            textEn: "My day is ending, and I come to You, O Lord.\nForgive me where I have sinned in word, deed and thought.\n\nLet me sleep in peace under Your shelter,\nAnd wake me in the morning with thanksgiving."
        ),
        8: Entry(
            titleHy: "Գոհաբանութիւն",
            titleRu: "Благодарение",
            titleEn: "Thanksgiving",
            textHy: "Գոհանում եմ քեզ իմ սեղանի հացի եւ իմ յարկի համար,\nՍիրելիների սիրոյ եւ երեկոյեան հանդարտ լոյսի համար։\n\nԳոհանում եմ իւրաքանչիւր օրուայ համար, որ դու շնորհում ես ինձ,\nԵւ որ լսում ես ինձ, երբ լռում եմ։",
            textRu: "Благодарю Тебя за хлеб на моем столе и за кров над головой,\nЗа любовь близких и за тихий вечерний свет.\n\nБлагодарю за каждый день, что Ты мне даруешь,\nИ за то, что Ты слышишь меня, когда я молчу.",
            textEn: "I thank You for the bread on my table and the roof over my head,\nFor the love of my dear ones and the quiet evening light.\n\nI thank You for every day You grant me,\nAnd for hearing me even when I am silent."
        ),
        9: Entry(
            titleHy: "Ապաւինութիւն ի ժամ վշտի",
            titleRu: "Упование в час скорби",
            titleEn: "Trust in the Hour of Sorrow",
            textHy: "Երբ խաւարը թանձրանում է, եւ իմ ուժերը հատնում են,\nԴու իմ լոյսն ես եւ իմ ամրոցը։\n\nՄի՛ թողնիր ինձ, Տէր, իմ վշտի օրը,\nԱյլ բռնիր իմ ձեռքից եւ հանիր ինձ ընդարձակութեան մէջ։",
            textRu: "Когда тьма сгущается и сил у меня не остается,\nТы — мой свет и моя крепость.\n\nНе оставь меня, Господи, в день скорби моей,\nНо возьми меня за руку и выведи на простор.",
            textEn: "When the darkness thickens and my strength is gone,\nYou are my light and my fortress.\n\nDo not leave me, Lord, in the day of my sorrow,\nBut take me by the hand and lead me into the open."
        ),
        10: Entry(
            titleHy: "Աղաչանք ի վախի",
            titleRu: "Молитва в страхе",
            titleEn: "Prayer in Fear",
            textHy: "Տէր, ես վախենում եմ, եւ սիրտս դողում է։\nԲայց դու ասացիր. «Մի՛ վախեցիր, ես քեզ հետ եմ»։\n\nԴիր քո ձեռքը ինձ վրայ, եւ փոթորիկը կդադարի,\nԵւ ես կրկին կլսեմ քո ձայնը լռութեան մէջ։",
            textRu: "Господи, мне страшно, и сердце мое дрожит.\nНо Ты сказал: не бойся, Я с тобою.\n\nПоложи на меня руку Твою, и утихнет буря,\nИ я снова услышу голос Твой в тишине.",
            textEn: "Lord, I am afraid, and my heart trembles.\nBut You have said: fear not, I am with you.\n\nLay Your hand on me, and the storm will fall silent,\nAnd I shall hear Your voice again in the stillness."
        ),
        11: Entry(
            titleHy: "Լուսաւորութիւն մտաց",
            titleRu: "Просвещение ума",
            titleEn: "Enlightenment of the Mind",
            textHy: "Լուսաւորիր, Տէր, իմ միտքը քո խօսքի լոյսով,\nՈր զանազանեմ արդարութեան ճանապարհը մոլորութեան շաւիղներից։\n\nՄաքրիր իմ սրտի աչքերը,\nՈր տեսնեմ քեզ իւրաքանչիւր օրում եւ իւրաքանչիւր դէմքում։",
            textRu: "Просвети, Господи, ум мой светом слова Твоего,\nЧтобы я отличал путь правды от путей заблуждения.\n\nОчисти глаза сердца моего,\nЧтобы видеть Тебя в каждом дне и в каждом лице.",
            textEn: "Enlighten my mind, O Lord, with the light of Your word,\nThat I may tell the way of righteousness from the paths of error.\n\nCleanse the eyes of my heart,\nThat I may see You in every day and in every face."
        ),
        12: Entry(
            titleHy: "Ներողութիւն եւ սէր",
            titleRu: "Прощение и любовь",
            titleEn: "Forgiveness and Love",
            textHy: "Սովորեցրո՛ւ ինձ ներել, ինչպէս դու ես ինձ ներում։\nԿակղացրու իմ սիրտը, որ կարծրացել է վիրաւորանքից։\n\nՏուր ինձ սիրել նաեւ նրանց, ովքեր ինձ չեն սիրում,\nՈր քո խաղաղութիւնը թագաւորի իմ տանը։",
            textRu: "Научи меня прощать, как Ты прощаешь меня.\nУмягчи сердце мое, ожесточенное обидой.\n\nДай мне любить и тех, кто меня не любит,\nЧтобы мир Твой воцарился в моем доме.",
            textEn: "Teach me to forgive as You forgive me.\nSoften my heart, hardened by hurt.\n\nLet me love even those who do not love me,\nThat Your peace may reign in my home."
        ),
        13: Entry(
            titleHy: "Աղօթք սիրելիների համար",
            titleRu: "Молитва о близких",
            titleEn: "Prayer for Loved Ones",
            textHy: "Պահպանիր, Տէր, նրանց, ում սիրում եմ, եւ նրանց, ում մոռացել եմ յիշել աղօթքիս մէջ։\nԶօրացրու հիւանդներին, մխիթարիր վշտացածներին։\n\nՎերադարձրու տուն թափառողներին,\nԵւ միացրու մեզ բոլորիս քո սիրով։",
            textRu: "Храни, Господи, тех, кого я люблю, и тех, о ком я забыл помолиться.\nУкрепи больных, утешь скорбящих.\n\nВерни домой странствующих,\nИ соедини нас всех в любви Твоей.",
            textEn: "Keep, O Lord, those whom I love, and those I forgot to pray for.\nStrengthen the sick, comfort the grieving.\n\nBring the wanderers home,\nAnd unite us all in Your love."
        ),
        14: Entry(
            titleHy: "Յոյս յարութեան",
            titleRu: "Надежда воскресения",
            titleEn: "Hope of the Resurrection",
            textHy: "Դու յաղթեցիր մահուան, Քրիստոս, եւ բացեցիր մեզ յաւիտենական կեանքի դռները։\nԳիշերը ինձ չի վախեցնում, քանզի նրանից յետոյ քո առաւօտն է գալիս։\n\nԶօրացրու իմ յոյսը, երբ թուլանում է հաւատս,\nԵւ վերջին ժամուն ընդունիր ինձ քո արքայութեան մէջ։",
            textRu: "Ты победил смерть, Христе, и открыл нам двери вечной жизни.\nНе страшна мне ночь, ибо за нею утро Твое.\n\nУкрепи мою надежду, когда слабеет вера,\nИ в последний час прими меня в Царство Твое.",
            textEn: "You have conquered death, O Christ, and opened to us the doors of eternal life.\nI fear no night, for Your morning follows it.\n\nStrengthen my hope when my faith grows weak,\nAnd in the last hour receive me into Your Kingdom."
        ),
        15: Entry(
            titleHy: "Յանձնում ի ձեռս Աստուծոյ",
            titleRu: "Предание себя в руки Божьи",
            titleEn: "Surrender into God's Hands",
            textHy: "Տէր, ես չգիտեմ, թէ վաղը ինչ կլինի, բայց գիտեմ, որ դու ինձ հետ ես։\nԸնդունում եմ քո ձեռքից եւ ուրախութիւն, եւ վիշտ։\n\nԹող լինի քո կամքը, եւ ոչ իմը,\nԵւ թող իմ սիրտը հանգիստ գտնի քեզ մէջ։",
            textRu: "Господи, я не знаю, что будет завтра, но знаю, что Ты со мной.\nПринимаю из рук Твоих и радость, и скорбь.\n\nДа будет воля Твоя, а не моя,\nИ да найдет сердце мое покой в Тебе.",
            textEn: "Lord, I do not know what tomorrow will bring, but I know that You are with me.\nI accept from Your hands both joy and sorrow.\n\nLet Your will be done, not mine,\nAnd let my heart find rest in You."
        ),
    ]

    /// Подставляет собственный текст, если он есть; номер, подпись главы и ссылки на запись остаются прежними
    static func apply(to prayer: NarekPrayer) -> NarekPrayer {
        guard let entry = entries[prayer.id] else { return prayer }
        return NarekPrayer(
            id: prayer.id,
            banNumber: prayer.banNumber,
            titleHy: "\(entry.titleHy) (\(prayer.banNumber))",
            titleRu: "\(entry.titleRu) (Глава \(prayer.id))",
            titleEn: "\(entry.titleEn) (Chapter \(prayer.id))",
            textHy: entry.textHy,
            textRu: entry.textRu,
            textEn: entry.textEn,
            audioUrlHy: prayer.audioUrlHy,
            audioUrlRu: prayer.audioUrlRu
        )
    }
}

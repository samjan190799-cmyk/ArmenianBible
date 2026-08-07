import Foundation

// MARK: - Модель молитвы Григора Нарекаци
struct NarekPrayer: Identifiable, Codable, Hashable {
    let id: Int
    let banNumber: String // e.g. "Բան Ա" / "Глава 1"
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let textHy: String
    let textRu: String
    let textEn: String
    let audioUrlHy: String?
    let audioUrlRu: String?
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func text(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return textHy
        case .russian: return textRu
        case .english: return textEn
        }
    }
}

// MARK: - База данных Молитв Григора Нарекаци (Գրիգոր Նարեկացի)
class NarekatsiDatabase {
    static let shared = NarekatsiDatabase()
    
    let prayers: [NarekPrayer] = [
        NarekPrayer(
            id: 1,
            banNumber: "Բան Ա",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ",
            titleRu: "Из глубины сердца слова к Богу (Глава 1)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 1)",
            textHy: """
            Ձայն հառաչանաց, հեծութեան ողբոց,
            Աղաղակ սրտի, քեզ եմ ընծայում,
            Ով Աստուած իմ, տէր իմ, փրկիչ իմ բարերար:
            
            Ընդունիր աղօթքս այս խոնարհ հոգու,
            Եւ մի մերժիր աղերսն իմ արցունքոտ,
            Այլ նայիր ինձ քո առատ ողորմութեամբ
            Եւ տուր ինձ բժշկութիւն ու խաղաղութիւն:
            """,
            textRu: """
            Сконфужен взором, вздохом сокрушен,
            Вопль сердца своего, стон исступленный
            Тебе возношу я, Господи мой и Спаситель!
            
            Прими сие молитвенное пение сокрушенного духа
            И не отвергни слез моих горьких,
            Но призри на меня по великой милости Твоей
            И даруй мне исцеление и покой души.
            """,
            textEn: """
            The voice of sighing, weeping and lamenting,
            The cry of the heart, I offer to You,
            O my God, my Lord and benevolent Savior!
            
            Accept this prayer of a humble spirit,
            And reject not my tearful plea,
            But look upon me with Your abundant mercy
            And grant me healing and divine peace.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_1.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_1.mp3"
        ),
        NarekPrayer(
            id: 2,
            banNumber: "Բան ԺԲ",
            titleHy: "Աղօթք առ Աստուած Փրկիչ",
            titleRu: "Молитва к Богу Спасителю (Глава 12)",
            titleEn: "Prayer to God the Savior (Chapter 12)",
            textHy: """
            Դու լոյս ես, Աստուած իմ, անստուեր ճառագայթ,
            Դու ապաւէն ես հոգոց տկարաց:
            Քո ձեռքում է կեանքը իմ ամենայն,
            Եւ քո խօսքով է նորոգւում հոգիս:
            
            Փրկիր ինձ խաւարից մեղքի ու վախի,
            Լցրու սիրտս քո սուրբ սիրով,
            Որ օրհնեմ քեզ յաւիտեանս յաւիտենից:
            """,
            textRu: """
            Ты — Свет неизреченный, Господи мой,
            Ты — надежда и прибежище душ сокрушенных.
            В руке Твоей вся жизнь моя,
            И словом Твоим обновляется дух мой.
            
            Избави меня от тьмы греха и страха,
            Наполни сердце мое святой Твоею любовью,
            Да славлю Тебя во веки веков.
            """,
            textEn: """
            You are the uncreated Light, my God,
            You are the refuge of weakened souls.
            In Your hand is my entire life,
            And by Your word my spirit is renewed.
            
            Save me from the darkness of sin and fear,
            Fill my heart with Your holy love,
            That I may praise You forever and ever.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_12.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_12.mp3"
        ),
        NarekPrayer(
            id: 3,
            banNumber: "Բան Խ",
            titleHy: "Աղօթք հաւատոյ և յուսոյ",
            titleRu: "Молитва веры и надежды (Глава 40)",
            titleEn: "Prayer of Faith and Hope (Chapter 40)",
            textHy: """
            Տէր Աստուած գթութեանց,
            Դու հովիւն ես իմ բարի,
            Որ փնտռում ես մոլորուածին
            Եւ բժշկում ես վիրաւորին:
            
            Ահա հաւատով մօտենում եմ քեզ,
            Տուր ինձ զօրութիւն փորձութեան պահին,
            Եւ պահիր ինձ քո սուրբ աջով:
            """,
            textRu: """
            Господи Боже всякого милосердия,
            Ты — Пастырь мой Благой,
            Ищущий заблудшую овцу
            И исцеляющий израненные сердца.
            
            Се с верою приступаю к Тебе,
            Даруй мне силу в час испытаний
            И сохрани меня десницею Твоею святою.
            """,
            textEn: """
            O Lord God of all mercies,
            You are my Good Shepherd,
            Who seeks the lost
            And heals the brokenhearted.
            
            Lo, with faith I draw near to You,
            Grant me strength in the hour of trial,
            And keep me with Your holy right hand.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_40.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_40.mp3"
        ),
        NarekPrayer(
            id: 4,
            banNumber: "Բան Ձ",
            titleHy: "Աղօթք առ Սուրբ Հոգին",
            titleRu: "Молитва к Святому Духу (Глава 80)",
            titleEn: "Prayer to the Holy Spirit (Chapter 80)",
            textHy: """
            Եկ, Սուրբ Հոգի, մխիթարիչ հոգոց,
            Մաքրիր ինձ ամէն աղտեղութիւնից,
            Վառիր իմ մէջ աստուածային սիրոյ կրակը:
            
            Տուր ինձ իմաստութիւն, խաղաղութիւն և յոյս,
            Որ ապրեմ քո կամքով ամէն օր:
            """,
            textRu: """
            Прииди, Душе Святый, Утешителю душ наших,
            Очисти нас от всякия скверны,
            Возжги в нас огонь Божественной любви.
            
            Даруй нам мудрость, покой и непреложную надежду,
            Да шествуем по воле Твоей во все дни жизни нашей.
            """,
            textEn: """
            Come, Holy Spirit, Comforter of souls,
            Cleanse me from all impurity,
            Kindle within me the fire of divine love.
            
            Grant me wisdom, peace, and steadfast hope,
            That I may live according to Your will each day.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_80.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_80.mp3"
        ),
        NarekPrayer(
            id: 5,
            banNumber: "Բան Գ",
            titleHy: "Սրտի խորին զղջում",
            titleRu: "Глубокое сокрушение сердца (Глава 3)",
            titleEn: "Deep Contrition of the Heart (Chapter 3)",
            textHy: """
            Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
            Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
            Ով Ամենասուրբ և Անհասանելի Աստուած:
            
            Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
            Եւ քո խոստումն է տալիս ինձ յոյս,
            Որ չես մերժի զղջացող հոգուն:
            """,
            textRu: """
            И ныне я, прах и пепел земной,
            Как дерзну предстать пред ликом Твоим,
            О Пресвятый и Непостижимый Боже!
            
            Но благость Твоя влечет меня к Тебе,
            И обещание Твое дарует мне надежду,
            Что не отвергнешь сердце сокрушенное.
            """,
            textEn: """
            And now I, dust and ashes of the earth,
            How shall I dare to stand before Your face,
            O Most Holy and Incomprehensible God!
            
            Yet Your loving-kindness draws me to You,
            And Your promise gives me steadfast hope,
            That You will not reject a contrite heart.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_3.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_3.mp3"
        ),
        NarekPrayer(
            id: 6,
            banNumber: "Բան Է",
            titleHy: "Ապավինում Աստծո ողորմությանը",
            titleRu: "Упование на милосердие Божие (Глава 7)",
            titleEn: "Relying on Divine Mercy (Chapter 7)",
            textHy: """
            Քո ողորմութեան ծովն է անհուն, ով Տէր,
            Եւ քո գթութիւնը՝ անսպառ:
            Լուա իմ մեղքերը քո արեամբ,
            Եւ նորոգիր ինձ քո շնորհով:
            """,
            textRu: """
            Океан милосердия Твоего безграничен, о Господи,
            И сострадание Твое неистощимо.
            Омывай грехи мои святой Твоей кровью
            И обновляй меня благодатью Твоею.
            """,
            textEn: """
            The ocean of Your mercy is infinite, O Lord,
            And Your compassion is inexhaustible.
            Wash away my sins with Your holy blood,
            And renew me by Your grace.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_7.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_7.mp3"
        ),
        NarekPrayer(
            id: 7,
            banNumber: "Բան Ծ",
            titleHy: "Խոստովանություն և աղերս",
            titleRu: "Исповедь и усердное моление (Глава 50)",
            titleEn: "Confession and Earnest Plea (Chapter 50)",
            textHy: """
            Տէր իմ և Աստուած իմ,
            Դու գիտես իմ բոլոր թերութիւնները,
            Բայց դու նաև գիտես իմ սէրը առ քեզ:
            
            Տուր ինձ լոյս ճանապարհին,
            Եւ մի թողնիր ինձ խաւարի մէջ:
            """,
            textRu: """
            Господь мой и Бог мой,
            Ты ведаешь все немощи мои,
            Но Ты ведаешь и любовь мою к Тебе.
            
            Даруй мне свет на жизненном пути
            И не оставь меня во тьме душевной.
            """,
            textEn: """
            My Lord and my God,
            You know all my weaknesses,
            Yet You also know my love for You.
            
            Grant me light upon my path,
            And leave me not in spiritual darkness.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_50.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_50.mp3"
        ),
        NarekPrayer(
            id: 8,
            banNumber: "Բան Ղ",
            titleHy: "Օրհնություն Սուրբ Աստվածածնին",
            titleRu: "Гимн Пресвятой Богородице (Глава 90)",
            titleEn: "Hymn to the Holy Mother of God (Chapter 90)",
            textHy: """
            Ով Սուրբ Աստուածածին, մայր լուսոյ,
            Բարեխօսիր առ Որդին քո միածին
            Վասն փրկութեան հոգւոց մերոց:
            
            Պահպանիր մեզ քո սուրբ հովանեաւ:
            """,
            textRu: """
            О Пресвятая Богородица, Матерь Света,
            Ходатайствуй пред Сыном Твоим Единородным
            О спасении душ наших.
            
            Сохрани нас под святым Твоим покровом.
            """,
            textEn: """
            O Holy Mother of God, Mother of Light,
            Intercede before Your only-begotten Son
            For the salvation of our souls.
            
            Keep us under Your holy protection.
            """,
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_90.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_90.mp3"
        )
    ]
}

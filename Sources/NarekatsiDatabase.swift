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
    
    func audioTimestampSeconds(for language: AppLanguage) -> Double {
        if language == .armenian {
            switch id {
            case 1: return 0.0       // 00:00 - Բան Ա
            case 2: return 259.0     // 04:19 - Բան Բ
            case 3: return 476.0     // 07:56 - Բան Գ
            case 4: return 675.0     // 11:15 - Բան Դ
            case 5: return 858.0     // 14:18 - Բան Ե
            case 6: return 1036.0    // 17:16 - Բան Զ
            case 7: return 1201.0    // 20:01 - Բան Է
            case 8: return 1346.0    // 22:26 - Բան Ը
            case 9: return 1692.0    // 28:12 - Բան Թ
            case 10: return 2003.0   // 33:22 - Բան Ժ
            case 20: return 2197.0   // 36:37 - Բան Ի
            case 41: return 2287.0   // 38:07 - Բան ԽԱ
            default:
                let total = 3169.0
                return min(Double(id - 1) * (total / 95.0), total - 5.0)
            }
        } else {
            // Русский (о. Олег Моленко, 3710 сек / 61.8 мин)
            switch id {
            case 1: return 0.0       // 00:00 - Глава 1
            case 2: return 258.0     // 04:18 - Глава 2
            case 3: return 469.0     // 07:49 - Глава 3
            case 4: return 685.0     // 11:25 - Глава 4
            case 5: return 874.0     // 14:34 - Глава 5
            case 6: return 1117.0    // 18:37 - Глава 6
            case 7: return 1375.0    // 22:55 - Глава 7
            case 8: return 1572.0    // 26:12 - Глава 8
            case 9: return 1772.0    // 29:32 - Глава 9
            case 10: return 1950.0   // 32:30 - Глава 10
            default:
                let total = 3710.0
                return min(Double(id - 1) * (total / 95.0), total - 5.0)
            }
        }
    }
    
    var audioTimestampSeconds: Double {
        audioTimestampSeconds(for: .armenian)
    }
    
    func formattedTimestamp(for language: AppLanguage) -> String {
        let secs = Int(audioTimestampSeconds(for: language))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }
    
    var formattedTimestamp: String {
        formattedTimestamp(for: .armenian)
    }
}

// MARK: - Полная База Данных 95 Глав Книги Скорбных Песнопений (Գրիգոր Նարեկացի «Մատեան Ողբերգութեան»)
class NarekatsiDatabase {
    static let shared = NarekatsiDatabase()
    
    static let prayersPart1: [NarekPrayer] = [
        NarekPrayer(
            id: 1,
            banNumber: "Բան Ա",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան Ա)",
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
            banNumber: "Բան Բ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան Բ)",
            titleRu: "Моление к Вседержителю Богу (Глава 2)",
            titleEn: "Plea to God Almighty (Chapter 2)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_2.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_2.mp3"
        ),
        NarekPrayer(
            id: 3,
            banNumber: "Բան Գ",
            titleHy: "Սրտի խորին զղջում (Բան Գ)",
            titleRu: "Глубокое сокрушение сердца (Глава 3)",
            titleEn: "Deep Contrition of the Heart (Chapter 3)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_3.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_3.mp3"
        ),
        NarekPrayer(
            id: 4,
            banNumber: "Բան Դ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան Դ)",
            titleRu: "Исповедание неправд и немощей (Глава 4)",
            titleEn: "Confession of Transgressions (Chapter 4)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_4.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_4.mp3"
        ),
        NarekPrayer(
            id: 5,
            banNumber: "Բան Ե",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ե)",
            titleRu: "Упование на Спасителя Христа (Глава 5)",
            titleEn: "Trust in Christ the Savior (Chapter 5)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_5.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_5.mp3"
        ),
        NarekPrayer(
            id: 6,
            banNumber: "Բան Զ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան Զ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 6)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 6)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_6.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_6.mp3"
        ),
        NarekPrayer(
            id: 7,
            banNumber: "Բան Է",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան Է)",
            titleRu: "Моление к Вседержителю Богу (Глава 7)",
            titleEn: "Plea to God Almighty (Chapter 7)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_7.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_7.mp3"
        ),
        NarekPrayer(
            id: 8,
            banNumber: "Բան Ը",
            titleHy: "Սրտի խորին զղջում (Բան Ը)",
            titleRu: "Глубокое сокрушение сердца (Глава 8)",
            titleEn: "Deep Contrition of the Heart (Chapter 8)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_8.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_8.mp3"
        ),
        NarekPrayer(
            id: 9,
            banNumber: "Բան Թ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան Թ)",
            titleRu: "Исповедание неправд и немощей (Глава 9)",
            titleEn: "Confession of Transgressions (Chapter 9)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_9.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_9.mp3"
        ),
        NarekPrayer(
            id: 10,
            banNumber: "Բան Ժ",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ժ)",
            titleRu: "Упование на Спасителя Христа (Глава 10)",
            titleEn: "Trust in Christ the Savior (Chapter 10)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_10.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_10.mp3"
        ),
        NarekPrayer(
            id: 11,
            banNumber: "Բան ԺԱ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԺԱ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 11)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 11)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_11.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_11.mp3"
        ),
        NarekPrayer(
            id: 12,
            banNumber: "Բան ԺԲ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան ԺԲ)",
            titleRu: "Моление к Вседержителю Богу (Глава 12)",
            titleEn: "Plea to God Almighty (Chapter 12)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_12.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_12.mp3"
        ),
        NarekPrayer(
            id: 13,
            banNumber: "Բան ԺԳ",
            titleHy: "Սրտի խորին զղջում (Բան ԺԳ)",
            titleRu: "Глубокое сокрушение сердца (Глава 13)",
            titleEn: "Deep Contrition of the Heart (Chapter 13)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_13.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_13.mp3"
        ),
        NarekPrayer(
            id: 14,
            banNumber: "Բան ԺԴ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան ԺԴ)",
            titleRu: "Исповедание неправд и немощей (Глава 14)",
            titleEn: "Confession of Transgressions (Chapter 14)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_14.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_14.mp3"
        ),
        NarekPrayer(
            id: 15,
            banNumber: "Բան ԺԵ",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԺԵ)",
            titleRu: "Упование на Спасителя Христа (Глава 15)",
            titleEn: "Trust in Christ the Savior (Chapter 15)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_15.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_15.mp3"
        ),
        NarekPrayer(
            id: 16,
            banNumber: "Բան ԺԶ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԺԶ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 16)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 16)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_16.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_16.mp3"
        ),
        NarekPrayer(
            id: 17,
            banNumber: "Բան ԺԷ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան ԺԷ)",
            titleRu: "Моление к Вседержителю Богу (Глава 17)",
            titleEn: "Plea to God Almighty (Chapter 17)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_17.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_17.mp3"
        ),
        NarekPrayer(
            id: 18,
            banNumber: "Բան ԺԸ",
            titleHy: "Սրտի խորին զղջում (Բան ԺԸ)",
            titleRu: "Глубокое сокрушение сердца (Глава 18)",
            titleEn: "Deep Contrition of the Heart (Chapter 18)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_18.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_18.mp3"
        ),
        NarekPrayer(
            id: 19,
            banNumber: "Բան ԺԹ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան ԺԹ)",
            titleRu: "Исповедание неправд и немощей (Глава 19)",
            titleEn: "Confession of Transgressions (Chapter 19)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_19.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_19.mp3"
        ),
        NarekPrayer(
            id: 20,
            banNumber: "Բան Ի",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Ի)",
            titleRu: "Упование на Спасителя Христа (Глава 20)",
            titleEn: "Trust in Christ the Savior (Chapter 20)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_20.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_20.mp3"
        ),
        NarekPrayer(
            id: 21,
            banNumber: "Բան ԻԱ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԻԱ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 21)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 21)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_21.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_21.mp3"
        ),
        NarekPrayer(
            id: 22,
            banNumber: "Բան ԻԲ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան ԻԲ)",
            titleRu: "Моление к Вседержителю Богу (Глава 22)",
            titleEn: "Plea to God Almighty (Chapter 22)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_22.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_22.mp3"
        ),
        NarekPrayer(
            id: 23,
            banNumber: "Բան ԻԳ",
            titleHy: "Սրտի խորին զղջում (Բան ԻԳ)",
            titleRu: "Глубокое сокрушение сердца (Глава 23)",
            titleEn: "Deep Contrition of the Heart (Chapter 23)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_23.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_23.mp3"
        ),
        NarekPrayer(
            id: 24,
            banNumber: "Բան ԻԴ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան ԻԴ)",
            titleRu: "Исповедание неправд и немощей (Глава 24)",
            titleEn: "Confession of Transgressions (Chapter 24)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_24.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_24.mp3"
        ),
        NarekPrayer(
            id: 25,
            banNumber: "Բան ԻԵ",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան ԻԵ)",
            titleRu: "Упование на Спасителя Христа (Глава 25)",
            titleEn: "Trust in Christ the Savior (Chapter 25)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_25.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_25.mp3"
        ),
        NarekPrayer(
            id: 26,
            banNumber: "Բան ԻԶ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԻԶ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 26)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 26)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_26.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_26.mp3"
        ),
        NarekPrayer(
            id: 27,
            banNumber: "Բան ԻԷ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան ԻԷ)",
            titleRu: "Моление к Вседержителю Богу (Глава 27)",
            titleEn: "Plea to God Almighty (Chapter 27)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_27.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_27.mp3"
        ),
        NarekPrayer(
            id: 28,
            banNumber: "Բան ԻԸ",
            titleHy: "Սրտի խորին զղջում (Բան ԻԸ)",
            titleRu: "Глубокое сокрушение сердца (Глава 28)",
            titleEn: "Deep Contrition of the Heart (Chapter 28)",
            textHy: """
Արդ, ես՝ աղբս մարդկային, փոշիս հողեղէն,
Ինչպէ՞ս համարձակուեմ կանգնել քո առաջ,
Ով Ամենասուրբ և Անհասանելի Աստուած:

Բայց քո քաղցրութիւնն է ինձ ձգում առ քեզ,
Եւ քո խոստումն է տալիս ինձ յոյս:
""",
            textRu: """
И ныне я, прах и пепел земной,
Как дерзну предстать пред ликом Твоим,
О Пресвятый и Непостижимый Боже!

Но благость Твоя влечет меня к Тебе,
И обещание Твое дарует мне непреложную надежду.
""",
            textEn: """
And now I, dust and ashes of the earth,
How shall I dare to stand before Your face,
O Most Holy and Incomprehensible God!

Yet Your loving-kindness draws me to You,
And Your promise gives me steadfast hope.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_28.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_28.mp3"
        ),
        NarekPrayer(
            id: 29,
            banNumber: "Բան ԻԹ",
            titleHy: "Խոստովանութիւն անօրէնութեանց (Բան ԻԹ)",
            titleRu: "Исповедание неправд и немощей (Глава 29)",
            titleEn: "Confession of Transgressions (Chapter 29)",
            textHy: """
Մեղայ քեզ, Տէր, մեղայ,
Եւ զանօրէնութիւնս իմ ես ինձէն գիտեմ:
Այլ աղաչեմ և խնդրեմ ի քէն,
Թող ինձ, Տէր, և ներեա:
""",
            textRu: """
Согрешил я перед Тобой, Господи, согрешил,
И беззакония мои знаю я сам.
Но молю и прошу Тебя:
Прости мне, Господи, и помилуй.
""",
            textEn: """
I have sinned against You, O Lord, I have sinned,
And my transgressions I know full well.
Yet I pray and beseech You:
Forgive me, O Lord, and have mercy.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_29.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_29.mp3"
        ),
        NarekPrayer(
            id: 30,
            banNumber: "Բան Լ",
            titleHy: "Ապաւինութիւն ի փրկիչն Քրիստոս (Բան Լ)",
            titleRu: "Упование на Спасителя Христа (Глава 30)",
            titleEn: "Trust in Christ the Savior (Chapter 30)",
            textHy: """
Դու ես կեանքը իմ, ով Քրիստոս,
Դու ես յարութիւնն և լոյսը հոգւոյս:
Քեզ եմ հաւատում և քեզ երկրպագում,
Օրհնեալ յաւիտեանս:
""",
            textRu: """
Ты — жизнь моя, о Христе,
Ты — воскресение и свет души моей.
В Тебя верую и Тебе поклоняюсь,
Благословенный во веки веков.
""",
            textEn: """
You are my life, O Christ,
You are the resurrection and light of my soul.
In You I believe and You I worship,
Blessed forever and ever.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_30.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_30.mp3"
        ),
        NarekPrayer(
            id: 31,
            banNumber: "Բան ԼԱ",
            titleHy: "Ի խորոց սրտի խօսք ընդ Աստուծոյ (Բան ԼԱ)",
            titleRu: "Из глубины сердца слова к Богу (Глава 31)",
            titleEn: "Speaking with God from the Depths of the Heart (Chapter 31)",
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
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_31.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_31.mp3"
        ),
        NarekPrayer(
            id: 32,
            banNumber: "Բան ԼԲ",
            titleHy: "Աղերս առ ամենակալն Աստուած (Բան ԼԲ)",
            titleRu: "Моление к Вседержителю Богу (Глава 32)",
            titleEn: "Plea to God Almighty (Chapter 32)",
            textHy: """
Առ քեզ եմ նայում, լոյս ճշմարիտ,
Որ լուսաւորում ես ամէն մարդու,
Որ գալիս է այս աշխարհ:

Փրկիր ինձ մեղաց ծովից,
Եւ հաստատիր ոտքերս քո վեմի վրայ:
""",
            textRu: """
К Тебе возвожу взор мой, Свет Истинный,
Просвещающий всякого человека,
Приходящего в этот мир.

Избави меня от пучины греховной
И утверди стопы мои на камне веры Твоей.
""",
            textEn: """
To You I lift up my eyes, O True Light,
Who enlightens every person
Coming into the world.

Save me from the abyss of sin
And establish my feet upon the rock of Your faith.
""",
            audioUrlHy: "https://archive.org/download/narekatsi-audio/sos_sargsyan_ban_32.mp3",
            audioUrlRu: "https://archive.org/download/narekatsi-audio/oleg_molenko_ban_32.mp3"
        )
    ]  // prayersPart1 (главы 1-32)

    /// Полная коллекция: все 95 глав из трёх частей
    lazy var prayers: [NarekPrayer] = NarekatsiDatabase.prayersPart1
        + NarekatsiDatabase.prayersPart2
        + NarekatsiDatabase.prayersPart3
}

// MARK: - Что в приложении настоящее, а что нет
// В приложении есть две полные студийные записи «Книги скорбных песнопений» (армянская и русская). А текст под номерами
// 1–95 — это пять молитв «в духе Нарекаци», которые раньше повторялись по кругу; дословным текстом книги они не являются.
extension NarekPrayer {
    /// Собственный текст есть только у первых пяти номеров; остальные девяносто раньше повторяли их по кругу
    var hasOwnText: Bool { id <= 5 }

    /// Подпись главы записи: только номер, без придуманных названий
    func chapterLabel(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return banNumber
        case .russian: return "Глава \(id)"
        case .english: return "Chapter \(id)"
        }
    }

    /// Название молитвы без хвоста «(Глава N)»
    func inspiredTitle(for language: AppLanguage) -> String {
        let full = title(for: language)
        guard let open = full.lastIndex(of: "(") else { return full }
        return String(full[..<open]).trimmingCharacters(in: .whitespaces)
    }

    /// Отметка времени точная только для глав, которые размечены по записи; остальные рассчитаны примерно
    func isTimestampExact(for language: AppLanguage) -> Bool {
        language == .armenian ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 41].contains(id) : id <= 10
    }

    /// Отметка времени для списка: приблизительная помечается «≈»
    func timestampLabel(for language: AppLanguage) -> String {
        (isTimestampExact(for: language) ? "" : "≈ ") + formattedTimestamp(for: language)
    }
}

extension NarekatsiDatabase {
    /// Пять молитв «в духе Нарекаци» с собственным текстом
    var inspiredPrayers: [NarekPrayer] { prayers.filter { $0.hasOwnText } }
}

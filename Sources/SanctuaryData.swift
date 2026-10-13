import Foundation
import CoreLocation

// MARK: - «Карта святынь»: монастыри и храмы Армении
// Координаты и исторические сведения сверены с Википедией (статьи о каждом памятнике на английском языке),
// даты праздников берутся из церковного календаря приложения.

/// Текст на трёх языках: Armenian, Russian, English
struct L3 {
    let hy: String
    let ru: String
    let en: String

    init(_ hy: String, _ ru: String, _ en: String) {
        self.hy = hy
        self.ru = ru
        self.en = en
    }

    func callAsFunction(_ language: AppLanguage) -> String {
        switch language {
        case .armenian: return hy
        case .russian: return ru
        case .english: return en
        }
    }
}

struct Sanctuary: Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let name: L3
    let region: L3
    let era: L3
    let history: L3
    /// Праздники церковного календаря, связанные с местом (хвосты id из ChurchCalendarService)
    let feastIds: [String]
    /// Стих, подходящий месту: книга, глава, стих (номера книг 1–66)
    let verse: (bookId: Int, chapter: Int, verse: Int)?
    /// Бесплатно открытые святыни; остальные — с Premium
    let isFree: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }
}

enum SanctuaryCatalog {
    static let all: [Sanctuary] = [
        Sanctuary(
            id: "etchmiadzin",
            latitude: 40.1619, longitude: 44.2910,
            name: L3("Մայր Աթոռ Սուրբ Էջմիածին", "Первопрестольный Святой Эчмиадзин", "Holy Etchmiadzin"),
            region: L3("Արմավիր", "Армавир", "Armavir"),
            era: L3("301–303", "301–303", "301–303"),
            history: L3(
                "Հայ Առաքելական Եկեղեցու մայր տաճարը: Ավանդության համաձայն՝ այն կառուցել է Սուրբ Գրիգոր Լուսավորիչը 301–303 թվականներին՝ Հայաստանի քրիստոնեության ընդունումից հետո, հեթանոսական տաճարի տեղում: Ներկա շենքի միջուկը վերաբերում է 483–484 թվականներին: 1441 թվականից այն կրկին Ամենայն հայոց կաթողիկոսի աթոռն է:",
                "Кафедральный собор Армянской Апостольской Церкви. По преданию, его построил св. Григорий Просветитель в 301–303 годах, после принятия Арменией христианства, на месте языческого храма. Ядро нынешнего здания относится к 483–484 годам. С 1441 года здесь снова находится престол Католикоса всех армян.",
                "The mother church of the Armenian Apostolic Church. According to tradition it was built between 301 and 303 by St. Gregory the Illuminator, after Armenia adopted Christianity, on the site of a pagan temple. The core of the present building dates from 483/484. Since 1441 it has again been the seat of the Catholicos of All Armenians."
            ),
            feastIds: ["holy_etchmiadzin", "shoghakat_etchmiadzin"],
            verse: (40, 16, 18),
            isFree: true
        ),
        Sanctuary(
            id: "hripsime",
            latitude: 40.1670, longitude: 44.3095,
            name: L3("Սուրբ Հռիփսիմե եկեղեցի", "Церковь Св. Рипсиме", "St. Hripsime Church"),
            region: L3("Արմավիր", "Армавир", "Armavir"),
            era: L3("618", "618", "618"),
            history: L3(
                "Կառուցվել է 618 թվականին Կոմիտաս կաթողիկոսի կողմից՝ Սուրբ Հռիփսիմեի գերեզմանի վրա: Եկեղեցին գրեթե անփոփոխ պահպանվել է VII դարից և համարվում է հայկական դասական ճարտարապետության գլուխգործոց: Այն Էջմիածնի հետ ընդգրկված է ՅՈՒՆԵՍԿՕ-ի Համաշխարհային ժառանգության ցանկում:",
                "Построена в 618 году католикосом Комитасом над гробницей св. Рипсиме, девы и мученицы времён крещения Армении. Церковь почти без изменений дожила с VII века и считается шедевром классической армянской архитектуры. Вместе с Эчмиадзином входит в список Всемирного наследия ЮНЕСКО.",
                "Built in 618 by Catholicos Komitas over the tomb of St. Hripsime, a virgin martyr of the Christianization of Armenia. The church has stood almost unchanged since the 7th century and is a masterpiece of classical Armenian architecture. Together with Etchmiadzin it is part of a UNESCO World Heritage Site."
            ),
            feastIds: ["st_hripsime"],
            verse: (40, 5, 8),
            isFree: false
        ),
        Sanctuary(
            id: "gayane",
            latitude: 40.1574, longitude: 44.2920,
            name: L3("Սուրբ Գայանե եկեղեցի", "Церковь Св. Гаяне", "St. Gayane Church"),
            region: L3("Արմավիր", "Армавир", "Armavir"),
            era: L3("630", "630", "630"),
            history: L3(
                "Կառուցվել է 630 թվականին Եզր Ա կաթողիկոսի կողմից՝ 301 թվականին նահատակված Սուրբ Գայանեի հիշատակին կապված վայրում: VII դարի եկեղեցին վաղ միջնադարյան հայկական եկեղեցիներից լավագույնս պահպանվածներից է և գտնվում է Մայր տաճարից քայլելու հեռավորության վրա:",
                "Построена в 630 году католикосом Езром I на месте, связанном с памятью св. Гаяне, игуменьи, принявшей мученическую смерть в 301 году. Церковь VII века — одна из лучше всего сохранившихся раннесредневековых армянских церквей; от Эчмиадзинского собора до неё можно дойти пешком.",
                "Built in 630 by Catholicos Ezra I on a site tied to the memory of St. Gayane, an abbess martyred with her companions in 301. The 7th-century church is among the best-preserved early medieval Armenian churches and lies within walking distance of Etchmiadzin Cathedral."
            ),
            feastIds: ["st_gayane"],
            verse: (66, 2, 10),
            isFree: false
        ),
        Sanctuary(
            id: "zvartnots",
            latitude: 40.1597, longitude: 44.3366,
            name: L3("Զվարթնոց", "Звартноц", "Zvartnots Cathedral"),
            region: L3("Արմավիր", "Армавир", "Armavir"),
            era: L3("643–652", "643–652", "643–652"),
            history: L3(
                "Կլոր տաճարի ավերակները: Շինարարությունը սկսել է Ներսես Գ Շինող կաթողիկոսը 643 թվականին, իսկ Մովսես Կաղանկատվացու համաձայն՝ օծվել է 652 թվականին: Շինության շրջանաձև կառուցվածքը եզակի էր միջնադարյան հայկական ճարտարապետության մեջ: Այն փլուզվել է հետագա դարերում՝ երկրաշարժից կամ արաբական արշավանքներից (պատճառը վիճելի է):",
                "Руины круглого собора. Строительство начал в 643 году католикос Нерсес III Строитель; по сообщению историка Мовсеса Каганкатваци, храм освящён в 652 году. Круглая в плане постройка была уникальной для средневековой армянской архитектуры. Позднее собор разрушился — от землетрясения или арабских набегов (причина остаётся предметом споров).",
                "The ruins of a circular cathedral begun in 643 by Catholicos Nerses III the Builder and, according to the historian Movses Kaghankatvatsi, consecrated in 652. Its round plan was unique in medieval Armenian architecture. It later collapsed, from an earthquake or Arab raids (the cause is still debated)."
            ),
            feastIds: [],
            verse: (58, 1, 14),
            isFree: false
        ),
        Sanctuary(
            id: "khor_virap",
            latitude: 39.8783, longitude: 44.5761,
            name: L3("Խոր Վիրապ", "Хор Вирап", "Khor Virap"),
            region: L3("Արարատ", "Арарат", "Ararat"),
            era: L3("642 · 1662", "642 · 1662", "642 · 1662"),
            history: L3(
                "Այստեղ Սուրբ Գրիգոր Լուսավորիչը 13 տարի բանտարկված էր Տրդատ Գ թագավորի կողմից՝ նախքան թագավորին բուժելը և 301 թվականին Հայաստանը մկրտելը: Մատուռն այստեղ առաջին անգամ կառուցել է Ներսես Գ Շինողը 642 թվականին, իսկ ներկայիս Սուրբ Աստվածածին եկեղեցին՝ 1662 թվականին: Վանքը գտնվում է Թուրքիայի սահմանից մի քանի կիլոմետր հեռավորության վրա՝ Արարատ լեռան տեսարանով:",
                "Здесь царь Трдат III держал в заточении св. Григория Просветителя 13 лет — до того, как Григорий исцелил царя и в 301 году крестил Армению. Первую часовню на этом месте построил в 642 году Нерсес III Строитель; нынешняя церковь Св. Богородицы возведена вокруг её руин в 1662 году. Монастырь стоит в нескольких километрах от границы с Турцией, с видом на гору Арарат.",
                "Here St. Gregory the Illuminator was imprisoned for 13 years by King Tiridates III, before he healed the king and baptized Armenia in 301. A chapel was first built on the site in 642 by Nerses III the Builder; the present St. Astvatsatsin (Holy Mother of God) church was built around its ruins in 1662. The monastery stands a few kilometres from the Turkish border, with a view of Mount Ararat."
            ),
            feastIds: ["khor_virap_exit", "gregory_pit"],
            verse: (44, 16, 25),
            isFree: true
        ),
        Sanctuary(
            id: "geghard",
            latitude: 40.1404, longitude: 44.8185,
            name: L3("Գեղարդավանք", "Гегард", "Geghard Monastery"),
            region: L3("Կոտայք", "Котайк", "Kotayk"),
            era: L3("IV դ. · 1215", "IV в. · 1215", "4th c. · 1215"),
            history: L3(
                "Լեռան մեջ մասամբ փորագրված վանք: Ըստ ավանդության՝ հիմնադրել է Սուրբ Գրիգոր Լուսավորիչը IV դարում՝ քարանձավում գտնվող սուրբ աղբյուրի մոտ, այդ պատճառով վաղ անվանվել է Այրիվանք: «Գեղարդ» նշանակում է նիզակ. ըստ ավանդության՝ Քրիստոսին խոցած նիզակը Հայաստան է բերել Թադեոս առաքյալը, և այն պահվել է այստեղ (այժմ՝ Մայր Աթոռի գանձարանում): Գլխավոր մատուռը կառուցվել է 1215 թվականին, վանքը ՅՈՒՆԵՍԿՕ-ի ցանկում է:",
                "Монастырь, частично высеченный в скале. По преданию, основан в IV веке св. Григорием Просветителем у священного источника в пещере — отсюда древнее название Айриванк, «монастырь пещеры». «Гегард» значит «копьё»: копьё, пронзившее Христа, по преданию, привёз в Армению апостол Фаддей, и оно хранилось здесь (сейчас — в сокровищнице Эчмиадзина). Главная часовня построена в 1215 году; монастырь входит в список Всемирного наследия ЮНЕСКО.",
                "A monastery partly carved out of the mountain. According to tradition it was founded in the 4th century by St. Gregory the Illuminator at a sacred spring inside a cave, hence its old name Ayrivank, “monastery of the cave”. “Geghard” means “spear”: the lance that wounded Christ was, by tradition, brought to Armenia by the Apostle Thaddeus and kept here (it is now in the Etchmiadzin treasury). The main chapel dates from 1215, and the monastery is a UNESCO World Heritage Site."
            ),
            feastIds: [],
            verse: (43, 19, 34),
            isFree: false
        ),
        Sanctuary(
            id: "noravank",
            latitude: 39.6841, longitude: 45.2329,
            name: L3("Նորավանք", "Нораванк", "Noravank"),
            region: L3("Վայոց ձոր", "Вайоц-Дзор", "Vayots Dzor"),
            era: L3("XIII–XIV դդ.", "XIII–XIV вв.", "13th–14th c."),
            history: L3(
                "XIII դարի վանք Եղեգնաձորի մոտ՝ աղյուսակարմիր ժայռերով նեղ կիրճում: XIII–XIV դարերում այն դարձավ Սյունիքի եպիսկոպոսների նստավայրը: Ամենահայտնի շինությունը երկհարկանի Սուրբ Աստվածածին եկեղեցին է, որն ավարտվել է 1339 թվականին՝ քանդակագործ և մանրանկարիչ Մոմիկի վերջին գործը:",
                "Монастырь XIII века в узком ущелье с кирпично-красными скалами близ Ехегнадзора. В XIII–XIV веках стал резиденцией сюникских епископов. Самое известное здание — двухэтажная церковь Св. Богородицы, завершённая в 1339 году, последняя работа скульптора и миниатюриста Момика.",
                "A 13th-century monastery in a narrow gorge of brick-red cliffs near Yeghegnadzor. In the 13th–14th centuries it became the residence of the bishops of Syunik. Its best-known building is the two-storey Surb Astvatsatsin (Holy Mother of God) Church, completed in 1339 as the last work of the sculptor and miniaturist Momik."
            ),
            feastIds: [],
            verse: (23, 2, 3),
            isFree: false
        ),
        Sanctuary(
            id: "areni",
            latitude: 39.7241, longitude: 45.1895,
            name: L3("Արենու Սուրբ Աստվածածին", "Церковь Св. Богородицы в Арени", "Areni Holy Mother of God Church"),
            region: L3("Վայոց ձոր", "Вайоц-Дзор", "Vayots Dzor"),
            era: L3("1321", "1321", "1321"),
            history: L3(
                "Միանավ գմբեթավոր Սուրբ Աստվածածին եկեղեցի, ավարտվել է 1321 թվականին: Գտնվում է Արփա գետի և Արենի գյուղի վերևի սարահարթում:",
                "Однонефная купольная церковь Св. Богородицы, завершённая в 1321 году. Стоит на плато над рекой Арпа и селом Арени.",
                "A single-nave domed church of the Holy Mother of God, completed in 1321. It stands on a plateau above the Arpa River and the village of Areni."
            ),
            feastIds: [],
            verse: (42, 1, 46),
            isFree: false
        ),
        Sanctuary(
            id: "tatev",
            latitude: 39.3794, longitude: 46.2500,
            name: L3("Տաթևի վանք", "Татев", "Tatev Monastery"),
            region: L3("Սյունիք", "Сюник", "Syunik"),
            era: L3("895–906", "895–906", "895–906"),
            history: L3(
                "IX դարի վանք Որոտանի կիրճի եզրին, Սյունիքի եպիսկոպոսների աթոռանիստը: Սուրբ Պողոս-Պետրոս եկեղեցին կառուցվել է 895–906 թվականներին: XIV–XV դարերում այստեղ գործել է Տաթևի համալսարանը՝ միջնադարյան Հայաստանի ամենակարևոր համալսարաններից մեկը:",
                "Монастырь IX века на краю ущелья реки Воротан, кафедра сюникских епископов. Церковь свв. Павла и Петра построена в 895–906 годах. В XIV–XV веках здесь действовал Татевский университет — один из важнейших университетов средневековой Армении.",
                "A 9th-century monastery on the edge of the Vorotan gorge, seat of the bishops of Syunik. The church of Saints Paul and Peter was built between 895 and 906. In the 14th–15th centuries it housed the University of Tatev, one of the most important medieval Armenian universities."
            ),
            feastIds: ["st_peter_paul"],
            verse: (55, 4, 7),
            isFree: false
        ),
        Sanctuary(
            id: "sevanavank",
            latitude: 40.5639, longitude: 45.0108,
            name: L3("Սևանավանք", "Севанаванк", "Sevanavank"),
            region: L3("Գեղարքունիք", "Гегаркуник", "Gegharkunik"),
            era: L3("874", "874", "874"),
            history: L3(
                "Արձանագրության համաձայն՝ վանքը հիմնադրել է Աշոտ Ա-ի դուստր Մարիամ իշխանուհին 874 թվականին: Այն գտնվում է Սևանա լճի թերակղզում, որը լճի մակարդակի մոտ 20 մետր իջնելուց առաջ կղզի էր: Այսօր Հայաստանի ամենաայցելվող վայրերից է, գործում է ճեմարան:",
                "По надписи в одной из церквей, монастырь основала в 874 году княжна Мариам, дочь Ашота I. Он стоит на полуострове озера Севан, который был островом, пока уровень озера не упал примерно на 20 метров. Сегодня это одно из самых посещаемых мест Армении, при монастыре действует семинария.",
                "According to an inscription in one of its churches, the monastery was founded in 874 by Princess Mariam, daughter of Ashot I. It stands on a peninsula of Lake Sevan that was an island until the lake level fell by about 20 metres. It is one of the most visited sights in Armenia, and its seminary is still active."
            ),
            feastIds: [],
            verse: (40, 4, 18),
            isFree: false
        ),
        Sanctuary(
            id: "haghpat",
            latitude: 41.0939, longitude: 44.7119,
            name: L3("Հաղպատավանք", "Ахпат", "Haghpat Monastery"),
            region: L3("Լոռի", "Лори", "Lori"),
            era: L3("976–991", "976–991", "976–991"),
            history: L3(
                "X–XIII դարերում կառուցված վանական համալիր, հավանաբար հիմնադրվել է 976 թվականին Բագրատունի Աշոտ Գ թագավորի կինը՝ Խոսրովանույշ թագուհու կողմից: Ամենամեծ եկեղեցին՝ Սուրբ Նշանը, ավարտվել է 991 թվականին: Սանահինի հետ ներառված է ՅՈՒՆԵՍԿՕ-ի Համաշխարհային ժառանգության ցանկում:",
                "Монастырский комплекс X–XIII веков, основанный, вероятно, в 976 году царицей Хосровануйш, женой багратидского царя Ашота III. Самая большая церковь, Сурб Ншан, завершена в 991 году. Вместе с Санаином входит в список Всемирного наследия ЮНЕСКО.",
                "A monastery complex built between the 10th and 13th centuries and founded, probably in 976, by Queen Khosrovanuysh, wife of the Bagratid king Ashot III. The largest church, Surb Nshan, was completed in 991. With Sanahin it forms a UNESCO World Heritage Site."
            ),
            feastIds: [],
            verse: (51, 3, 16),
            isFree: false
        ),
        Sanctuary(
            id: "sanahin",
            latitude: 41.0872, longitude: 44.6661,
            name: L3("Սանահինի վանք", "Санаин", "Sanahin Monastery"),
            region: L3("Լոռի", "Лори", "Lori"),
            era: L3("966", "966", "966"),
            history: L3(
                "Հիմնադրվել է X դարում. Սուրբ Ամենափրկիչ եկեղեցին 966 թվականին կառուցել են Աշոտ Գ թագավորը և Խոսրովանույշ թագուհին: Անունը նշանակում է «սա ավելի հին է, քան այն»՝ հարևան Հաղպատի նկատմամբ հնության հավակնություն, վանքերը իրարից 3 կմ հեռավորության վրա են: Երկուսը միասին ՅՈՒՆԵՍԿՕ-ի ցանկում են:",
                "Основан в X веке; церковь Св. Спасителя (Аменапркич) построили в 966 году царь Ашот III и царица Хосровануйш. Название означает «этот древнее того» — шутливая претензия на старшинство перед соседним Ахпатом, до которого около 3 км. Вместе они входят в список Всемирного наследия ЮНЕСКО.",
                "Founded in the 10th century; the Church of the Holy Saviour (Amenaprkich) was built in 966 by King Ashot III and Queen Khosrovanuysh. The name means “this one is older than that one”, a claim of seniority over neighbouring Haghpat, about 3 km away. Together they form a UNESCO World Heritage Site."
            ),
            feastIds: [],
            verse: (20, 9, 10),
            isFree: false
        ),
        Sanctuary(
            id: "saghmosavank",
            latitude: 40.3805, longitude: 44.3967,
            name: L3("Սաղմոսավանք", "Сагмосаванк", "Saghmosavank"),
            region: L3("Արագածոտն", "Арагацотн", "Aragatsotn"),
            era: L3("1215", "1215", "1215"),
            history: L3(
                "«Սաղմոսների վանքը»՝ Կասաղ գետի կիրճի եզրին, Արագած լեռան ստորոտին: Սիոն եկեղեցին կառուցել է Վաչե Վաչուտյան իշխանը 1215 թվականին, ժամատունը՝ նրա որդի Քուրդը 1255 թվականին:",
                "«Монастырь Псалмов» на краю ущелья реки Касах, у подножия Арагаца. Церковь Сион построил в 1215 году князь Вахе Вачутян, а притвор (жаматтун) добавил в 1255 году его сын Курд.",
                "The “Monastery of the Psalms”, on the edge of the Kasagh gorge below Mount Aragats. The Church of Zion was built in 1215 by Prince Vache Vachutyan; the gavit (zhamatun) was added in 1255 by his son Kurt."
            ),
            feastIds: [],
            verse: (49, 5, 19),
            isFree: false
        ),
        Sanctuary(
            id: "goshavank",
            latitude: 40.7299, longitude: 44.9977,
            name: L3("Գոշավանք", "Гошаванк", "Goshavank"),
            region: L3("Տավուշ", "Тавуш", "Tavush"),
            era: L3("XII–XIII դդ.", "XII–XIII вв.", "12th–13th c."),
            history: L3(
                "Կառուցվել է 1188 թվականի երկրաշարժից ավերված Նոր Գետիկ վանքի տեղում: Վերակառուցմանը մասնակցել է Մխիթար Գոշը՝ պետական գործիչ, առակագիր և օրենսգրքի հեղինակ, որը այստեղ դպրոց է հիմնել:",
                "Построен на месте старого монастыря Нор Гетик, разрушенного землетрясением 1188 года. В восстановлении участвовал Мхитар Гош — государственный деятель, автор басен и свода законов; здесь он основал школу.",
                "Built in the place of the older monastery of Nor Getik, destroyed by an earthquake in 1188. Mkhitar Gosh, a statesman, writer of fables and author of a law code, took part in the rebuilding and founded a school here."
            ),
            feastIds: [],
            verse: (40, 13, 3),
            isFree: false
        ),
        Sanctuary(
            id: "kecharis",
            latitude: 40.5324, longitude: 44.7196,
            name: L3("Կեչառիս", "Кечарис", "Kecharis Monastery"),
            region: L3("Կոտայք", "Котайк", "Kotayk"),
            era: L3("XI–XIII դդ.", "XI–XIII вв.", "11th–13th c."),
            history: L3(
                "XI–XIII դարերի վանական համալիր Ծաղկաձորում, հիմնադրվել է Պահլավունի իշխանի կողմից: XII–XIII դարերում այն Հայաստանի կարևոր կրոնական և կրթական կենտրոն էր:",
                "Монастырский комплекс XI–XIII веков в Цахкадзоре, основанный князем из рода Пахлавуни. В XII–XIII веках — крупный религиозный и образовательный центр Армении.",
                "A monastic complex from the 11th to 13th centuries in Tsaghkadzor, founded by a Pahlavuni prince. In the 12th–13th centuries it was a major religious and educational centre of Armenia."
            ),
            feastIds: [],
            verse: (59, 1, 5),
            isFree: false
        ),
        Sanctuary(
            id: "yerevan_cathedral",
            latitude: 40.1719, longitude: 44.5169,
            name: L3("Սուրբ Գրիգոր Լուսավորիչ մայր եկեղեցի", "Собор Св. Григория Просветителя (Ереван)", "St. Gregory the Illuminator Cathedral, Yerevan"),
            region: L3("Երևան", "Ереван", "Yerevan"),
            era: L3("2001", "2001", "2001"),
            history: L3(
                "Հայ Առաքելական Եկեղեցու ամենամեծ տաճարը, նախագծել է ճարտարապետ Ստեփան Քյուրքչյանը, օծվել է 2001 թվականի սեպտեմբերի 23-ին՝ Հայաստանում քրիստոնեության պետական կրոն հռչակվելու 1700-ամյակի առիթով: Համալիրն ընդգրկում է տաճարը և Տրդատ թագավորի ու Աշխեն թագուհու մատուռները:",
                "Крупнейший собор Армянской Апостольской Церкви, спроектированный архитектором Степаном Кюркчяном и освящённый 23 сентября 2001 года к 1700-летию провозглашения христианства государственной религией Армении. Комплекс включает собор и часовни царя Трдата и царицы Ашхен.",
                "The largest cathedral of the Armenian Apostolic Church, designed by the architect Stepan Kurkchyan and consecrated on 23 September 2001 for the 1700th anniversary of Armenia's adoption of Christianity. The complex combines the cathedral with the chapels of St. Tiridates the King and St. Ashkhen the Queen."
            ),
            feastIds: ["relics_st_gregory"],
            verse: (40, 5, 14),
            isFree: false
        )
    ]

    static func site(id: String) -> Sanctuary? {
        all.first { $0.id == id }
    }

    /// Ближайший по календарю праздник из связанных с местом
    @MainActor
    static func nextFeast(for site: Sanctuary) -> ArmenianChurchFeast? {
        guard !site.feastIds.isEmpty else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        var candidates: [ArmenianChurchFeast] = []
        for y in [year, year + 1] {
            let wanted = Set(site.feastIds.map { "\(y)_\($0)" })
            candidates += ChurchCalendarService.shared.feasts(for: y).filter { wanted.contains($0.id) }
        }
        return candidates
            .filter { calendar.startOfDay(for: $0.date) >= today }
            .min { $0.date < $1.date }
    }

    /// Стих места из Библии приложения: текст берётся из базы, поэтому всегда точный
    static func verse(for site: Sanctuary, language: AppLanguage) -> (text: String, reference: String)? {
        guard let ref = site.verse,
              let chapter = BibleDatabase.shared.getChapterText(bookId: ref.bookId, chapter: ref.chapter),
              let verse = chapter.verses.first(where: { $0.verseNumber == ref.verse }) else { return nil }
        let text = verse.text(for: language).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let book: String
        switch language {
        case .armenian: book = chapter.book.nameHy
        case .russian: book = chapter.book.nameRu
        case .english: book = chapter.book.nameEn
        }
        return (text, "\(book) \(ref.chapter):\(ref.verse)")
    }
}

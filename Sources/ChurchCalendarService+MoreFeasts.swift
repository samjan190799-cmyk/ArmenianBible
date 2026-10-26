import Foundation

extension ChurchCalendarService {
    // MARK: - Праздники, которые сверка с календарём Первопрестольного Святого Эчмиадзина добавила к основному списку
    //
    // Даты сверены с календарём Эчмиадзина (armenianchurch.org) и календарём Армянской Церкви в Грузии
    // (armenianchurch.ge) за 2021–2030 годы. Молитвы не заполнены намеренно: текстов, которые можно
    // подтвердить по источникам, нет, а выдумывать молитвословие приложение не должно.
    func additionalFeasts(for year: Int, easter: Date, assumptionSunday: Date) -> [ArmenianChurchFeast] {
        var list: [ArmenianChurchFeast] = []

        // Страдания св. Григория Просветителя и заключение в яму (суббота Великого Поста, за 15 дней до Пасхи)
        list.append(ArmenianChurchFeast(
            id: "\(year)_gregory_pit",
            type: .saints,
            date: dateByAdding(days: -15, to: easter),
            titleHy: "Սուրբ Գրիգոր Լուսավորչի չարչարանքների և Խոր Վիրապ նետվելու հիշատակություն",
            titleRu: "Страдания св. Григория Просветителя и заключение в яму (Хор Вирап)",
            titleEn: "St. Gregory the Illuminator's Torments and Imprisonment in the Pit",
            descriptionHy: "Առաջինն է Սուրբ Գրիգոր Լուսավորչին նվիրված երեք հիշատակության օրերից: Տոնվում է Մեծ պահքի շաբաթ օրը՝ ի հիշատակ այն չարչարանքների, որ Գրիգորը կրեց Տրդատ թագավորից, և Խոր Վիրապում նրա 13 տարվա բանտարկության:",
            descriptionRu: "Первый из трёх дней памяти св. Григория Просветителя, первого Католикоса всех армян. Совершается в субботу Великого Поста в память мук, которые Григорий принял от царя Трдата, и его тринадцатилетнего заключения в глубокой яме Хор Вирапа.",
            descriptionEn: "The first of the three commemoration days of St. Gregory the Illuminator, the first Catholicos of All Armenians. Kept on a Saturday of Great Lent in memory of the torments he suffered under King Tiridates and his thirteen years in the pit of Khor Virap.",
            meaningHy: "Գրիգորի հավատարմությունը Քրիստոսին տանջանքների մեջ դարձավ Հայաստանի մեծ դարձի սկիզբը՝ 301 թվականին նա դուրս եկավ վիրապից և լուսավորեց հայ ժողովրդին:",
            meaningRu: "Верность Григория Христу среди мучений стала началом великого обращения Армении: в 301 году он вышел из ямы и просветил армянский народ.",
            meaningEn: "Gregory's faithfulness to Christ amid torment became the beginning of Armenia's great conversion: in 301 he came out of the pit and enlightened the Armenian nation.",
            traditionsHy: "",
            traditionsRu: "",
            traditionsEn: "",
            scriptureReading: "",
            prayerHy: "",
            prayerRu: "",
            prayerEn: "",
            isFasting: false
        ))

        // Лазарева суббота (Ղազարոսի հարություն — 41-й день Великого Поста, суббота перед Вербным Воскресеньем)
        list.append(ArmenianChurchFeast(
            id: "\(year)_lazarus_saturday",
            type: .dominical,
            date: dateByAdding(days: -8, to: easter),
            titleHy: "Ղազարոսի հարության շաբաթ",
            titleRu: "Лазарева суббота (Воскрешение Лазаря)",
            titleEn: "Lazarus Saturday (Raising of Lazarus)",
            descriptionHy: "Մեծ պահքի 41-րդ օրը Հայ Եկեղեցին հիշատակում է Քրիստոսի կողմից չորսօրյա Ղազարոսի հարությունը՝ Մարթայի և Մարիամի եղբոր:",
            descriptionRu: "На 41-й день Великого Поста Армянская Церковь вспоминает воскрешение Христом четверодневного Лазаря, брата Марфы и Марии, накануне Входа Господня в Иерусалим.",
            descriptionEn: "On the 41st day of Great Lent the Armenian Church remembers Christ raising Lazarus, the brother of Martha and Mary, on the eve of Palm Sunday.",
            meaningHy: "Ղազարոսի հարությունը ապացույց է, որ Քրիստոսն է «հարությունը և կյանքը», և նախանշան բոլոր ննջեցյալների ապագա հարության:",
            meaningRu: "Воскрешение Лазаря свидетельствует, что Христос есть «воскресение и жизнь», и предвозвещает будущее воскресение всех усопших во Христе.",
            meaningEn: "The raising of Lazarus shows that Christ is \"the resurrection and the life\" and foretells the coming resurrection of all who have fallen asleep in Christ.",
            traditionsHy: "",
            traditionsRu: "",
            traditionsEn: "",
            scriptureReading: "Հովհաննես 11:1-46",
            prayerHy: "",
            prayerRu: "",
            prayerEn: "",
            isFasting: false
        ))

        // Память пророка Илии (Եղիա մարգարեի հիշատակություն — воскресенье после недели поста Илии, Пасха + 56 дней)
        list.append(ArmenianChurchFeast(
            id: "\(year)_prophet_elijah",
            type: .saints,
            date: dateByAdding(days: 56, to: easter),
            titleHy: "Եղիա մարգարեի հիշատակություն",
            titleRu: "Память пророка Илии",
            titleEn: "Commemoration of the Prophet Elijah",
            descriptionHy: "Եղիա մարգարեն Հին Կտակարանի մեծագույն մարգարեներից է. նա նախանձախնդրորեն պայքարեց կռապաշտության դեմ, ողջ վերցվեց երկինք և Քրիստոսի հետ երևաց Թաբոր լեռան վրա՝ Պայծառակերպության ժամանակ:",
            descriptionRu: "Память великого ветхозаветного пророка Илии: он ревностно боролся с идолопоклонством, был взят на небо живым и явился со Христом на горе Фавор при Преображении. Совершается в воскресенье, следующее за неделей поста Илии.",
            descriptionEn: "Commemoration of the great Old Testament prophet Elijah, who fought zealously against idolatry, was taken up alive into Heaven, and appeared with Christ on Mount Tabor at the Transfiguration. Kept on the Sunday after the Fast of Elijah.",
            meaningHy: "Եղիայի կյանքը կապում է Հին և Նոր Կտակարանները, իսկ նրա ապաշխարության կոչը հնչում է մինչև Քրիստոսի երկրորդ գալուստը:",
            meaningRu: "Жизнь Илии соединяет Ветхий и Новый Завет, а его призыв к покаянию звучит до Второго пришествия Христа.",
            meaningEn: "Elijah's life joins the Old and New Testaments, and his call to repentance sounds until the Second Coming of Christ.",
            traditionsHy: "",
            traditionsRu: "",
            traditionsEn: "",
            scriptureReading: "",
            prayerHy: "",
            prayerRu: "",
            prayerEn: "",
            isFasting: false
        ))

        // Апостол Фаддей и дева Сандухт (Թադեոս առաքյալ և Սանդուխտ կույս — суббота после Вардавара, Пасха + 104 дня)
        list.append(ArmenianChurchFeast(
            id: "\(year)_thaddeus_sandukht",
            type: .saints,
            date: dateByAdding(days: 104, to: easter),
            titleHy: "Թադեոս առաքյալ և Սանդուխտ կույս",
            titleRu: "Апостол Фаддей и дева Сандухт",
            titleEn: "The Apostle Thaddeus and the Virgin Sandukht",
            descriptionHy: "Թադեոս առաքյալը և Սանդուխտ կույսը Հայ Եկեղեցու ամենահարգված սրբերից են. նրանց անուններին է կապված հայ ժողովրդի մեծ դարձը: Թադեոսը քարոզեց Հայաստանում և դարձի բերեց Սանատրուկ թագավորի դուստր Սանդուխտին. երկուսն էլ նահատակվեցին Շավարշանում:",
            descriptionRu: "Апостол Фаддей и дева Сандухт — одни из самых почитаемых святых Армянской Церкви: с их именами связано великое обращение армянского народа. Фаддей проповедовал в Армении и обратил Сандухт, дочь царя Санатрука; оба приняли мученическую смерть в Шаваршане.",
            descriptionEn: "The Apostle Thaddeus and the Virgin Sandukht are among the most venerated saints of the Armenian Church; the great conversion of the Armenian nation is tied to their names. Thaddeus preached in Armenia and converted Sandukht, daughter of King Sanatruk; both were martyred in Shavarshan.",
            meaningHy: "Նրանց արյունը դարձավ Հայաստանում Քրիստոսի եկեղեցու հիմքերից մեկը՝ Սուրբ Գրիգոր Լուսավորչի քարոզությունից շատ առաջ:",
            meaningRu: "Их кровь стала одним из оснований Церкви Христовой в Армении, задолго до проповеди св. Григория Просветителя.",
            meaningEn: "Their blood became one of the foundations of Christ's Church in Armenia, long before the preaching of St. Gregory the Illuminator.",
            traditionsHy: "",
            traditionsRu: "",
            traditionsEn: "",
            scriptureReading: "",
            prayerHy: "",
            prayerRu: "",
            prayerEn: "",
            isFasting: false
        ))

        // Шогакат Святого Эчмиадзина (Սուրբ Էջմիածնի Շողակաթ — суббота перед Успением Богородицы)
        list.append(ArmenianChurchFeast(
            id: "\(year)_shoghakat_etchmiadzin",
            type: .dominical,
            date: dateByAdding(days: -1, to: assumptionSunday),
            titleHy: "Սուրբ Էջմիածնի Շողակաթ",
            titleRu: "Шогакат Святого Эчмиадзина",
            titleEn: "Apparition (Shoghakat) of Holy Etchmiadzin",
            descriptionHy: "Մայր Աթոռ Սուրբ Էջմիածնի հիմնադրման և օծման տոնը: Սուրբ Գրիգոր Լուսավորչի տեսիլքում Միածինն իջավ երկնքից և ոսկե մուրճով նշեց Մայր տաճարի հիմքի տեղը: Տոնվում է Աստվածածնի Վերափոխման տոնից առաջ ընկած շաբաթ օրը:",
            descriptionRu: "Праздник основания и освящения Кафедрального Собора Первопрестольного Эчмиадзина. В видении св. Григория Просветителя Единородный сошёл с небес и золотым молотом указал место для храма. Совершается в субботу перед Успением Пресвятой Богородицы.",
            descriptionEn: "The feast of the founding and consecration of the Cathedral of the Mother See of Holy Etchmiadzin. In the vision of St. Gregory the Illuminator the Only Begotten descended from Heaven and marked the site of the cathedral with a golden hammer. Kept on the Saturday before the Assumption of the Holy Mother of God.",
            meaningHy: "Շողակաթ նշանակում է լույսի շող. Գրիգորը տեսավ երկնքից իջնող կրակե սյուն: Էջմիածին՝ «Միածնի իջնելը»:",
            meaningRu: "«Шогакат» значит «луч света»: Григорий увидел огненный столп, нисходящий с неба. Эчмиадзин — «сошествие Единородного».",
            meaningEn: "\"Shoghakat\" means a ray of light: Gregory saw a fiery column descending from the sky. Etchmiadzin means \"the descent of the Only Begotten\".",
            traditionsHy: "",
            traditionsRu: "",
            traditionsEn: "",
            scriptureReading: "",
            prayerHy: "",
            prayerRu: "",
            prayerEn: "",
            isFasting: false
        ))

        return list
    }
}

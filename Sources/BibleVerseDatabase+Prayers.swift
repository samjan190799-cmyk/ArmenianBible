import Foundation

// MARK: - Молитвы для виджетов
// Молитвы лежат в shortFaith2 (isPrayer == true). Целые молитвы длиннее, чем помещается в средний виджет,
// поэтому здесь — законченные куски по одному-двум предложениям (в средний виджет на каждом языке попадают те, что не длиннее 100 знаков).
extension BibleVerse {
    /// Молитвы целиком: карточка в приложении и большой виджет
    static var prayers: [BibleVerse] { shortFaith2.filter { $0.isPrayer } }

    /// Всё для категории «Молитвы» в виджетах. Каждый виджет сам берёт то, что влезает по длине:
    /// средний — куски (35–100 знаков), большой — целые молитвы (75–260 знаков)
    static var prayerUnits: [BibleVerse] { prayers + shortPrayers }

    static let shortPrayers: [BibleVerse] = [
        BibleVerse(
            textHy: "Փա՛ռք Քեզ, Տե՛ր Աստված իմ, որ արժանացրիր ինձ այս առավոտյան լույսին։",
            textRu: "Слава Тебе, Господи Боже мой, сподобившему меня сего утреннего света!",
            textEn: "Glory to Thee, my Lord and God, Who hast made me worthy of this morning light!",
            refHy: "Սուրբ Հովհաննես Գառնեցի",
            refRu: "Св. Иоанн Гарнеци",
            refEn: "St. John of Garni",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր ինձ այսօր խաղաղությամբ և առանց փորձության անցկացնել օրը, պահպանիր իմ մտքերը և գործերը Քո սիրո մեջ։ Ամեն։",
            textRu: "Даруй мне провести этот день в мире и без искушений, сохрани помыслы мои и дела в любви Твоей. Аминь.",
            textEn: "Grant me to pass this day in peace and without temptation, keep my thoughts and deeds in Thy love. Amen.",
            refHy: "Սուրբ Հովհաննես Գառնեցի",
            refRu: "Св. Иоанн Гарнеци",
            refEn: "St. John of Garni",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տերը կպահպանի քեզ ամեն չարից, Տերը կպահպանի քո անձը։",
            textRu: "Господь сохранит тебя от всякого зла; сохранит душу твою Господь.",
            textEn: "The Lord shall preserve thee from all evil: he shall preserve thy soul.",
            refHy: "Ճանապարհորդի Աղոթք",
            refRu: "Молитва путешественника",
            refEn: "Traveler's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տերը կպահպանի քո մուտքն ու ելքը այսուհետև մինչև հավիտյան։ Ամեն։",
            textRu: "Господь будет охранять выхождение твое и вхождение твое отныне и вовек. Аминь.",
            textEn: "The Lord shall preserve thy going out and thy coming in from this time forth, and even for evermore. Amen.",
            refHy: "Ճանապարհորդի Աղոթք",
            refRu: "Молитва путешественника",
            refEn: "Traveler's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր մեզ Քո խաղաղությունը, Տե՛ր, որը վեր է ամեն մտքից։",
            textRu: "Даруй нам мир Твой, Господи, который превыше всякого ума.",
            textEn: "Grant us Thy peace, O Lord, which passeth all understanding.",
            refHy: "Աղոթագիրք (Խաղաղության)",
            refRu: "Молитвослов (О мире)",
            refEn: "Prayer Book (For Peace)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Խաղաղեցրու մեր սրտերը, հեռացրու մեր վախերը և տուր մեզ Քո ներկայության ապահովությունը։ Ամեն։",
            textRu: "Умиротвори сердца наши, отгони страхи наши и даруй нам уверенность в Твоем присутствии. Аминь.",
            textEn: "Pacify our hearts, take away our fears, and grant us the security of Thy presence. Amen.",
            refHy: "Աղոթագիրք (Խաղաղության)",
            refRu: "Молитвослов (О мире)",
            refEn: "Prayer Book (For Peace)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Ընկա՛լ քաղցրությամբ, Տեր Աստված հզոր, զդառնացողիս աղաչանս, մատի՛ր գթությամբ առ պատկառեալս դիմոք։",
            textRu: "Прими с благоволением, Господи Боже Вседержитель, горькие моления мои, обрати милостивый взор на кающегося.",
            textEn: "Receive with sweetness, Lord God Almighty, my bitter prayers, look with compassion upon my contrite face.",
            refHy: "Սուրբ Գրիգոր Նարեկացի",
            refRu: "Св. Григор Нарекаци",
            refEn: "St. Gregory of Narek",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Փարատեա՛, ամենապարգև, զամոթական տխրութիւնս, բա՛րձ յինէն զծանր հեծութիւնս։ Ամեն։",
            textRu: "Рассей, Всеблагой, постыдную скорбь мою, сними с меня тяжелое бремя уныния. Аминь.",
            textEn: "Dispel, O All-Giver, my shameful sadness, lift from me this heavy sighing. Amen.",
            refHy: "Սուրբ Գրիգոր Նարեկացի",
            refRu: "Св. Григор Нарекаци",
            refEn: "St. Gregory of Narek",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր Յիսուս Քրիստոս, աճեցրո՛ւ իմ հաւատքը, զօրացրո՛ւ իմ յոյսը և կատարելագործի՛ր իմ սէրը։",
            textRu: "Господи Иисусе Христе, умножь мою веру, укрепи мою надежду и усовершенствуй мою любовь!",
            textEn: "Lord Jesus Christ, increase my faith, strengthen my hope, and perfect my love!",
            refHy: "Աղոթագիրք (Հավատքի)",
            refRu: "Молитвослов (О вере)",
            refEn: "Prayer Book (Of Faith)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր ինձ սիրտ, որ լսի Քո ձայնը, և կամք՝ որ հնազանդուի Քո սուրբ կամքին։ Ամեն։",
            textRu: "Даруй мне сердце, внемлющее Твоему голосу, и волю, покорную Твоей святой воле. Аминь.",
            textEn: "Grant me a heart that listens to Thy voice, and a will obedient to Thy holy will. Amen.",
            refHy: "Աղոթագիրք (Հավատքի)",
            refRu: "Молитвослов (О вере)",
            refEn: "Prayer Book (Of Faith)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Աստուա՛ծ երկնաւոր, օրհնի՛ր իմ ընտանիքը։ Տո՛ւր մեզ խաղաղութիւն, սէր և համերաշխութիւն։",
            textRu: "Отец Небесный, благослови мою семью! Даруй нам мир, любовь и единомыслие.",
            textEn: "Heavenly Father, bless my family! Grant us peace, love, and unity.",
            refHy: "Ընտանեկան Աղոթք",
            refRu: "Семейная молитва",
            refEn: "Family Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Պահպանի՛ր մեզ ամեն չարից և փորձանքից, եղի՛ր մեր տան Պահապանն ու Ապաւէնը։ Ամեն։",
            textRu: "Сохрани нас от всякого зла и невзгод, будь Хранителем и Защитником нашего дома. Аминь.",
            textEn: "Keep us from all evil and adversity, and be the Guardian and Protector of our home. Amen.",
            refHy: "Ընտանեկան Աղոթք",
            refRu: "Семейная молитва",
            refEn: "Family Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր և արարիչ կյանքիս, ծուլության, տխրության, արծաթասիրության և դատարկախոսության հոգին մի՛ տուր ինձ։",
            textRu: "Господи и Владыка живота моего, дух праздности, уныния, любоначалия и празднословия не даждь ми.",
            textEn: "O Lord and Master of my life, take from me the spirit of sloth, despair, lust of power, and idle talk.",
            refHy: "Սուրբ Եփրեմ Ասորի",
            refRu: "Св. Ефрем Сирин",
            refEn: "St. Ephrem the Syrian",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Իսկ ողջախոհության, խոնարհության, համբերության և սիրո հոգին շնորհի՛ր Քո ծառային։ Ամեն։",
            textRu: "Дух же целомудрия, смиренномудрия, терпения и любви даруй ми, рабу Твоему. Аминь.",
            textEn: "But give rather the spirit of chastity, humility, patience, and love to Thy servant. Amen.",
            refHy: "Սուրբ Եփրեմ Ասորի",
            refRu: "Св. Ефрем Сирин",
            refEn: "St. Ephrem the Syrian",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տէր Աստուած մեր, զոր ինչ մեղայ այսօր բանիւ, գործով կամ խորհրդով, որպէս բարերար և մարդասէր Աստուած՝ ներեա՛ ինձ։",
            textRu: "Господи Боже наш, если согрешил я в сей день словом, делом или помышлением, как благой и человеколюбивый Бог, прости мне.",
            textEn: "O Lord our God, if I have sinned this day in word, deed, or thought, as a good and loving God, forgive me.",
            refHy: "Երեկոյան Աղոթք",
            refRu: "Вечерняя молитва",
            refEn: "Evening Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր ինձ խաղաղ քուն և անխռով ննջում, պահպանիր զիս չարի փորձանքից։ Ամեն։",
            textRu: "Даруй мне мирный и безмятежный сон, сохрани меня от всякого зла. Аминь.",
            textEn: "Grant me peaceful and undisturbed sleep, and keep me safe from all evil. Amen.",
            refHy: "Երեկոյան Աղոթք",
            refRu: "Вечерняя молитва",
            refEn: "Evening Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Հա՛յր մեր, որ երկնքում ես, սուրբ թող լինի Քո անունը. Քո արքայությունը թող գա, Քո կամքը թող լինի երկրի վրա, ինչպես երկնքում։",
            textRu: "Отче наш, сущий на небесах! Да святится имя Твое; да приидет Царствие Твое; да будет воля Твоя и на земле, как на небе.",
            textEn: "Our Father which art in heaven, Hallowed be thy name. Thy kingdom come. Thy will be done in earth, as it is in heaven.",
            refHy: "Տերունական աղոթք (1/4)",
            refRu: "Молитва Господня (1/4)",
            refEn: "The Lord's Prayer (1/4)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Մեր հանապազօրյա հացը տո՛ւր մեզ այսօր։ Եվ ներե՛ր մեզ մեր պարտքերը, ինչպես և մենք ենք ներում մեր պարտապաններին։",
            textRu: "Хлеб наш насущный дай нам на сей день; и прости нам долги наши, как и мы прощаем должникам нашим.",
            textEn: "Give us this day our daily bread. And forgive us our debts, as we forgive our debtors.",
            refHy: "Տերունական աղոթք (2/4)",
            refRu: "Молитва Господня (2/4)",
            refEn: "The Lord's Prayer (2/4)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Եվ մի՛ տանիր մեզ փորձության, այլ փրկի՛ր մեզ չարից։",
            textRu: "И не введи нас в искушение, но избавь нас от лукавого.",
            textEn: "And lead us not into temptation, but deliver us from evil.",
            refHy: "Տերունական աղոթք (3/4)",
            refRu: "Молитва Господня (3/4)",
            refEn: "The Lord's Prayer (3/4)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Որովհետև Քոնն է արքայությունը և զորությունը և փառքը հավիտյանս։ Ամեն։",
            textRu: "Ибо Твое есть Царство и сила и слава вовеки. Аминь.",
            textEn: "For thine is the kingdom, and the power, and the glory, for ever. Amen.",
            refHy: "Տերունական աղոթք (4/4)",
            refRu: "Молитва Господня (4/4)",
            refEn: "The Lord's Prayer (4/4)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Պահապա՛ն ամենայնի Քրիստոս, աջ Քո հովանի լիցի ի վերայ իմ, ի տուէ և ի գիշերի։",
            textRu: "Хранитель всех, Христос! Да будет десница Твоя сенью надо мною днем и ночью.",
            textEn: "O Christ, guardian of all, let Thy right hand be a shadow over me day and night.",
            refHy: "Սուրբ Ներսես Շնորհալի",
            refRu: "Св. Нерсес Шнорали",
            refEn: "St. Nerses the Gracious",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր իմ և Աստվա՛ծ իմ, Քո սիրո և ողորմության համար ներիր իմ բոլոր մեղքերը, որոնք գործել եմ Քո սուրբ կամքի դեմ։",
            textRu: "Господи мой и Бог мой! Ради Твоей любви и милосердия прости все грехи мои, содеянные против Твоей святой воли.",
            textEn: "My Lord and my God, for the sake of Thy love and mercy, forgive all my sins which I have committed against Thy holy will.",
            refHy: "Աղոթագիրք (Զղջման)",
            refRu: "Молитвослов (Покаянная)",
            refEn: "Prayer Book (Repentance)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Լվա՛ ինձ իմ անօրենությունից և մաքրիր ինձ իմ մեղքերից։ Ամեն։",
            textRu: "Омой меня от беззакония моего и очисти меня от грехов моих. Аминь.",
            textEn: "Wash me thoroughly from my iniquity, and cleanse me from my sins. Amen.",
            refHy: "Աղոթագիրք (Զղջման)",
            refRu: "Молитвослов (Покаянная)",
            refEn: "Prayer Book (Repentance)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Բժշկի՛ր ինձ, Տե՛ր, և ես կբժշկվեմ. փրկի՛ր ինձ, և ես կփրկվեմ, որովհետև Դու ես իմ փառքը։",
            textRu: "Исцели меня, Господи, и исцелен буду; спаси меня, и спасен буду; ибо Ты хвала моя.",
            textEn: "Heal me, O Lord, and I shall be healed; save me, and I shall be saved: for thou art my praise.",
            refHy: "Բժշկության Աղոթք",
            refRu: "Молитва об исцелении",
            refEn: "Prayer for Healing",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր առողջություն մարմնիս և խաղաղություն հոգուս։ Ամեն։",
            textRu: "Даруй здравие телу моему и мир душе моей. Аминь.",
            textEn: "Grant health to my body and peace to my soul. Amen.",
            refHy: "Բժշկության Աղոթք",
            refRu: "Молитва об исцелении",
            refEn: "Prayer for Healing",
            isPrayer: true
        )
    ]
}

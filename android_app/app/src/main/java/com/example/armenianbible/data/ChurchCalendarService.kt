package com.example.armenianbible.data

import android.content.Context
import android.content.Intent
import android.provider.CalendarContract
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

enum class FeastType(val id: String, val icon: String, val colorHex: String) {
    DAGHAVAR("daghavar", "👑", "#F59E0B"),
    DOMINICAL("dominical", "✨", "#0284C7"),
    FASTING("fasting", "🕯️", "#8B5CF6"),
    SAINTS("saints", "🕊️", "#10B981");

    fun localizedTitle(lang: AppLanguage): String = when (this) {
        DAGHAVAR -> when (lang) {
            AppLanguage.ARMENIAN -> "Տաղավար տոներ"
            AppLanguage.RUSSIAN -> "Великие праздники"
            AppLanguage.ENGLISH -> "Major Feasts"
        }
        DOMINICAL -> when (lang) {
            AppLanguage.ARMENIAN -> "Տերունական տոներ"
            AppLanguage.RUSSIAN -> "Господские праздники"
            AppLanguage.ENGLISH -> "Dominical Feasts"
        }
        FASTING -> when (lang) {
            AppLanguage.ARMENIAN -> "Պահք"
            AppLanguage.RUSSIAN -> "Посты"
            AppLanguage.ENGLISH -> "Fasting Days"
        }
        SAINTS -> when (lang) {
            AppLanguage.ARMENIAN -> "Սրբոց տոներ"
            AppLanguage.RUSSIAN -> "Дни святых"
            AppLanguage.ENGLISH -> "Saints' Days"
        }
    }
}

data class ArmenianChurchFeast(
    val id: String,
    val type: FeastType,
    val dateMillis: Long,
    val titleHy: String,
    val titleRu: String,
    val titleEn: String,
    val descriptionHy: String,
    val descriptionRu: String,
    val descriptionEn: String,
    val scriptureReading: String,
    val prayerHy: String,
    val prayerRu: String,
    val prayerEn: String,
    val isFasting: Boolean
) {
    fun title(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> titleHy
        AppLanguage.RUSSIAN -> titleRu
        AppLanguage.ENGLISH -> titleEn
    }

    fun description(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> descriptionHy
        AppLanguage.RUSSIAN -> descriptionRu
        AppLanguage.ENGLISH -> descriptionEn
    }

    fun prayer(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> prayerHy
        AppLanguage.RUSSIAN -> prayerRu
        AppLanguage.ENGLISH -> prayerEn
    }

    fun formattedDate(lang: AppLanguage): String {
        val locale = when (lang) {
            AppLanguage.ARMENIAN -> Locale("hy", "AM")
            AppLanguage.RUSSIAN -> Locale("ru", "RU")
            AppLanguage.ENGLISH -> Locale.ENGLISH
        }
        val sdf = SimpleDateFormat("d MMMM, EEEE", locale)
        return sdf.format(Date(dateMillis))
    }
}

object ChurchCalendarService {

    fun calculateEaster(year: Int): Long {
        val a = year % 19
        val b = year / 100
        val c = year % 100
        val d = b / 4
        val e = b % 4
        val f = (b + 8) / 25
        val g = (b - f + 1) / 3
        val h = (19 * a + b - d - g + 15) % 30
        val i = c / 4
        val k = c % 4
        val l = (32 + 2 * e + 2 * i - h - k) % 7
        val m = (a + 11 * h + 22 * l) / 451
        val month = (h + l - 7 * m + 114) / 31 // 3 = March, 4 = April
        val day = ((h + l - 7 * m + 114) % 31) + 1

        val cal = Calendar.getInstance()
        cal.set(year, month - 1, day, 12, 0, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun addDays(timeMillis: Long, days: Int): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = timeMillis
        cal.add(Calendar.DAY_OF_YEAR, days)
        return cal.timeInMillis
    }

    private fun createDate(year: Int, month: Int, day: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(year, month - 1, day, 12, 0, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun sundayNearest(year: Int, month: Int, day: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(year, month - 1, day, 12, 0, 0)
        val weekday = cal.get(Calendar.DAY_OF_WEEK) // 1 = Sunday
        val diff = 1 - weekday
        val adjustedDiff = if (diff > 3) diff - 7 else if (diff < -3) diff + 7 else diff
        cal.add(Calendar.DAY_OF_YEAR, adjustedDiff)
        return cal.timeInMillis
    }

    private fun secondSaturday(year: Int, month: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(year, month - 1, 1, 12, 0, 0)
        val weekday = cal.get(Calendar.DAY_OF_WEEK) // 7 = Saturday
        var daysToFirstSat = (7 - weekday) % 7
        if (daysToFirstSat < 0) daysToFirstSat += 7
        cal.add(Calendar.DAY_OF_YEAR, daysToFirstSat + 7)
        return cal.timeInMillis
    }

    fun feasts(year: Int): List<ArmenianChurchFeast> {
        val easter = calculateEaster(year)
        val list = mutableListOf<ArmenianChurchFeast>()

        // 1. Рождество и Богоявление (6 января) [Тагавар 1]
        list.add(
            ArmenianChurchFeast(
                id = "${year}_christmas",
                type = FeastType.DAGHAVAR,
                dateMillis = createDate(year, 1, 6),
                titleHy = "Սուրբ Ծնունդ և Աստվածահայտնություն",
                titleRu = "Рождество Христово и Богоявление",
                titleEn = "Holy Nativity and Theophany",
                descriptionHy = "Հայ Առաքելական Եկեղեցին Քրիստոսի Ծնունդը և Մկրտությունը նշում է միասին՝ հունվարի 6-ին: Ողջույնը՝ «Քրիստոս ծնաւ եւ յայտնեցաւ: Ձեզ եւ մեզ մեծ աւետիս»:",
                descriptionRu = "Армянская Апостольская Церковь празднует Рождество и Крещение Господне в один день — 6 января. Приветствие: «Христос родился и явился! Вам и нам благая весть!»",
                descriptionEn = "The Armenian Apostolic Church celebrates the Nativity and Theophany together on January 6. Greeting: 'Christ is born and revealed! Blessed is the revelation of Christ!'",
                scriptureReading = "Մատթեոս 1:18-25, Ղուկաս 2:1-20",
                prayerHy = "Փա՜ռք ի բարձունս Աստուծոյ, եւ յերկիր խաղաղութիւն, ի մարդիկ հաճութիւն:",
                prayerRu = "Слава в вышних Богу, и на земле мир, в человеках благоволение!",
                prayerEn = "Glory to God in the highest, and on earth peace, good will toward men!",
                isFasting = false
            )
        )

        // 2. Сретение Господне (14 февраля)
        list.add(
            ArmenianChurchFeast(
                id = "${year}_candlemas",
                type = FeastType.DOMINICAL,
                dateMillis = createDate(year, 2, 14),
                titleHy = "Տյառնընդառաջ (Տրնդեզ)",
                titleRu = "Сретение Господне (Трндез)",
                titleEn = "Presentation of the Lord (Trndez)",
                descriptionHy = "Քառասուն օրական Հիսուսի ընծայումը Տաճարին: Լույսի և նորապսակների օրհնության տոն:",
                descriptionRu = "Принесение 40-дневного Младенца Иисуса в Иерусалимский Храм. Праздник благословения молодоженов.",
                descriptionEn = "Presentation of the 40-day-old infant Jesus to the Temple in Jerusalem.",
                scriptureReading = "Ղուկաս 2:22-40",
                prayerHy = "Լոյս ի յայտնութիւն հեթանոսաց եւ փառք ժողովրդեան քում Իսրայէլի:",
                prayerRu = "Свет к просвещению язычников и славу народа Твоего Израиля!",
                prayerEn = "A light to lighten the Gentiles, and the glory of Thy people Israel!",
                isFasting = false
            )
        )

        // 3. Св. Саркис
        list.add(
            ArmenianChurchFeast(
                id = "${year}_st_sarkis",
                type = FeastType.SAINTS,
                dateMillis = addDays(easter, -63),
                titleHy = "Սուրբ Սարգիս զորավար",
                titleRu = "День святого полководца Саркиса",
                titleEn = "Feast of St. Sarkis the General",
                descriptionHy = "Երիտասարդների և սիրո բարեխոս Սուրբ Սարգիս զորավարի հիշատակության օր:",
                descriptionRu = "День памяти святого полководца Саркиса — покровителя молодежи и воинов.",
                descriptionEn = "Commemoration of St. Sarkis the General, patron saint of youth and love.",
                scriptureReading = "Եփեսացիս 6:10-18",
                prayerHy = "Սուրբդ Աստուծոյ Սարգիս զօրավար, բարեխօսեա՛ առ Քրիստոս Աստուած մեր:",
                prayerRu = "Святой Божий полководец Саркис, моли Христа Бога нашего о душах наших!",
                prayerEn = "Holy Saint Sarkis, intercede with Christ our God to save our souls!",
                isFasting = false
            )
        )

        // 4. Бун Барекендан
        list.add(
            ArmenianChurchFeast(
                id = "${year}_barekendan",
                type = FeastType.DOMINICAL,
                dateMillis = addDays(easter, -49),
                titleHy = "Բուն Բարեկենդան",
                titleRu = "Истинная Масленица (Бун Барекендан)",
                titleEn = "Great Barekendan",
                descriptionHy = "Մեծ Պահքին նախորդող ուրախության և բարի կենդանության տոն:",
                descriptionRu = "Канун Великого Поста, день духовной радости и примирения.",
                descriptionEn = "The eve of Great Lent, a joyful celebration representing Edenic joy.",
                scriptureReading = "Մատթեոս 6:1-21",
                prayerHy = "Տէր, տուր մեզ զղջում եւ արթնութիւն հոգւոյ:",
                prayerRu = "Господи, даруй нам покаяние и бодрость духа!",
                prayerEn = "Lord, grant us true repentance and vigilance of soul!",
                isFasting = false
            )
        )

        // 5. Начало Великого Поста
        list.add(
            ArmenianChurchFeast(
                id = "${year}_lent_start",
                type = FeastType.FASTING,
                dateMillis = addDays(easter, -48),
                titleHy = "Մեծ Պահքի սկիզբ",
                titleRu = "Начало Великого Поста",
                titleEn = "Beginning of Great Lent",
                descriptionHy = "Քառասնօրյա ապաշխարության և աղոթքի շրջան մինչև Սուրբ Զատիկ:",
                descriptionRu = "Начало 40-дневного периода покаяния, воздержания и молитвы.",
                descriptionEn = "Beginning of the 40-day fast of repentance leading to Holy Easter.",
                scriptureReading = "Եսայի 58:1-14",
                prayerHy = "Բա՛ց մեզ, Տէր, զդուռն ողորմութեան Քո:",
                prayerRu = "Отверзи нам, Господи, двери милосердия Твоего!",
                prayerEn = "Open to us, O Lord, the door of Thy mercy!",
                isFasting = true
            )
        )

        // 6. Благовещение (7 апреля)
        list.add(
            ArmenianChurchFeast(
                id = "${year}_annunciation",
                type = FeastType.DOMINICAL,
                dateMillis = createDate(year, 4, 7),
                titleHy = "Ավետումն Սուրբ Աստվածածնի",
                titleRu = "Благовещение Пресвятой Богородицы",
                titleEn = "Annunciation of the Holy Mother of God",
                descriptionHy = "Գաբրիել հրեշտակապետի ավետիսը Կույս Մարիամին: Մայրության և գեղեցկության տոն:",
                descriptionRu = "Благая весть архангела Гавриила Деве Марии о рождении Спасителя.",
                descriptionEn = "Archangel Gabriel's announcement to the Virgin Mary of the birth of Christ.",
                scriptureReading = "Ղուկաս 1:26-38",
                prayerHy = "Ուրախացի՛ր, բերկրեալդ, Տէրն ընդ քեզ. օրհնեալ ես դու ի կանայս:",
                prayerRu = "Радуйся, Благодатная! Господь с Тобою; благословенна Ты между женами!",
                prayerEn = "Hail, Mary, full of grace, the Lord is with thee; blessed art thou among women!",
                isFasting = false
            )
        )

        // 7. Цахказард (Вербное воскресенье)
        list.add(
            ArmenianChurchFeast(
                id = "${year}_palm_sunday",
                type = FeastType.DOMINICAL,
                dateMillis = addDays(easter, -7),
                titleHy = "Ծաղկազարդ (Ծառզարդար)",
                titleRu = "Вербное Воскресенье (Цахказард)",
                titleEn = "Palm Sunday",
                descriptionHy = "Հիսուս Քրիստոսի հաղթական մուտքը Երուսաղեմ: Մանուկների օրհնության օր:",
                descriptionRu = "Торжественный вход Господень в Иерусалим. Благословение детей.",
                descriptionEn = "Triumphal Entry of Jesus Christ into Jerusalem.",
                scriptureReading = "Մատթեոս 21:1-11",
                prayerHy = "Օվսաննա՜ ի բարձունս, օրհնեալ որ գաս յանուն Տեառն:",
                prayerRu = "Осанна в вышних! Благословен Грядущий во имя Господне!",
                prayerEn = "Hosanna in the highest! Blessed is He who comes in the name of the Lord!",
                isFasting = false
            )
        )

        // 8. Великая Пятница
        list.add(
            ArmenianChurchFeast(
                id = "${year}_good_friday",
                type = FeastType.FASTING,
                dateMillis = addDays(easter, -2),
                titleHy = "Ավագ Ուրբաթ (Խաչելություն)",
                titleRu = "Великая Пятница (Страсти Господни)",
                titleEn = "Great and Holy Friday",
                descriptionHy = "Հիսուս Քրիստոսի չարչարանքների, խաչելության և թաղման հիշատակը:",
                descriptionRu = "Воспоминание святых Страстей, распятия и погребения Господа Иисуса Христа.",
                descriptionEn = "Commemoration of the Crucifixion, Death, and Burial of Jesus Christ.",
                scriptureReading = "Հովհաննես 19:1-37",
                prayerHy = "Խաչի Քո, Քրիստոս, երկիրպագանեմք, եւ զսուրբ զՅարութիւն Քո փառաւորեմք:",
                prayerRu = "Кресту Твоему поклоняемся, Владыко, и святое Воскресение Твое славим!",
                prayerEn = "We bow before Thy Cross, O Christ, and we glorify Thy Holy Resurrection!",
                isFasting = true
            )
        )

        // 9. СВЯТАЯ ПАСХА [Тагавар 2]
        list.add(
            ArmenianChurchFeast(
                id = "${year}_easter",
                type = FeastType.DAGHAVAR,
                dateMillis = easter,
                titleHy = "Սուրբ Հարություն (Սուրբ Զատիկ)",
                titleRu = "Светлое Христово Воскресение (Пасха)",
                titleEn = "Feast of the Glorious Resurrection (Easter)",
                descriptionHy = "Քրիստոնեական մեծագույն տոնը՝ Քրիստոս յարեաւ ի մեռելոց: Օրհնեալ է յարութիւնն Քրիստոսի:",
                descriptionRu = "Величайший христианский праздник победы над смертью: Христос воскрес из мертвых!",
                descriptionEn = "The greatest Christian feast of the Resurrection of Jesus Christ.",
                scriptureReading = "Մատթեոս 28:1-20, Հովհաննես 20:1-18",
                prayerHy = "Քրիստոս յարեաւ ի մեռելոց, մահուամբ զմահ կոխեաց, եւ որոց ի գերեզմանս էին՝ կեանս պարգեւեաց:",
                prayerRu = "Христос воскрес из мертвых, смертию смерть поправ, и сущим во гробех жизнь даровав!",
                prayerEn = "Christ is risen from the dead, trampling down death by death, and giving life to those in the tombs!",
                isFasting = false
            )
        )

        // 10. Вознесение Господне
        list.add(
            ArmenianChurchFeast(
                id = "${year}_ascension",
                type = FeastType.DOMINICAL,
                dateMillis = addDays(easter, 39),
                titleHy = "Համբարձում Տեառն",
                titleRu = "Вознесение Господне",
                titleEn = "Ascension of the Lord",
                descriptionHy = "Հիսուս Քրիստոսի երկինք համբարձվելու և Հոր աջ կողմը նստելու տոնը:",
                descriptionRu = "Праздник восшествия Господа во плоти на Небеса к Богу Отцу.",
                descriptionEn = "Commemoration of the Ascension of Jesus Christ into Heaven.",
                scriptureReading = "Գործք Առաքելոց 1:1-11",
                prayerHy = "Համբարձաւ Աստուած օրհնութեամբ, եւ Տէր մեր ձայնիւ փողոյ: Փա՜ռք Քեզ, Տէր:",
                prayerRu = "Восшел Бог при восклицаниях, Господь при звуке трубном. Слава Тебе, Господи!",
                prayerEn = "God is gone up with a shout, the Lord with the sound of a trumpet!",
                isFasting = false
            )
        )

        // 11. Пятидесятница
        list.add(
            ArmenianChurchFeast(
                id = "${year}_pentecost",
                type = FeastType.DOMINICAL,
                dateMillis = addDays(easter, 49),
                titleHy = "Հոգեգալուստ (Պենտեկոստե)",
                titleRu = "Пятидесятница (Сошествие Святого Духа)",
                titleEn = "Pentecost",
                descriptionHy = "Սուրբ Հոգու էջքը առաքյալների վրա և Քրիստոսի Եկեղեցու հիմնադրումը:",
                descriptionRu = "Сошествие Святого Духа на апостолов. День рождения Церкви Христовой.",
                descriptionEn = "Descent of the Holy Spirit upon the Apostles. Birthday of the Church.",
                scriptureReading = "Գործք Առաքելոց 2:1-21",
                prayerHy = "Ե՛կ, Հոգի՛ Սուրբ, եւ լի՛ց զսիրտս հաւատացելոց Քոց:",
                prayerRu = "Царю Небесный, Утешителю, Душе истины, прииди и вселися в ны!",
                prayerEn = "O Heavenly King, the Comforter, the Spirit of Truth, come and abide in us!",
                isFasting = false
            )
        )

        // 12. ВАРДАВАР [Тагавар 3]
        list.add(
            ArmenianChurchFeast(
                id = "${year}_vardavar",
                type = FeastType.DAGHAVAR,
                dateMillis = addDays(easter, 98),
                titleHy = "Պայծառակերպություն (Վարդավառ)",
                titleRu = "Преображение Господне (Вардавар)",
                titleEn = "Transfiguration (Vardavar)",
                descriptionHy = "Քրիստոսի աստվածային փառքի պայծառացումը Թաբոր լեռան վրա:",
                descriptionRu = "Явление Божественной славы Спасителя на горе Фавор. Праздник благословения водой.",
                descriptionEn = "The Transfiguration of Jesus Christ on Mount Tabor.",
                scriptureReading = "Մատթեոս 17:1-9",
                prayerHy = "Պայծառացո՛, Տէր, զխաւարեալ հոգիս մեր Թաբորական լուսով Քո:",
                prayerRu = "Преобразился еси на горе, Христе Боже, показавый учеником Твоим славу Твою!",
                prayerEn = "Thou wast transfigured on the mountain, O Christ God, revealing Thy glory!",
                isFasting = false
            )
        )

        // 13. УСПЕНИЕ БОГОРОДИЦЫ [Тагавар 4]
        list.add(
            ArmenianChurchFeast(
                id = "${year}_assumption",
                type = FeastType.DAGHAVAR,
                dateMillis = sundayNearest(year, 8, 15),
                titleHy = "Վերափոխումն Սուրբ Աստվածածնի",
                titleRu = "Успение Пресвятой Богородицы",
                titleEn = "Assumption of the Holy Mother of God",
                descriptionHy = "Աստվածամոր երկինք վերափոխման տոնը: Ավանդական խաղողօրհնեքի հանդիսություն:",
                descriptionRu = "Успение и взятие Божией Матери на Небо. Чин освящения винограда.",
                descriptionEn = "Assumption of the Holy Virgin Mary and Blessing of the Grapes.",
                scriptureReading = "Ղուկաս 1:39-56",
                prayerHy = "Անկանիմք առաջի քո, Սուրբ Աստուածածին. բարեխօսեա՛ վասն անձանց մերոց:",
                prayerRu = "Под твою милость прибегаем, Богородице Дево, избави нас от бед!",
                prayerEn = "We fly to thy patronage, O holy Mother of God; deliver us from all dangers!",
                isFasting = false
            )
        )

        // 14. ВОЗДВИЖЕНИЕ КРЕСТА [Тагавар 5]
        list.add(
            ArmenianChurchFeast(
                id = "${year}_exaltation_cross",
                type = FeastType.DAGHAVAR,
                dateMillis = sundayNearest(year, 9, 14),
                titleHy = "Խաչվերաց",
                titleRu = "Воздвижение Честного Креста (Хачверац)",
                titleEn = "Exaltation of the Holy Cross (Khachverats)",
                descriptionHy = "Քրիստոսի Սուրբ Խաչափայտի գերությունից ազատագրման և բարձրացման տոնը:",
                descriptionRu = "Возвращение Животворящего Креста Господня из плена и его торжественное воздвижение.",
                descriptionEn = "Elevation and veneration of the Holy Cross of Christ.",
                scriptureReading = "Հովհաննես 19:16-37",
                prayerHy = "Խաչ քո եղիցի մեզ ապաւէն, Տէր Յիսուս, յորժամ գաս փառօք:",
                prayerRu = "Крест Твой да будет нам прибежищем, Господи Иисусе!",
                prayerEn = "May Thy Holy Cross be our refuge, Lord Jesus!",
                isFasting = false
            )
        )

        // 15. День переводчиков
        list.add(
            ArmenianChurchFeast(
                id = "${year}_targmanchats",
                type = FeastType.SAINTS,
                dateMillis = secondSaturday(year, 10),
                titleHy = "Սուրբ Թարգմանչաց տոն",
                titleRu = "День святых Переводчиков (Таргманчац)",
                titleEn = "Feast of the Holy Translators",
                descriptionHy = "Սուրբ Մեսրոպ Մաշտոցի և Սահակ Պարթևի հիշատակը: Աստվածաշնչի հայերեն թարգմանությունը:",
                descriptionRu = "Память создателей армянской письменности и переводчиков Библии.",
                descriptionEn = "Commemoration of Holy Translators Sts. Mesrop Mashtots and Sahak Partev.",
                scriptureReading = "Առակաց 1:1-7",
                prayerHy = "Որք զարդարեցին զիմաստս Անեղին, բարեխօսեցէ՛ք առ Տէր վասն մեր:",
                prayerRu = "Святые переводчики, молите Бога о нашем просвещении!",
                prayerEn = "Holy Translators, pray to the Lord for our enlightenment!",
                isFasting = false
            )
        )

        return list.sortedBy { it.dateMillis }
    }

    fun todayFeast(): ArmenianChurchFeast? {
        val today = Calendar.getInstance()
        val year = today.get(Calendar.YEAR)
        val all = feasts(year)

        return all.find { f ->
            val cal = Calendar.getInstance()
            cal.timeInMillis = f.dateMillis
            cal.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                    cal.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR)
        }
    }

    fun nextDaghavarFeast(): Pair<ArmenianChurchFeast, Int>? {
        val today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)

        val year = today.get(Calendar.YEAR)
        var candidates = feasts(year).filter { it.type == FeastType.DAGHAVAR && it.dateMillis >= today.timeInMillis }
        if (candidates.isEmpty()) {
            candidates = feasts(year + 1).filter { it.type == FeastType.DAGHAVAR }
        }

        val next = candidates.firstOrNull() ?: return null
        val diffDays = ((next.dateMillis - today.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
        return Pair(next, maxOf(0, diffDays))
    }

    fun generateICSFile(context: Context, year: Int, language: AppLanguage): File? {
        val allFeasts = feasts(year)
        val sdfDate = SimpleDateFormat("yyyyMMdd", Locale.US)
        val sdfNow = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US)
        sdfNow.timeZone = TimeZone.getTimeZone("UTC")
        val nowStr = sdfNow.format(Date())

        val calName = when (language) {
            AppLanguage.ARMENIAN -> "Եկեղեցական Տոնացույց $year"
            AppLanguage.RUSSIAN -> "Церковный Календарь $year"
            AppLanguage.ENGLISH -> "Armenian Church Calendar $year"
        }

        val sb = StringBuilder()
        sb.append("BEGIN:VCALENDAR\n")
        sb.append("VERSION:2.0\n")
        sb.append("PRODID:-//Samvel//Armenian Bible Android//HY\n")
        sb.append("CALSCALE:GREGORIAN\n")
        sb.append("METHOD:PUBLISH\n")
        sb.append("X-WR-CALNAME:$calName\n")
        sb.append("X-WR-TIMEZONE:Asia/Yerevan\n")

        for (f in allFeasts) {
            val dtStart = sdfDate.format(Date(f.dateMillis))
            val dtEnd = sdfDate.format(Date(f.dateMillis + 24 * 60 * 60 * 1000L))
            val summary = "${f.type.icon} ${f.title(language)}"
            var desc = f.description(language)
            if (f.scriptureReading.isNotEmpty()) {
                val readTitle = when (language) {
                    AppLanguage.ARMENIAN -> "Ընթերցվածք"
                    AppLanguage.RUSSIAN -> "Чтения дня"
                    AppLanguage.ENGLISH -> "Readings"
                }
                desc += "\\n\\n📖 $readTitle: ${f.scriptureReading}"
            }
            if (f.prayer(language).isNotEmpty()) {
                val prayTitle = when (language) {
                    AppLanguage.ARMENIAN -> "Աղոթք"
                    AppLanguage.RUSSIAN -> "Молитва"
                    AppLanguage.ENGLISH -> "Prayer"
                }
                desc += "\\n\\n🙏 $prayTitle: ${f.prayer(language)}"
            }

            sb.append("BEGIN:VEVENT\n")
            sb.append("UID:${f.id}_$year@armenianbible.android\n")
            sb.append("DTSTAMP:$nowStr\n")
            sb.append("DTSTART;VALUE=DATE:$dtStart\n")
            sb.append("DTEND;VALUE=DATE:$dtEnd\n")
            sb.append("SUMMARY:$summary\n")
            sb.append("DESCRIPTION:$desc\n")
            sb.append("STATUS:CONFIRMED\n")
            sb.append("TRANSP:TRANSPARENT\n")
            sb.append("BEGIN:VALARM\n")
            sb.append("ACTION:DISPLAY\n")
            sb.append("DESCRIPTION:$summary\n")
            sb.append("TRIGGER:-P1D\n")
            sb.append("END:VALARM\n")
            sb.append("END:VEVENT\n")
        }

        sb.append("END:VCALENDAR")

        return try {
            val file = File(context.cacheDir, "ArmenianChurchCalendar_$year.ics")
            val writer = FileWriter(file)
            writer.write(sb.toString())
            writer.flush()
            writer.close()
            file
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun insertFeastToSystemCalendar(context: Context, feast: ArmenianChurchFeast, language: AppLanguage) {
        val intent = Intent(Intent.ACTION_INSERT).apply {
            data = CalendarContract.Events.CONTENT_URI
            putExtra(CalendarContract.Events.TITLE, "${feast.type.icon} ${feast.title(language)}")
            putExtra(CalendarContract.Events.DESCRIPTION, "${feast.description(language)}\n\n${feast.prayer(language)}")
            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, feast.dateMillis)
            putExtra(CalendarContract.EXTRA_EVENT_END_TIME, feast.dateMillis + 24 * 60 * 60 * 1000L)
            putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, true)
        }
        context.startActivity(intent)
    }
}

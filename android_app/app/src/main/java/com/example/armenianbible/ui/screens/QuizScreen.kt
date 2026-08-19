package com.example.armenianbible.ui.screens

import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MilitaryTech
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.AppLanguage
import com.example.armenianbible.data.PreferencesManager

data class QuizBadge(
    val id: String,
    val titleHy: String,
    val titleRu: String,
    val titleEn: String,
    val descHy: String,
    val descRu: String,
    val descEn: String,
    val iconEmoji: String,
    val requiredScore: Int = 0
) {
    fun title(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> titleHy
        AppLanguage.RUSSIAN -> titleRu
        AppLanguage.ENGLISH -> titleEn
    }

    fun desc(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> descHy
        AppLanguage.RUSSIAN -> descRu
        AppLanguage.ENGLISH -> descEn
    }
}

val allBadges = listOf(
    QuizBadge("first", "Առաջին Քայլ", "Первый Шаг", "First Step", "Ավարտեք 1-ին հարցը", "Ответьте на 1-й вопрос", "Complete 1st question", "🌱", 100),
    QuizBadge("novice", "Աստվածաշնչի Ուսանող", "Новичк-Знаток", "Novice Scholar", "Վաստակեք 300 միավոր", "Наберите 300 очков", "Earn 300 points", "📜", 300),
    QuizBadge("master", "Աստվածաբան", "Мастер Библии", "Bible Master", "Վաստակեք 700 միավոր", "Наберите 700 очков", "Earn 700 points", "👑", 700),
    QuizBadge("legend", "Աստվածաշնչյան Լեգենդ", "Легенда Истины", "Legend of Faith", "Վաստակեք 1200+ միավոր", "Наберите 1200+ очков", "Earn 1200+ points", "🔥", 1200)
)

data class FullQuizQuestion(
    val id: Int,
    val category: String,
    val questionHy: String,
    val questionRu: String,
    val questionEn: String,
    val optionsHy: List<String>,
    val optionsRu: List<String>,
    val optionsEn: List<String>,
    val correctIndex: Int,
    val explanationHy: String,
    val explanationRu: String,
    val explanationEn: String,
    val ref: String
) {
    fun question(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> questionHy
        AppLanguage.RUSSIAN -> questionRu
        AppLanguage.ENGLISH -> questionEn
    }

    fun options(lang: AppLanguage): List<String> = when (lang) {
        AppLanguage.ARMENIAN -> optionsHy
        AppLanguage.RUSSIAN -> optionsRu
        AppLanguage.ENGLISH -> optionsEn
    }

    fun explanation(lang: AppLanguage): String = when (lang) {
        AppLanguage.ARMENIAN -> explanationHy
        AppLanguage.RUSSIAN -> explanationRu
        AppLanguage.ENGLISH -> explanationEn
    }
}

val extendedQuizQuestions = listOf(
    FullQuizQuestion(
        1, "old",
        "Քանի՞ օրում Աստված արարեց աշխարհը և հանգստացավ յոթերորդ օրը։",
        "За сколько дней Бог сотворил мир, после чего почил в день седьмой?",
        "In how many days did God create the world before resting on the seventh day?",
        listOf("5 օրում", "6 օրում", "7 օրում", "40 օրում"),
        listOf("За 5 дней", "За 6 дней", "За 7 дней", "За 40 дней"),
        listOf("In 5 days", "In 6 days", "In 7 days", "In 40 days"),
        1, "Աստված արարեց երկինքն ու երկիրը 6 օրում:", "Бог сотворил небо и землю за 6 дней.", "God created heaven and earth in 6 days.", "Ծննդոց 2:2"
    ),
    FullQuizQuestion(
        2, "old",
        "Ո՞վ տապան կառուցեց ջրհեղեղից փրկվելու համար։",
        "Кто построил ковчег для спасения от Великого потопа?",
        "Who built the ark to survive the Great Flood?",
        listOf("Աբրահամը", "Մովսեսը", "Նոյը", "Դավիթը"),
        listOf("Авраам", "Моисей", "Ной", "Давид"),
        listOf("Abraham", "Moses", "Noah", "David"),
        2, "Աստված պատվիրեց Նոյին տապան շինել:", "Бог повелел Ною построить ковчег.", "God commanded Noah to build an ark.", "Ծննդոց 6:14"
    ),
    FullQuizQuestion(
        3, "old",
        "Ո՞վ սպանեց Գողիաթին պարսատիկով և քարով։",
        "Кто победил великана Голиафа с помощью пращи и камня?",
        "Who defeated the giant Goliath using a sling and a stone?",
        listOf("Սավուղը", "Սողոմոնը", "Դավիթը", "Սամսոնը"),
        listOf("Саул", "Соломон", "Давид", "Самсон"),
        listOf("Saul", "Solomon", "David", "Samson"),
        2, "Երիտասարդ Դավիթը հավատով հաղթեց Գողիաթին:", "Давид победил Голиафа во имя Господа.", "David defeated Goliath in God's name.", "Ա Թագավորաց 17:50"
    ),
    FullQuizQuestion(
        4, "gospel",
        "Ո՞ր քաղաքում ծնվեց Հիսուս Քրիստոս։",
        "В каком городе родился Иисус Христос?",
        "In which city was Jesus Christ born?",
        listOf("Նազարեթ", "Երուսաղեմ", "Բեթղեհեմ", "Կափառնաում"),
        listOf("Назарет", "Иерусалим", "Вифлеем", "Капернаум"),
        listOf("Nazareth", "Jerusalem", "Bethlehem", "Capernaum"),
        2, "Հիսուս ծնվեց Բեթղեհեմ քաղաքում:", "Иисус родился в Вифлееме Иудейском.", "Jesus was born in Bethlehem.", "Մատթեոս 2:1"
    ),
    FullQuizQuestion(
        5, "gospel",
        "Քանի՞ առաքյալ ընտրեց Հիսուսը։",
        "Сколько апостолов избрал Иիсус?",
        "How many apostles did Jesus choose?",
        listOf("7", "10", "12", "70"),
        listOf("7", "10", "12", "70"),
        listOf("7", "10", "12", "70"),
        2, "Հիսուս ընտրեց 12 աշակերտների:", "Иисус призвал 12 учеников.", "Jesus chose 12 apostles.", "Մատթեոս 10:1"
    ),
    FullQuizQuestion(
        6, "new",
        "Ո՞վ էր Պողոս առաքյալը նախքան Քրիստոնեություն ընդունելը։",
        "Кем был апостол Павел до своего обращения в христианство?",
        "Who was the Apostle Paul before converting?",
        listOf("Ձկնորս", "Սավուղ (հալածող)", "Մաքսավոր", "Քահանայապետ"),
        listOf("Рыбак", "Савл (гонитель)", "Мытарь", "Первосвященник"),
        listOf("Fisherman", "Saul (persecutor)", "Tax collector", "High Priest"),
        1, "Սավուղը հալածում էր եկեղեցին մինչ Դամասկոսի ճանապարհին հանդիպեց Տիրոջը:", "Савл гнал христиан до встречи на пути в Дамаск.", "Saul persecuted Christians until meeting Jesus.", "Գործք 9:3-5"
    ),
    FullQuizQuestion(
        7, "old",
        "Ո՞վ ստացավ 10 Պատվիրանները Սինա լեռան վրա։",
        "Кто получил 10 Заповедей на горе Синай?",
        "Who received the 10 Commandments on Mount Sinai?",
        listOf("Աբրահամը", "Մովսեսը", "Հեսուն", "Ահարոնը"),
        listOf("Авраам", "Моисей", "Иисус Навин", "Аарон"),
        listOf("Abraham", "Moses", "Joshua", "Aaron"),
        1, "Մովսեսը բարձրացավ Սինա լեռը և ստացավ պատվիրանները:", "Моисей взошел на Синай и получил заповеди.", "Moses ascended Sinai and received the commandments.", "Ելք 20:1"
    ),
    FullQuizQuestion(
        8, "gospel",
        "Ո՞ր գետում մկրտվեց Հիսուս Քրիստոս Հովհաննես Մկրտչի կողմից։",
        "В какой реке крестился Иисус Христос от Иоанна Крестителя?",
        "In which river was Jesus baptized by John the Baptist?",
        listOf("Եփրատ", "Տիգրիս", "Հորդանան", "Նեղոս"),
        listOf("Евфрат", "Тигр", "Иордан", "Нил"),
        listOf("Euphrates", "Tigris", "Jordan", "Nile"),
        2, "Հիսուս մկրտվեց Հորդանան գետում:", "Иисус крестился в реке Иордан.", "Jesus was baptized in the Jordan River.", "Մատթեոս 3:13"
    ),
    FullQuizQuestion(
        9, "old",
        "Ո՞վ էր Աստվածաշնչում ամենաիմաստուն թագավորը։",
        "Кто был самым мудрым царем в Библии?",
        "Who was the wisest king in the Bible?",
        listOf("Սավուղը", "Դավիթը", "Սողոմոնը", "Եզեկիան"),
        listOf("Саул", "Давид", "Соломон", "Езекия"),
        listOf("Saul", "David", "Solomon", "Hezekiah"),
        2, "Աստված տվեց Սողոմոնին անկրկնելի իմաստություն:", "Бог даровал Соломону великую мудрость.", "God gave Solomon great wisdom.", "Գ Թագավորաց 3:12"
    ),
    FullQuizQuestion(
        10, "gospel",
        "Ո՞րն է Աստվածաշնչի ամենակարճ համարը։",
        "Какой самый короткий стих в Библии?",
        "What is the shortest verse in the Bible?",
        listOf("«Հիսուս լաց եղավ»", "«Աղոթեցեք»", "«Փառք Աստծո»", "«Սիրեցեք միմյանց»"),
        listOf("«Иисус прослезился»", "«Молитесь»", "«Слава Богу»", "«Любите друг друга»"),
        listOf("«Jesus wept»", "«Pray always»", "«Glory to God»", "«Love one another»"),
        0, "«Հիսուս լաց եղավ» (Յովհաննէս 11:35):", "«Иисус прослезился» (Иоанна 11:35).", "«Jesus wept» (John 11:35).", "Յովհաննէս 11:35"
    ),
    FullQuizQuestion(
        11, "new",
        "Ո՞ր քաղաքում էին Քրիստոսի հետևորդները առաջին անգամ կոչվեցին «Քրիստոնյաներ»։",
        "В каком городе последователи Христа впервые стали называться Христианами?",
        "In which city were disciples first called Christians?",
        listOf("Երուսաղեմ", "Անտիոք", "Հռոմ", "Կորնթոս"),
        listOf("Иерусалим", "Антиохия", "Рим", "Коринф"),
        listOf("Jerusalem", "Antioch", "Rome", "Corinth"),
        1, "Անտիոքում աշակերտները առաջին անգամ կոչվեցին Քրիստոնյաներ:", "В Антиохии ученики впервые стали называться Христианами.", "Disciples were first called Christians in Antioch.", "Գործք 11:26"
    ),
    FullQuizQuestion(
        12, "gospel",
        "Քանի՞ հացով և ձկով Հիսուսը կերակրեց 5000 մարդկանց։",
        "Сколькими хлебами и рыбами Иисус накормил 5000 человек?",
        "How many loaves and fish did Jesus use to feed the 5,000?",
        listOf("5 հաց և 2 ձուկ", "7 հաց և 3 ձուկ", "3 հաց և 5 ձուկ", "12 հաց և 2 ձուկ"),
        listOf("5 хлебов и 2 рыбы", "7 хлебов и 3 рыбы", "3 хлеба и 5 рыб", "12 хлебов и 2 рыбы"),
        listOf("5 loaves and 2 fish", "7 loaves and 3 fish", "3 loaves and 5 fish", "12 loaves and 2 fish"),
        0, "Հիսուս օրհնեց 5 նկանակն ու 2 ձուկը:", "Иисус благословил 5 хлебов и 2 рыбы.", "Jesus blessed 5 loaves and 2 fish.", "Մատթեոս 14:19"
    ),
    FullQuizQuestion(
        13, "old",
        "Ո՞ր լեռան վրա կանգ առավ Նոյան Տապանը ջրհեղեղից հետո։",
        "На какой горе остановился Ноев Ковчег после потопа?",
        "Upon which mountain did Noah's Ark come to rest after the flood?",
        listOf("Սինա", "Արարատ", "Ձիթենյաց", "Թաբոր"),
        listOf("Синай", "Арарат", "Елеонская", "Фавор"),
        listOf("Sinai", "Ararat", "Mount Olivet", "Tabor"),
        1, "Տապանը կանգ առավ Արարատ լեռան վրա:", "Ковчег остановился на горах Араратских.", "The ark rested upon the mountains of Ararat.", "Ծննդոց 8:4"
    ),
    FullQuizQuestion(
        14, "new",
        "Ո՞վ էր Առաջին Քրիստոնյա Նահատակը (Նախասարկավագը)։",
        "Кто был первым христианским мучеником (перводиаконом)?",
        "Who was the first Christian martyr (first deacon)?",
        listOf("Սուրբ Ստեփանոսը", "Սուրբ Պետրոսը", "Սուրբ Հակոբոսը", "Սուրբ Պողոսը"),
        listOf("Святой Стефан", "Святой Пётр", "Святой Иаков", "Святой Павел"),
        listOf("Saint Stephen", "Saint Peter", "Saint James", "Saint Paul"),
        0, "Սուրբ Ստեփանոս Նախավկան քարկոծվեց Քրիստոսի վկայության համար:", "Святой Стефан был побит камнями за вероисповедание Христа.", "Saint Stephen was stoned for witnessing to Christ.", "Գործք 7:59"
    ),
    FullQuizQuestion(
        15, "new",
        "Ո՞վ էր Հայաստանում Քրիստոնեության առաջին Լուսավորիչն ու Հայրապետը։",
        "Кто был первым Просветителем и Крестителем Армении?",
        "Who was the Illuminator and Baptizer of Armenia?",
        listOf("Սուրբ Գրիգոր Լուսավորիչը", "Սուրբ Սահակ Պարթևը", "Սուրբ Մեսրոպ Մաշտոցը", "Սուրբ Ներսեսը"),
        listOf("Святой Григорий Просветитель", "Святой Саак Партев", "Святой Месроп Маштоц", "Святой Нерсес"),
        listOf("Saint Gregory the Illuminator", "Saint Sahak Partev", "Saint Mesrop Mashtots", "Saint Nerses"),
        0, "Սուրբ Գրիգոր Լուսավորիչը դարձրեց Հայաստանը աշխարհում առաջին քրիստոնյա պետությունը 301թ․:", "Святой Григорий Просветитель крестил Армению в 301 году как первую христианскую страну в мире.", "Saint Gregory the Illuminator guided Armenia to accept Christianity in 301 AD.", "Պատմություն Հայոց 301թ."
    )
)

@Composable
fun QuizScreen(
    prefs: PreferencesManager,
    appLanguage: AppLanguage,
    onDismiss: () -> Unit = {}
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    var questionIndex by remember { mutableIntStateOf(0) }
    var score by remember { mutableIntStateOf(0) }
    var selectedOption by remember { mutableStateOf<Int?>(null) }
    var bestScore by remember { mutableIntStateOf(prefs.quizBestScore) }
    var quizCompleted by remember { mutableStateOf(false) }

    val currentQ = extendedQuizQuestions[questionIndex % extendedQuizQuestions.size]

    val unlockedBadges = remember(bestScore) {
        allBadges.filter { bestScore >= it.requiredScore }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC))
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top Gamification Score Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Աստվածաշնչյան Վիկտորինա 🏆",
                    style = MaterialTheme.typography.titleLarge.copy(color = Color(0xFF0F172A), fontWeight = FontWeight.Bold, fontSize = 19.sp)
                )
                Text(
                    text = "Միավորներ: $score | Ռեկորդ: $bestScore",
                    color = Color(0xFF059669),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFF1F5F9))
            ) {
                Icon(Icons.Default.Refresh, contentDescription = "Close", tint = Color(0xFF475569), modifier = Modifier.size(18.dp))
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // BADGES HORIZONTAL SCROLL BAR
        Text("Նվաճումներ և Կրծքանշաններ (Значки & Награды):", color = Color(0xFF64748B), fontSize = 11.sp, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(6.dp))

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            items(allBadges) { badge ->
                val isUnlocked = bestScore >= badge.requiredScore
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = if (isUnlocked) Color.White else Color(0xFFF1F5F9),
                    border = CardDefaults.outlinedCardBorder().copy(
                        brush = if (isUnlocked) Brush.linearGradient(listOf(Color(0xFFF59E0B), Color(0xFF10B981))) else Brush.linearGradient(listOf(Color(0xFFE2E8F0), Color(0xFFE2E8F0)))
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(badge.iconEmoji, fontSize = 16.sp)
                        Spacer(modifier = Modifier.width(6.dp))
                        Column {
                            Text(
                                text = badge.title(appLanguage),
                                color = if (isUnlocked) Color(0xFF0F172A) else Color(0xFF94A3B8),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = if (isUnlocked) "✓ Открыто" else "${badge.requiredScore} очков",
                                color = if (isUnlocked) Color(0xFF059669) else Color(0xFF94A3B8),
                                fontSize = 9.sp
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (quizCompleted) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .shadow(2.dp, RoundedCornerShape(24.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(
                    modifier = Modifier.padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF059669), modifier = Modifier.size(60.dp))
                    Spacer(modifier = Modifier.height(12.dp))
                    Text("Շնորհավորում ենք! 🎉", color = Color(0xFF0F172A), fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(6.dp))
                    Text("Վաստակած միավորները: $score", color = Color(0xFF0EA5E9), fontSize = 18.sp, fontWeight = FontWeight.SemiBold)

                    Spacer(modifier = Modifier.height(20.dp))

                    Button(
                        onClick = {
                            questionIndex = 0
                            score = 0
                            selectedOption = null
                            quizCompleted = false
                        },
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9))
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = null, tint = Color.White)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Խաղալ Կրկին 🎲", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }
        } else {
            // Progress Bar
            LinearProgressIndicator(
                progress = { (questionIndex + 1) / extendedQuizQuestions.size.toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(CircleShape),
                color = Color(0xFF0EA5E9),
                trackColor = Color(0xFFE2E8F0)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Question Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(20.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                shape = RoundedCornerShape(20.dp)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Հարց ${questionIndex + 1}/${extendedQuizQuestions.size}",
                            color = Color(0xFF0EA5E9),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "+100 очков",
                            color = Color(0xFFD97706),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = currentQ.question(appLanguage),
                        color = Color(0xFF0F172A),
                        fontSize = 17.sp,
                        fontWeight = FontWeight.SemiBold,
                        lineHeight = 24.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Options list
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                currentQ.options(appLanguage).forEachIndexed { idx, opt ->
                    val isSelected = selectedOption == idx
                    val isCorrect = idx == currentQ.correctIndex

                    val bgColor = when {
                        selectedOption == null -> Color.White
                        isSelected && isCorrect -> Color(0xFF059669)
                        isSelected && !isCorrect -> Color(0xFFDC2626)
                        isCorrect -> Color(0xFF059669).copy(alpha = 0.8f)
                        else -> Color.White
                    }

                    val textColor = when {
                        selectedOption == null -> Color(0xFF0F172A)
                        isSelected || isCorrect -> Color.White
                        else -> Color(0xFF64748B)
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(if (selectedOption == null) 1.dp else 0.dp, RoundedCornerShape(16.dp))
                            .clip(RoundedCornerShape(16.dp))
                            .background(bgColor)
                            .border(
                                width = 1.dp,
                                color = if (isSelected) Color.Transparent else Color(0xFFE2E8F0),
                                shape = RoundedCornerShape(16.dp)
                            )
                            .clickable(enabled = selectedOption == null) {
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                selectedOption = idx
                                if (idx == currentQ.correctIndex) {
                                    score += 100
                                    if (score > bestScore) {
                                        bestScore = score
                                        prefs.quizBestScore = score
                                    }
                                }
                            }
                            .padding(horizontal = 18.dp, vertical = 14.dp)
                    ) {
                        Text(
                            text = opt,
                            color = textColor,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Explanation box when answered
            if (selectedOption != null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(1.dp, RoundedCornerShape(16.dp))
                        .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(16.dp)),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF3C7).copy(alpha = 0.5f)),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text("💡 Պարզաբանում (${currentQ.ref}):", color = Color(0xFFD97706), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(currentQ.explanation(appLanguage), color = Color(0xFF1E293B), fontSize = 13.sp)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Button(
                    onClick = {
                        if (questionIndex + 1 < extendedQuizQuestions.size) {
                            questionIndex++
                            selectedOption = null
                        } else {
                            quizCompleted = true
                        }
                    },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9)),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Հաջորդ հարցը ➔", fontSize = 15.sp, color = Color.White, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

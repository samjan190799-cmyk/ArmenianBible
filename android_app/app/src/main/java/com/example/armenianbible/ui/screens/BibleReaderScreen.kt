package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.speech.tts.TextToSpeech
import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.*
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*
import kotlinx.coroutines.launch
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BibleReaderScreen(
    dbHelper: BibleDatabaseHelper,
    prefs: PreferencesManager,
    appLanguage: AppLanguage,
    armenianEdition: ArmenianEdition,
    initialBookId: Int? = null,
    initialChapter: Int? = null,
    initialSubTab: Int = 0
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()

    var selectedBook by remember { mutableStateOf<BibleBook?>(null) }
    var selectedChapter by remember { mutableStateOf<Int?>(initialChapter) }
    var mainSectionTab by remember { mutableIntStateOf(if (initialSubTab == 2) 1 else 0) } // 0: Bible, 1: Narekatsi
    var narekSubTab by remember { mutableIntStateOf(0) } // 0: Text, 1: Audio Player
    var selectedTestament by remember { mutableIntStateOf(if (initialSubTab == 1) 1 else 0) } // 0: OT, 1: NT

    var selectedNarekPrayer by remember { mutableStateOf<NarekPrayer?>(null) }
    var searchText by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }

    var fontSize by remember { mutableFloatStateOf(prefs.fontSize) }
    var currentEdition by remember { mutableStateOf(armenianEdition) }
    var showEditionSheet by remember { mutableStateOf(false) }

    // AI Explanation modal
    var explainingVerse by remember { mutableStateOf<BibleVerseText?>(null) }
    var explanationResult by remember { mutableStateOf<String?>(null) }
    var isExplainingAI by remember { mutableStateOf(false) }

    var isSpeakingBible by remember { mutableStateOf(false) }
    var tts by remember { mutableStateOf<TextToSpeech?>(null) }

    val listState = rememberLazyListState()
    val narekPlayer = remember { NarekAudioPlayer.getInstance(context) }

    DisposableEffect(Unit) {
        val ttsInstance = TextToSpeech(context) { status -> }
        tts = ttsInstance
        onDispose {
            narekPlayer.stop()
            ttsInstance.stop()
            ttsInstance.shutdown()
        }
    }

    val allBooks = remember { dbHelper.getBooks() }

    LaunchedEffect(initialBookId, initialSubTab) {
        if (initialSubTab == 2) {
            mainSectionTab = 1
        }
        if (initialBookId != null) {
            val b = dbHelper.getBook(initialBookId)
            if (b != null) {
                selectedBook = b
                selectedTestament = if (b.isNewTestament) 1 else 0
                mainSectionTab = 0
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC))
    ) {
        // MARK: - Top App Bar (iOS style clean header)
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 1.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Back Button (if inside book/chapter/prayer)
                if (selectedBook != null || selectedNarekPrayer != null) {
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            tts?.stop()
                            isSpeakingBible = false
                            if (selectedNarekPrayer != null) {
                                selectedNarekPrayer = null
                            } else if (selectedChapter != null) {
                                selectedChapter = null
                            } else {
                                selectedBook = null
                            }
                        },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF1F5F9))
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color(0xFF0F172A),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                } else {
                    // Quick Edition / Language Pill Button
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = Color(0xFFEFF6FF),
                        border = ButtonDefaults.outlinedButtonBorder().copy(
                            brush = androidx.compose.ui.graphics.SolidColor(Color(0xFFBFDBFE))
                        ),
                        modifier = Modifier.clickable { showEditionSheet = true }
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Icon(Icons.AutoMirrored.Filled.MenuBook, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> when(currentEdition) {
                                        ArmenianEdition.ARARAT -> "Արարատյան"
                                        ArmenianEdition.GRABAR -> "Գրաբար"
                                        ArmenianEdition.WESTERN -> "Արևմտահայ."
                                    }
                                    AppLanguage.RUSSIAN -> "Синодальный"
                                    AppLanguage.ENGLISH -> "KJV Bible"
                                },
                                color = Color(0xFF0284C7),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                // Title
                Text(
                    text = when {
                        selectedNarekPrayer != null -> selectedNarekPrayer!!.banNumber
                        selectedBook != null && selectedChapter != null -> "${selectedBook!!.name(appLanguage)} $selectedChapter"
                        selectedBook != null -> selectedBook!!.name(appLanguage)
                        mainSectionTab == 1 -> "Գրիգոր Նարեկացի"
                        else -> when (appLanguage) {
                            AppLanguage.ARMENIAN -> "Աստվածաշունչ"
                            AppLanguage.RUSSIAN -> "Библия"
                            AppLanguage.ENGLISH -> "Holy Bible"
                        }
                    },
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = Color(0xFF0F172A),
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        fontFamily = FontFamily.Serif
                    ),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                // Right action controls
                if (selectedBook != null && selectedChapter != null) {
                    // Audio TTS & Font Size
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(
                            onClick = {
                                if (isSpeakingBible) {
                                    tts?.stop()
                                    isSpeakingBible = false
                                } else {
                                    val verses = dbHelper.getChapterVerses(selectedBook!!.id, selectedChapter!!)
                                    val fullChapterText = verses.joinToString(". ") { it.text(appLanguage, currentEdition) }
                                    tts?.language = when(appLanguage) {
                                        AppLanguage.ARMENIAN -> Locale("hy")
                                        AppLanguage.RUSSIAN -> Locale("ru")
                                        AppLanguage.ENGLISH -> Locale("en")
                                    }
                                    tts?.speak(fullChapterText, TextToSpeech.QUEUE_FLUSH, null, "ChapterAudio")
                                    isSpeakingBible = true
                                }
                            },
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(
                                imageVector = if (isSpeakingBible) Icons.Default.Stop else Icons.AutoMirrored.Filled.VolumeUp,
                                contentDescription = "Audio",
                                tint = Color(0xFF0EA5E9),
                                modifier = Modifier.size(22.dp)
                            )
                        }

                        IconButton(onClick = {
                            if (fontSize > 13f) {
                                fontSize -= 2f
                                prefs.fontSize = fontSize
                            }
                        }, modifier = Modifier.size(32.dp)) {
                            Text("-A", color = Color(0xFF64748B), fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }

                        IconButton(onClick = {
                            if (fontSize < 30f) {
                                fontSize += 2f
                                prefs.fontSize = fontSize
                            }
                        }, modifier = Modifier.size(32.dp)) {
                            Text("+A", color = Color(0xFF64748B), fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                    }
                } else if (selectedBook == null && selectedNarekPrayer == null) {
                    // Search Button
                    IconButton(
                        onClick = { isSearchActive = !isSearchActive },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF1F5F9))
                    ) {
                        Icon(
                            imageVector = if (isSearchActive) Icons.Default.Close else Icons.Default.Search,
                            contentDescription = "Search",
                            tint = Color(0xFF0F172A),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }

        // Search Bar (expandable)
        if (isSearchActive && selectedBook == null && selectedNarekPrayer == null) {
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                shape = RoundedCornerShape(16.dp),
                color = Color.White,
                shadowElevation = 1.dp
            ) {
                OutlinedTextField(
                    value = searchText,
                    onValueChange = { searchText = it },
                    placeholder = { Text("Փնտրել գիրքը կամ համարը...", color = Color(0xFF94A3B8), fontSize = 14.sp) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF0EA5E9)) },
                    trailingIcon = if (searchText.isNotEmpty()) {
                        { IconButton(onClick = { searchText = "" }) { Icon(Icons.Default.Close, contentDescription = null, tint = Color(0xFF64748B)) } }
                    } else null,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color(0xFF0EA5E9),
                        unfocusedBorderColor = Color(0xFFE2E8F0),
                        focusedContainerColor = Color.White,
                        unfocusedContainerColor = Color.White,
                        focusedTextColor = Color(0xFF0F172A),
                        unfocusedTextColor = Color(0xFF0F172A)
                    ),
                    shape = RoundedCornerShape(16.dp),
                    singleLine = true
                )
            }
        }

        // VIEW 1: MAIN BIBLE BOOK LIST / NAREKATSI SELECTOR
        if (selectedBook == null && selectedNarekPrayer == null) {
            Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
                Spacer(modifier = Modifier.height(10.dp))

                // Top Segmented Bar: Աստվածաշունչ / Գրիգոր Նարեկացի
                TabRow(
                    selectedTabIndex = mainSectionTab,
                    containerColor = Color(0xFFEFF1F5),
                    contentColor = Color(0xFF0EA5E9),
                    modifier = Modifier.clip(RoundedCornerShape(14.dp)),
                    divider = {}
                ) {
                    Tab(
                        selected = mainSectionTab == 0,
                        onClick = { mainSectionTab = 0 },
                        text = {
                            Text(
                                text = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> "Աստվածաշունչ ✝️"
                                    AppLanguage.RUSSIAN -> "Библия ✝️"
                                    AppLanguage.ENGLISH -> "Holy Bible ✝️"
                                },
                                color = if (mainSectionTab == 0) Color(0xFF0EA5E9) else Color(0xFF64748B),
                                fontWeight = if (mainSectionTab == 0) FontWeight.Bold else FontWeight.Medium,
                                fontSize = 13.sp
                            )
                        }
                    )
                    Tab(
                        selected = mainSectionTab == 1,
                        onClick = { mainSectionTab = 1 },
                        text = {
                            Text(
                                text = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> "Գրիգոր Նարեկացի 📜"
                                    AppLanguage.RUSSIAN -> "Нарекаци 📜"
                                    AppLanguage.ENGLISH -> "St. Gregory 📜"
                                },
                                color = if (mainSectionTab == 1) Color(0xFFD97706) else Color(0xFF64748B),
                                fontWeight = if (mainSectionTab == 1) FontWeight.Bold else FontWeight.Medium,
                                fontSize = 13.sp
                            )
                        }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                if (mainSectionTab == 0) {
                    // SUB-TABS: Old Testament (Հին Կտակարան) vs New Testament (Նոր Կտակարան)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFE2E8F0).copy(alpha = 0.5f))
                            .padding(3.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (selectedTestament == 0) Color.White else Color.Transparent)
                                .clickable { selectedTestament = 0 }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = if (appLanguage == AppLanguage.ARMENIAN) "Հին Կտակարան (39)" else "Ветхий Завет (39)",
                                color = if (selectedTestament == 0) Color(0xFF0F172A) else Color(0xFF64748B),
                                fontWeight = if (selectedTestament == 0) FontWeight.Bold else FontWeight.Medium,
                                fontSize = 12.sp
                            )
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (selectedTestament == 1) Color.White else Color.Transparent)
                                .clickable { selectedTestament = 1 }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = if (appLanguage == AppLanguage.ARMENIAN) "Նոր Կտակարան (27)" else "Новый Завет (27)",
                                color = if (selectedTestament == 1) Color(0xFF0F172A) else Color(0xFF64748B),
                                fontWeight = if (selectedTestament == 1) FontWeight.Bold else FontWeight.Medium,
                                fontSize = 12.sp
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    val filteredBooks = allBooks.filter { book ->
                        (if (selectedTestament == 0) !book.isNewTestament else book.isNewTestament) &&
                                (searchText.isEmpty() ||
                                        book.name(appLanguage).contains(searchText, ignoreCase = true) ||
                                        book.shortName(appLanguage).contains(searchText, ignoreCase = true))
                    }

                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(filteredBooks, key = { it.id }) { book ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .shadow(0.5.dp, RoundedCornerShape(14.dp))
                                    .clip(RoundedCornerShape(14.dp))
                                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(14.dp))
                                    .clickable {
                                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                        selectedBook = book
                                        if (book.chaptersCount == 1) {
                                            selectedChapter = 1
                                        }
                                    },
                                colors = CardDefaults.cardColors(containerColor = Color.White)
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp, vertical = 14.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = book.name(appLanguage),
                                            style = MaterialTheme.typography.titleMedium.copy(
                                                color = Color(0xFF0F172A),
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 16.sp,
                                                fontFamily = FontFamily.Serif
                                            )
                                        )
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = "${book.chaptersCount} ${if (appLanguage == AppLanguage.ARMENIAN) "գլուխ" else "глав"}",
                                            style = MaterialTheme.typography.bodySmall.copy(color = Color(0xFF64748B), fontSize = 12.sp)
                                        )
                                    }

                                    // Abbreviation Box badge (like iOS)
                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = Color(0xFF0EA5E9).copy(alpha = 0.1f),
                                        modifier = Modifier.padding(end = 8.dp)
                                    ) {
                                        Text(
                                            text = book.shortName(appLanguage),
                                            color = Color(0xFF0284C7),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 12.sp,
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }

                                    Icon(
                                        Icons.Default.ChevronRight,
                                        contentDescription = null,
                                        tint = Color(0xFFCBD5E1),
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // NAREKATSI SECTION (2 SUB-TABS: 📄 ТЕКСТ / 🎧 ОЗВУЧКА И ПЛЕЕР)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFE2E8F0).copy(alpha = 0.5f))
                            .padding(3.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (narekSubTab == 0) Color.White else Color.Transparent)
                                .clickable {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    narekSubTab = 0
                                }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "📄 Տեքստ (Մատյան)",
                                color = if (narekSubTab == 0) Color(0xFFD97706) else Color(0xFF64748B),
                                fontWeight = if (narekSubTab == 0) FontWeight.Bold else FontWeight.Medium,
                                fontSize = 12.sp
                            )
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (narekSubTab == 1) Color.White else Color.Transparent)
                                .clickable {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    narekSubTab = 1
                                }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "🎧 Ձայնագրություն",
                                    color = if (narekSubTab == 1) Color(0xFFD97706) else Color(0xFF64748B),
                                    fontWeight = if (narekSubTab == 1) FontWeight.Bold else FontWeight.Medium,
                                    fontSize = 12.sp
                                )
                                if (narekPlayer.isPlaying.value) {
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Box(
                                        modifier = Modifier
                                            .size(6.dp)
                                            .clip(CircleShape)
                                            .background(Color(0xFF10B981))
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    if (narekSubTab == 0) {
                        // SUBTAB 0: TEXT PRAYERS LIST
                        val filteredPrayers = NarekatsiDatabase.prayers.filter { p ->
                            searchText.isEmpty() ||
                                    p.banNumber.contains(searchText, ignoreCase = true) ||
                                    p.title(appLanguage).contains(searchText, ignoreCase = true) ||
                                    p.text(appLanguage).contains(searchText, ignoreCase = true)
                        }

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(filteredPrayers) { prayer ->
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .shadow(0.5.dp, RoundedCornerShape(14.dp))
                                        .clip(RoundedCornerShape(14.dp))
                                        .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(14.dp))
                                        .clickable {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            selectedNarekPrayer = prayer
                                        },
                                    colors = CardDefaults.cardColors(containerColor = Color.White)
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Surface(
                                            shape = CircleShape,
                                            color = Color(0xFFFEF3C7),
                                            modifier = Modifier.size(42.dp)
                                        ) {
                                            Box(contentAlignment = Alignment.Center) {
                                                Icon(Icons.AutoMirrored.Filled.MenuBook, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(22.dp))
                                            }
                                        }
                                        Spacer(modifier = Modifier.width(14.dp))
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(prayer.banNumber, color = Color(0xFFD97706), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                            Spacer(modifier = Modifier.height(2.dp))
                                            Text(prayer.title(appLanguage), color = Color(0xFF0F172A), fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                        }
                                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFFCBD5E1))
                                    }
                                }
                            }
                        }
                    } else {
                        // SUBTAB 1: DEDICATED AUDIO PLAYER & 95 CHAPTERS PLAYLIST
                        val currentPrayerId = narekPlayer.currentlyPlayingId.value ?: narekPlayer.savedPrayerId.value
                        val activePrayer = NarekatsiDatabase.prayers.find { it.id == currentPrayerId } ?: NarekatsiDatabase.prayers[0]

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(14.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            // 1. HERO PLAYER CARD
                            item {
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .shadow(1.dp, RoundedCornerShape(20.dp))
                                        .clip(RoundedCornerShape(20.dp))
                                        .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp)),
                                    colors = CardDefaults.cardColors(containerColor = Color.White)
                                ) {
                                    Column(modifier = Modifier.padding(18.dp)) {
                                        // Top Row: Ban Number + Voice Selector
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Text(
                                                    text = activePrayer.banNumber,
                                                    color = Color(0xFFD97706),
                                                    fontSize = 17.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    fontFamily = FontFamily.Serif
                                                )
                                                if (narekPlayer.isStreaming.value) {
                                                    Spacer(modifier = Modifier.width(8.dp))
                                                    Text("• Բեռնվում է...", color = Color(0xFF64748B), fontSize = 11.sp)
                                                }
                                            }

                                            // Voice Switcher (Armenian Sos Sargsyan / Russian Oleg Molenko)
                                            Surface(
                                                shape = RoundedCornerShape(8.dp),
                                                color = Color(0xFFFEF3C7),
                                                modifier = Modifier.clickable {
                                                    val newLang = if (narekPlayer.voiceLanguage.value == AppLanguage.ARMENIAN) AppLanguage.RUSSIAN else AppLanguage.ARMENIAN
                                                    narekPlayer.voiceLanguage.value = newLang
                                                    narekPlayer.play(activePrayer, newLang)
                                                }
                                            ) {
                                                Text(
                                                    text = if (narekPlayer.voiceLanguage.value == AppLanguage.ARMENIAN) "🇦🇲 Սոս Սարգսյան" else "🇷🇺 О. Моленко",
                                                    color = Color(0xFFD97706),
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                                )
                                            }
                                        }

                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = activePrayer.title(narekPlayer.voiceLanguage.value),
                                            color = Color(0xFF0F172A),
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.SemiBold,
                                            maxLines = 2,
                                            overflow = TextOverflow.Ellipsis
                                        )

                                        Spacer(modifier = Modifier.height(14.dp))

                                        // Seek Slider
                                        val curMs = narekPlayer.currentTimeMs.longValue
                                        val durMs = if (narekPlayer.durationMs.longValue > 0) narekPlayer.durationMs.longValue else 300000L
                                        val sliderPos = (curMs.toFloat() / durMs.toFloat()).coerceIn(0f, 1f)

                                        Slider(
                                            value = sliderPos,
                                            onValueChange = { frac ->
                                                val targetMs = (frac * durMs).toLong()
                                                narekPlayer.seekTo(targetMs)
                                            },
                                            colors = SliderDefaults.colors(
                                                thumbColor = Color(0xFFD97706),
                                                activeTrackColor = Color(0xFFD97706),
                                                inactiveTrackColor = Color(0xFFE2E8F0)
                                            )
                                        )

                                        // Time indicators
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            val curSec = curMs / 1000
                                            val durSec = durMs / 1000
                                            Text(
                                                text = String.format("%02d:%02d", curSec / 60, curSec % 60),
                                                color = Color(0xFF64748B),
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold
                                            )
                                            Text(
                                                text = String.format("%02d:%02d", durSec / 60, durSec % 60),
                                                color = Color(0xFF64748B),
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold
                                            )
                                        }

                                        Spacer(modifier = Modifier.height(10.dp))

                                        // Playback Controls Row: Prev, -15s, Play/Pause, +15s, Next
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceEvenly,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            IconButton(onClick = { narekPlayer.playPreviousPrayer() }) {
                                                Icon(Icons.Default.SkipPrevious, contentDescription = "Prev", tint = Color(0xFF0F172A), modifier = Modifier.size(24.dp))
                                            }

                                            IconButton(onClick = { narekPlayer.skipBackward(15) }) {
                                                Icon(Icons.Default.Replay10, contentDescription = "Rewind", tint = Color(0xFF0F172A), modifier = Modifier.size(24.dp))
                                            }

                                            // Main Big Play/Pause Button
                                            Surface(
                                                shape = CircleShape,
                                                shadowElevation = 6.dp,
                                                modifier = Modifier
                                                    .size(56.dp)
                                                    .clickable {
                                                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                                        narekPlayer.togglePlay(activePrayer)
                                                    }
                                            ) {
                                                Box(
                                                    modifier = Modifier
                                                        .fillMaxSize()
                                                        .background(
                                                            Brush.linearGradient(
                                                                listOf(Color(0xFFF59E0B), Color(0xFFD97706))
                                                            )
                                                        ),
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Icon(
                                                        imageVector = if (narekPlayer.isPlaying.value) Icons.Default.Pause else Icons.Default.PlayArrow,
                                                        contentDescription = "Play/Pause",
                                                        tint = Color.White,
                                                        modifier = Modifier.size(30.dp)
                                                    )
                                                }
                                            }

                                            IconButton(onClick = { narekPlayer.skipForward(15) }) {
                                                Icon(Icons.Default.Forward10, contentDescription = "Forward", tint = Color(0xFF0F172A), modifier = Modifier.size(24.dp))
                                            }

                                            IconButton(onClick = { narekPlayer.playNextPrayer() }) {
                                                Icon(Icons.Default.SkipNext, contentDescription = "Next", tint = Color(0xFF0F172A), modifier = Modifier.size(24.dp))
                                            }
                                        }

                                        // Remembered position indicator
                                        if (narekPlayer.savedTimeMs.longValue > 0 && !narekPlayer.isPlaying.value) {
                                            Spacer(modifier = Modifier.height(10.dp))
                                            val savedSec = narekPlayer.savedTimeMs.longValue / 1000
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.Center,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Icon(Icons.Default.History, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(13.dp))
                                                Spacer(modifier = Modifier.width(4.dp))
                                                Text(
                                                    text = "Պահպանված դիրք՝ ${String.format("%02d:%02d", savedSec / 60, savedSec % 60)} (Գլուխ ${narekPlayer.savedPrayerId.value})",
                                                    color = Color(0xFF64748B),
                                                    fontSize = 11.sp
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. PLAYLIST HEADER
                            item {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "📻 Բոլոր 95 Գլուխները (Плейлист)",
                                        color = Color(0xFF0F172A),
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Text("95 աղոթք", color = Color(0xFF64748B), fontSize = 12.sp)
                                }
                            }

                            // 3. 95 CHAPTERS PLAYLIST ITEMS
                            items(NarekatsiDatabase.prayers) { prayer ->
                                val isCurrent = (narekPlayer.currentlyPlayingId.value == prayer.id) ||
                                        (narekPlayer.currentlyPlayingId.value == null && narekPlayer.savedPrayerId.value == prayer.id)
                                val isThisPlaying = narekPlayer.isPlaying.value && narekPlayer.currentlyPlayingId.value == prayer.id

                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .shadow(0.5.dp, RoundedCornerShape(14.dp))
                                        .clip(RoundedCornerShape(14.dp))
                                        .border(
                                            if (isCurrent) 1.5.dp else 1.dp,
                                            if (isCurrent) Color(0xFFD97706).copy(alpha = 0.8f) else Color(0xFFE2E8F0),
                                            RoundedCornerShape(14.dp)
                                        )
                                        .clickable {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            narekPlayer.playPrayer(prayer, narekPlayer.voiceLanguage.value)
                                        },
                                    colors = CardDefaults.cardColors(
                                        containerColor = if (isCurrent) Color(0xFFFEF3C7).copy(alpha = 0.35f) else Color.White
                                    )
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(horizontal = 14.dp, vertical = 10.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Surface(
                                            shape = CircleShape,
                                            color = if (isCurrent) Color(0xFFFEF3C7) else Color(0xFFF1F5F9),
                                            modifier = Modifier.size(38.dp)
                                        ) {
                                            Box(contentAlignment = Alignment.Center) {
                                                if (isThisPlaying) {
                                                    Icon(Icons.Default.GraphicEq, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(18.dp))
                                                } else {
                                                    Text(
                                                        text = "${prayer.id}",
                                                        color = if (isCurrent) Color(0xFFD97706) else Color(0xFF64748B),
                                                        fontWeight = FontWeight.Bold,
                                                        fontSize = 13.sp
                                                    )
                                                }
                                            }
                                        }

                                        Spacer(modifier = Modifier.width(12.dp))

                                        Column(modifier = Modifier.weight(1f)) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Text(
                                                    text = prayer.banNumber,
                                                    color = if (isCurrent) Color(0xFFD97706) else Color(0xFF0F172A),
                                                    fontSize = 13.sp,
                                                    fontWeight = FontWeight.Bold
                                                )
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Text(
                                                    text = "• ${prayer.formattedTimestamp(narekPlayer.voiceLanguage.value)}",
                                                    color = if (isCurrent) Color(0xFFD97706) else Color(0xFF94A3B8),
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.SemiBold
                                                )
                                            }
                                            Text(
                                                text = prayer.title(narekPlayer.voiceLanguage.value),
                                                color = Color(0xFF64748B),
                                                fontSize = 12.sp,
                                                maxLines = 1,
                                                overflow = TextOverflow.Ellipsis
                                            )
                                        }

                                        Icon(
                                            imageVector = if (isThisPlaying) Icons.Default.PauseCircle else Icons.Default.PlayCircle,
                                            contentDescription = "Play",
                                            tint = if (isThisPlaying) Color(0xFFD97706) else Color(0xFFCBD5E1),
                                            modifier = Modifier.size(26.dp)
                                        )
                                    }
                                }
                            }

                            item {
                                Spacer(modifier = Modifier.height(30.dp))
                            }
                        }
                    }
                }
            }
        }
        // VIEW 2: NAREKATSI PRAYER DETAIL WITH AUDIO
        else if (selectedNarekPrayer != null) {
            val p = selectedNarekPrayer!!
            Card(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .shadow(1.dp, RoundedCornerShape(20.dp))
                    .clip(RoundedCornerShape(20.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
                    .verticalScroll(rememberScrollState()),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = p.banNumber,
                            color = Color(0xFFD97706),
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            val isThisPrayerPlaying = narekPlayer.isPlaying.value && narekPlayer.currentlyPlayingId.value == p.id
                            IconButton(onClick = {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                narekPlayer.togglePlay(p, appLanguage)
                            }) {
                                Icon(
                                    imageVector = if (isThisPrayerPlaying) Icons.Default.Stop else Icons.AutoMirrored.Filled.VolumeUp,
                                    contentDescription = "Audio",
                                    tint = if (isThisPrayerPlaying) Color(0xFFEF4444) else Color(0xFFD97706)
                                )
                            }

                            IconButton(onClick = {
                                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                val clip = ClipData.newPlainText("Prayer", "${p.title(appLanguage)}\n\n${p.text(appLanguage)}")
                                clipboard.setPrimaryClip(clip)
                                Toast.makeText(context, "Պատճենված է", Toast.LENGTH_SHORT).show()
                            }) {
                                Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8))
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = p.title(appLanguage),
                        color = Color(0xFF0F172A),
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )

                    HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), color = Color(0xFFE2E8F0))

                    Text(
                        text = p.text(appLanguage),
                        color = Color(0xFF1E293B),
                        fontSize = 16.sp,
                        lineHeight = 26.sp,
                        fontFamily = FontFamily.Serif
                    )
                }
            }
        }
        // VIEW 3: CHAPTER GRID PICKER
        else if (selectedChapter == null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Ընտրեք գլուխը (1-${selectedBook!!.chaptersCount}):",
                    color = Color(0xFF64748B),
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(bottom = 14.dp)
                )

                LazyVerticalGrid(
                    columns = GridCells.Fixed(5),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items((1..selectedBook!!.chaptersCount).toList()) { ch ->
                        Box(
                            modifier = Modifier
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(14.dp))
                                .background(Color.White)
                                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(14.dp))
                                .clickable {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                    selectedChapter = ch
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "$ch",
                                color = Color(0xFF0F172A),
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            }
        }
        // VIEW 4: CHAPTER VERSES READER
        else {
            val verses = remember(selectedBook, selectedChapter) {
                dbHelper.getChapterVerses(selectedBook!!.id, selectedChapter!!)
            }

            Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
                Spacer(modifier = Modifier.height(8.dp))

                // Chapter Prev / Next Pills
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Button(
                        enabled = selectedChapter!! > 1,
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            selectedChapter = selectedChapter!! - 1
                        },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFEFF1F5),
                            contentColor = Color(0xFF0F172A),
                            disabledContainerColor = Color(0xFFF1F5F9).copy(alpha = 0.5f),
                            disabledContentColor = Color(0xFFCBD5E1)
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = Color(0xFF0F172A), modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Նախորդ", color = Color(0xFF0F172A), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    }

                    Text(
                        text = "Գլուխ ${selectedChapter} / ${selectedBook!!.chaptersCount}",
                        color = Color(0xFF64748B),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Button(
                        enabled = selectedChapter!! < selectedBook!!.chaptersCount,
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            selectedChapter = selectedChapter!! + 1
                        },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFEFF1F5),
                            contentColor = Color(0xFF0F172A),
                            disabledContainerColor = Color(0xFFF1F5F9).copy(alpha = 0.5f),
                            disabledContentColor = Color(0xFFCBD5E1)
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Text("Հաջորդ", color = Color(0xFF0F172A), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = Color(0xFF0F172A), modifier = Modifier.size(16.dp))
                    }
                }

                // Verses List
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(verses, key = { it.id }) { v ->
                        val text = v.text(appLanguage, currentEdition)
                        val ref = v.reference(appLanguage, selectedBook!!.name(appLanguage))
                        var isFav by remember(v) { mutableStateOf(prefs.isFavorite(ref)) }

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .shadow(0.5.dp, RoundedCornerShape(14.dp))
                                .clip(RoundedCornerShape(14.dp))
                                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(14.dp)),
                            colors = CardDefaults.cardColors(containerColor = Color.White)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Surface(
                                        shape = CircleShape,
                                        color = Color(0xFFE0F2FE)
                                    ) {
                                        Text(
                                            text = "${v.verseNumber}",
                                            color = Color(0xFF0284C7),
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 12.sp,
                                            modifier = Modifier.padding(horizontal = 9.dp, vertical = 2.dp)
                                        )
                                    }

                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        // AI Explain button
                                        IconButton(
                                            onClick = {
                                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                explainingVerse = v
                                                explanationResult = null
                                                isExplainingAI = true

                                                val prompt = "Դու Աստվածաշնչի փորձագետ ես: Բացատրիր այս համարը՝ «${v.text(appLanguage, currentEdition)}» ($ref): Տուր խորը, բայց պարզ բացատրություն:"
                                                val key = when(prefs.activeProvider) {
                                                    AIProvider.GEMINI -> prefs.geminiApiKey
                                                    AIProvider.CHATGPT -> prefs.openaiApiKey
                                                    AIProvider.CLAUDE -> prefs.anthropicApiKey
                                                }

                                                scope.launch {
                                                    if (key.trim().isNotEmpty()) {
                                                        val res = AIService.chatGuide(prefs.activeProvider, key, prompt, appLanguage)
                                                        isExplainingAI = false
                                                        res.onSuccess { explanationResult = it }
                                                            .onFailure { explanationResult = "Չհաջողվեց ստանալ ИИ մեկնաբանությունը: ${it.localizedMessage}" }
                                                    } else {
                                                        isExplainingAI = false
                                                        explanationResult = "ИИ մեկնաբանության համար խնդրում ենք մուտքագրել API բանալին Կարգավորումներում ⚙️"
                                                    }
                                                }
                                            },
                                            modifier = Modifier.size(30.dp)
                                        ) {
                                            Icon(Icons.Default.AutoAwesome, contentDescription = "Explain", tint = Color(0xFFA855F7), modifier = Modifier.size(16.dp))
                                        }

                                        // Copy
                                        IconButton(
                                            onClick = {
                                                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                                val clip = ClipData.newPlainText("Verse", "$text ($ref)")
                                                clipboard.setPrimaryClip(clip)
                                                Toast.makeText(context, "Պատճենված է!", Toast.LENGTH_SHORT).show()
                                            },
                                            modifier = Modifier.size(30.dp)
                                        ) {
                                            Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                        }

                                        // Share Card
                                        IconButton(
                                            onClick = {
                                                val verseObj = BibleVerse(
                                                    textHy = v.textHy,
                                                    textRu = v.textRu,
                                                    textEn = v.textEn,
                                                    refHy = ref,
                                                    refRu = ref,
                                                    refEn = ref
                                                )
                                                VerseCardExporter.shareVerseAsImage(context, verseObj, appLanguage, prefs.accentTheme)
                                            },
                                            modifier = Modifier.size(30.dp)
                                        ) {
                                            Icon(Icons.Default.Share, contentDescription = "Share", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                        }

                                        // Favorite
                                        IconButton(
                                            onClick = {
                                                val item = FavoriteItem(
                                                    textHy = v.textHy,
                                                    textRu = v.textRu,
                                                    textEn = v.textEn,
                                                    refHy = ref,
                                                    refRu = ref,
                                                    refEn = ref
                                                )
                                                if (isFav) {
                                                    prefs.removeFavorite(item)
                                                    isFav = false
                                                } else {
                                                    prefs.addFavorite(item)
                                                    isFav = true
                                                }
                                            },
                                            modifier = Modifier.size(30.dp)
                                        ) {
                                            Icon(
                                                imageVector = if (isFav) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                                contentDescription = "Fav",
                                                tint = if (isFav) Color(0xFFEF4444) else Color(0xFF94A3B8),
                                                modifier = Modifier.size(16.dp)
                                            )
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(6.dp))

                                Text(
                                    text = text,
                                    color = Color(0xFF1E293B),
                                    fontSize = fontSize.sp,
                                    lineHeight = (fontSize * 1.45f).sp,
                                    fontFamily = FontFamily.Serif
                                )
                            }
                        }
                    }

                    item {
                        Spacer(modifier = Modifier.height(24.dp))
                    }
                }
            }
        }

        // Edition Picker Bottom Sheet
        if (showEditionSheet) {
            ModalBottomSheet(
                onDismissRequest = { showEditionSheet = false },
                containerColor = Color.White,
                shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("📖 Ընտրեք Աստվածաշնչի տարբերակը", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Color(0xFF0F172A))
                    Spacer(modifier = Modifier.height(14.dp))

                    ArmenianEdition.entries.forEach { edition ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    currentEdition = edition
                                    prefs.armenianEdition = edition
                                    showEditionSheet = false
                                }
                                .padding(vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = currentEdition == edition,
                                onClick = {
                                    currentEdition = edition
                                    prefs.armenianEdition = edition
                                    showEditionSheet = false
                                },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(edition.displayName, color = Color(0xFF0F172A), fontSize = 15.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                }
            }
        }

        // AI Verse Explanation Dialog
        if (explainingVerse != null) {
            AlertDialog(
                onDismissRequest = { explainingVerse = null },
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color(0xFFA855F7))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("ИИ Толкование стиха", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Color(0xFF0F172A))
                    }
                },
                text = {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .verticalScroll(rememberScrollState())
                    ) {
                        Text(
                            text = "«${explainingVerse!!.text(appLanguage, currentEdition)}»",
                            fontFamily = FontFamily.Serif,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color(0xFF0284C7)
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        if (isExplainingAI) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                CircularProgressIndicator(modifier = Modifier.size(18.dp), color = Color(0xFFA855F7), strokeWidth = 2.dp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Text("ИИ подготавливает богословское толкование...", color = Color(0xFF64748B), fontSize = 13.sp)
                            }
                        } else if (explanationResult != null) {
                            Text(
                                text = explanationResult!!,
                                color = Color(0xFF1E293B),
                                fontSize = 14.sp,
                                lineHeight = 22.sp
                            )
                        }
                    }
                },
                confirmButton = {
                    Button(
                        onClick = { explainingVerse = null },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9))
                    ) {
                        Text("Փակել", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                },
                containerColor = Color.White,
                shape = RoundedCornerShape(20.dp)
            )
        }
    }
}

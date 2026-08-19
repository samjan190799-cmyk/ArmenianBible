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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*
import java.util.Locale

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

    var selectedBook by remember { mutableStateOf<BibleBook?>(null) }
    var selectedChapter by remember { mutableStateOf<Int?>(initialChapter) }
    var selectedTab by remember { mutableIntStateOf(initialSubTab) } // 0: OT, 1: NT, 2: Narekatsi
    var selectedNarekPrayer by remember { mutableStateOf<NarekPrayer?>(null) }
    var searchQuery by remember { mutableStateOf("") }
    var fontSize by remember { mutableFloatStateOf(prefs.fontSize) }

    var isSpeaking by remember { mutableStateOf(false) }
    var tts by remember { mutableStateOf<TextToSpeech?>(null) }

    DisposableEffect(Unit) {
        val ttsInstance = TextToSpeech(context) { status -> }
        tts = ttsInstance
        onDispose {
            ttsInstance.stop()
            ttsInstance.shutdown()
        }
    }

    val allBooks = remember { dbHelper.getBooks() }

    LaunchedEffect(initialBookId, initialSubTab) {
        selectedTab = initialSubTab
        if (initialBookId != null) {
            val b = dbHelper.getBook(initialBookId)
            if (b != null) {
                selectedBook = b
                selectedTab = if (b.isNewTestament) 1 else 0
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC))
            .padding(16.dp)
    ) {
        // Navigation header
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (selectedBook != null || selectedNarekPrayer != null) {
                IconButton(
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        tts?.stop()
                        isSpeaking = false
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
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color(0xFF0F172A), modifier = Modifier.size(20.dp))
                }
                Spacer(modifier = Modifier.width(8.dp))
            }

            Text(
                text = when {
                    selectedNarekPrayer != null -> selectedNarekPrayer!!.banNumber
                    selectedBook != null && selectedChapter != null -> "${selectedBook!!.name(appLanguage)} — Глава $selectedChapter"
                    selectedBook != null -> selectedBook!!.name(appLanguage)
                    else -> when (appLanguage) {
                        AppLanguage.ARMENIAN -> "Աստվածաշունչ"
                        AppLanguage.RUSSIAN -> "Библия"
                        AppLanguage.ENGLISH -> "Holy Bible"
                    }
                },
                style = MaterialTheme.typography.titleLarge.copy(
                    color = Color(0xFF0F172A),
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    fontFamily = FontFamily.Serif
                ),
                modifier = Modifier.weight(1f)
            )

            if (selectedBook != null && selectedChapter != null) {
                // Font Controls
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = {
                        if (fontSize > 12f) {
                            fontSize -= 2f
                            prefs.fontSize = fontSize
                        }
                    }) {
                        Text("-A", color = Color(0xFF64748B), fontWeight = FontWeight.Bold)
                    }
                    Text("${fontSize.toInt()}", color = Color(0xFF0F172A), fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    IconButton(onClick = {
                        if (fontSize < 32f) {
                            fontSize += 2f
                            prefs.fontSize = fontSize
                        }
                    }) {
                        Text("+A", color = Color(0xFF64748B), fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // VIEW 1: MAIN BIBLE + NAREKATSI SELECTOR
        if (selectedBook == null && selectedNarekPrayer == null) {
            // Search Bar
            if (selectedTab != 2) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Փնտրել գիրքը...", color = Color(0xFF94A3B8)) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF94A3B8)) },
                    trailingIcon = if (searchQuery.isNotEmpty()) {
                        { IconButton(onClick = { searchQuery = "" }) { Icon(Icons.Default.Close, contentDescription = null, tint = Color(0xFF64748B)) } }
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
                    shape = RoundedCornerShape(16.dp)
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Top Tabs: Old Testament, New Testament, St. Gregory of Narek
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color(0xFFEFF1F5),
                contentColor = Color(0xFF0EA5E9),
                modifier = Modifier.clip(RoundedCornerShape(14.dp)),
                divider = {}
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = {
                        Text(
                            text = if (appLanguage == AppLanguage.ARMENIAN) "Հին Կտակարան" else "Ветхий Завет",
                            color = if (selectedTab == 0) Color(0xFF0EA5E9) else Color(0xFF64748B),
                            fontWeight = if (selectedTab == 0) FontWeight.Bold else FontWeight.Medium,
                            fontSize = 12.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = {
                        Text(
                            text = if (appLanguage == AppLanguage.ARMENIAN) "Նոր Կտակարան" else "Новый Завет",
                            color = if (selectedTab == 1) Color(0xFF0EA5E9) else Color(0xFF64748B),
                            fontWeight = if (selectedTab == 1) FontWeight.Bold else FontWeight.Medium,
                            fontSize = 12.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                )
                Tab(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    text = {
                        Text(
                            text = if (appLanguage == AppLanguage.ARMENIAN) "Նարեկացի 📜" else "Нарекаци 📜",
                            color = if (selectedTab == 2) Color(0xFFD97706) else Color(0xFF64748B),
                            fontWeight = if (selectedTab == 2) FontWeight.Bold else FontWeight.Medium,
                            fontSize = 12.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            if (selectedTab == 2) {
                // NAREKATSI SECTION
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(NarekatsiDatabase.prayers) { prayer ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .shadow(1.dp, RoundedCornerShape(16.dp))
                                .clip(RoundedCornerShape(16.dp))
                                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(16.dp))
                                .clickable { selectedNarekPrayer = prayer },
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
                                        Icon(Icons.Default.MenuBook, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(22.dp))
                                    }
                                }
                                Spacer(modifier = Modifier.width(14.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(prayer.banNumber, color = Color(0xFFD97706), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                    Text(prayer.title(appLanguage), color = Color(0xFF0F172A), fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                }
                                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF94A3B8))
                            }
                        }
                    }
                }
            } else {
                // BIBLE BOOKS SECTION
                val filteredBooks = allBooks.filter { book ->
                    (if (selectedTab == 0) !book.isNewTestament else book.isNewTestament) &&
                            (searchQuery.isEmpty() || book.name(appLanguage).contains(searchQuery, ignoreCase = true) || book.shortName(appLanguage).contains(searchQuery, ignoreCase = true))
                }

                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(filteredBooks) { book ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .shadow(1.dp, RoundedCornerShape(16.dp))
                                .clip(RoundedCornerShape(16.dp))
                                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(16.dp))
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
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = book.name(appLanguage),
                                        style = MaterialTheme.typography.titleMedium.copy(
                                            color = Color(0xFF0F172A),
                                            fontWeight = FontWeight.SemiBold,
                                            fontSize = 16.sp
                                        )
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = "${book.chaptersCount} ${if (appLanguage == AppLanguage.ARMENIAN) "գլուխ" else "глав"}",
                                        style = MaterialTheme.typography.bodySmall.copy(color = Color(0xFF64748B))
                                    )
                                }
                                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF94A3B8))
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

                        Row {
                            IconButton(onClick = {
                                if (isSpeaking) {
                                    tts?.stop()
                                    isSpeaking = false
                                } else {
                                    val textToRead = "${p.title(appLanguage)}. ${p.text(appLanguage)}"
                                    tts?.language = when(appLanguage) {
                                        AppLanguage.ARMENIAN -> Locale("hy")
                                        AppLanguage.RUSSIAN -> Locale("ru")
                                        AppLanguage.ENGLISH -> Locale("en")
                                    }
                                    tts?.speak(textToRead, TextToSpeech.QUEUE_FLUSH, null, "NarekAudio")
                                    isSpeaking = true
                                }
                            }) {
                                Icon(
                                    imageVector = if (isSpeaking) Icons.Default.Stop else Icons.Default.VolumeUp,
                                    contentDescription = "Audio",
                                    tint = Color(0xFFD97706)
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
            Text(
                text = "Ընտրեք գլուխը (1-${selectedBook!!.chaptersCount}):",
                color = Color(0xFF64748B),
                modifier = Modifier.padding(bottom = 12.dp)
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
        // VIEW 4: CHAPTER VERSES READER
        else {
            val verses = remember(selectedBook, selectedChapter) {
                dbHelper.getChapterVerses(selectedBook!!.id, selectedChapter!!)
            }

            // Next / Prev Chapter Controls
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 10.dp),
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
                        contentColor = Color(0xFF0F172A)
                    )
                ) {
                    Icon(Icons.Default.ArrowBack, contentDescription = null, tint = Color(0xFF0F172A), modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Նախորդ", color = Color(0xFF0F172A), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }

                Button(
                    enabled = selectedChapter!! < selectedBook!!.chaptersCount,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        selectedChapter = selectedChapter!! + 1
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFEFF1F5),
                        contentColor = Color(0xFF0F172A)
                    )
                ) {
                    Text("Հաջորդ", color = Color(0xFF0F172A), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(Icons.Default.ArrowForward, contentDescription = null, tint = Color(0xFF0F172A), modifier = Modifier.size(16.dp))
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(verses) { v ->
                    val text = v.text(appLanguage, armenianEdition)
                    val ref = v.reference(appLanguage, selectedBook!!.name(appLanguage))
                    var isFav by remember(v) { mutableStateOf(prefs.isFavorite(ref)) }

                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(1.dp, RoundedCornerShape(16.dp))
                            .clip(RoundedCornerShape(16.dp))
                            .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(16.dp)),
                        colors = CardDefaults.cardColors(containerColor = Color.White)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
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
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 2.dp)
                                    )
                                }

                                Row {
                                    IconButton(
                                        onClick = {
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            val clip = ClipData.newPlainText("Verse", "$text ($ref)")
                                            clipboard.setPrimaryClip(clip)
                                            Toast.makeText(context, "Պատճենված է", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                    }

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
                                        modifier = Modifier.size(32.dp)
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

                            Spacer(modifier = Modifier.height(8.dp))

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
            }
        }
    }
}

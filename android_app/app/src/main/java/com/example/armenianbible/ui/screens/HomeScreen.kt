package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*
import com.example.armenianbible.widget.BibleAppWidget

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    dbHelper: BibleDatabaseHelper,
    prefs: PreferencesManager,
    appLanguage: AppLanguage,
    onLanguageChange: (AppLanguage) -> Unit,
    armenianEdition: ArmenianEdition,
    onEditionChange: (ArmenianEdition) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenQuiz: () -> Unit,
    onOpenNarek: () -> Unit
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    var currentVerse by remember {
        mutableStateOf(dbHelper.getRandomVerse() ?: BibleVerse(
            textHy = "Ի սկզբանէ էր Բանն, եւ Բանն էր առ Աստուած, եւ Աստուած էր Բանն:",
            textRu = "В начале было Слово, и Слово было у Бога, и Слово было Бог.",
            textEn = "In the beginning was the Word, and the Word was with God, and the Word was God.",
            refHy = "Յովհաննէս 1:1",
            refRu = "От Иоанна 1:1",
            refEn = "John 1:1"
        ))
    }

    var isFav by remember(currentVerse) {
        mutableStateOf(prefs.isFavorite(currentVerse.refHy))
    }

    val accentColor = Color(android.graphics.Color.parseColor(prefs.accentTheme.colorHex))
    val secondaryAccentColor = Color(android.graphics.Color.parseColor(prefs.accentTheme.secondaryColorHex))

    // Save for widget
    LaunchedEffect(currentVerse) {
        prefs.saveCurrentVerseForWidget(currentVerse)
        BibleAppWidget.sendUpdateBroadcast(context)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F172A))
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Sleek Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Աստվածաշունչ ✝️",
                    style = MaterialTheme.typography.titleLarge.copy(
                        color = Color(0xFFF8FAFC),
                        fontWeight = FontWeight.Bold,
                        fontSize = 22.sp
                    )
                )
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Օրվա / Պատահական տող"
                        AppLanguage.RUSSIAN -> "Стих дня / Случайный стих"
                        AppLanguage.ENGLISH -> "Verse of the Day"
                    },
                    style = MaterialTheme.typography.bodySmall.copy(color = Color(0xFF94A3B8), fontSize = 12.sp)
                )
            }

            // Fully Rounded Settings Gear Icon
            IconButton(
                onClick = onOpenSettings,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color(0xFF1E293B))
                    .border(1.dp, Color(0xFF334155), CircleShape)
            ) {
                Icon(Icons.Default.Settings, contentDescription = "Settings", tint = Color.White)
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Edition selector for Armenian (Fully Rounded Segmented Pills)
        if (appLanguage == AppLanguage.ARMENIAN) {
            SingleChoiceSegmentedButtonRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(CircleShape)
            ) {
                ArmenianEdition.entries.forEachIndexed { index, edition ->
                    SegmentedButton(
                        selected = armenianEdition == edition,
                        onClick = { onEditionChange(edition) },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = ArmenianEdition.entries.size),
                        colors = SegmentedButtonDefaults.colors(
                            activeContainerColor = accentColor,
                            activeContentColor = Color.White,
                            inactiveContainerColor = Color(0xFF1E293B),
                            inactiveContentColor = Color(0xFF94A3B8)
                        )
                    ) {
                        Text(
                            text = edition.displayName,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            maxLines = 1,
                            softWrap = false,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(14.dp))
        }

        // Main Verse Card (Glassmorphic Rounded Card)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(28.dp))
                .border(
                    width = 1.2.dp,
                    brush = Brush.linearGradient(colors = listOf(accentColor, secondaryAccentColor, Color(0xFFEC4899))),
                    shape = RoundedCornerShape(28.dp)
                ),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B).copy(alpha = 0.95f))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = Color(0xFFF59E0B),
                    modifier = Modifier.size(30.dp)
                )

                Spacer(modifier = Modifier.height(14.dp))

                AnimatedContent(
                    targetState = currentVerse,
                    transitionSpec = {
                        fadeIn() + slideInVertically { it / 2 } togetherWith fadeOut() + slideOutVertically { -it / 2 }
                    },
                    label = "VerseAnim"
                ) { verse ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "«${verse.text(appLanguage)}»",
                            style = MaterialTheme.typography.bodyLarge.copy(
                                color = Color(0xFFF8FAFC),
                                fontSize = 17.sp,
                                lineHeight = 25.sp,
                                textAlign = TextAlign.Center,
                                fontWeight = FontWeight.Normal
                            )
                        )

                        Spacer(modifier = Modifier.height(18.dp))

                        Text(
                            text = "— ${verse.reference(appLanguage)}",
                            style = MaterialTheme.typography.titleMedium.copy(
                                color = secondaryAccentColor,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center,
                                fontSize = 16.sp
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Action Buttons Row (Like, Copy, Share)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            val item = FavoriteItem(
                                textHy = currentVerse.textHy,
                                textRu = currentVerse.textRu,
                                textEn = currentVerse.textEn,
                                refHy = currentVerse.refHy,
                                refRu = currentVerse.refRu,
                                refEn = currentVerse.refEn
                            )
                            if (isFav) {
                                prefs.removeFavorite(item)
                                isFav = false
                                Toast.makeText(context, "Հեռացված է էջանշաններից", Toast.LENGTH_SHORT).show()
                            } else {
                                prefs.addFavorite(item)
                                isFav = true
                                Toast.makeText(context, "Ավելացված է էջանշաններում ❤️", Toast.LENGTH_SHORT).show()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = if (isFav) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Favorite",
                            tint = if (isFav) Color(0xFFEF4444) else Color(0xFF94A3B8),
                            modifier = Modifier.size(24.dp)
                        )
                    }

                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            val clip = ClipData.newPlainText("Verse", "«${currentVerse.text(appLanguage)}» — ${currentVerse.reference(appLanguage)}")
                            clipboard.setPrimaryClip(clip)
                            Toast.makeText(context, "Պատճենված է!", Toast.LENGTH_SHORT).show()
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.ContentCopy,
                            contentDescription = "Copy",
                            tint = Color(0xFF94A3B8),
                            modifier = Modifier.size(22.dp)
                        )
                    }

                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            val sendIntent = Intent().apply {
                                action = Intent.ACTION_SEND
                                putExtra(Intent.EXTRA_TEXT, "«${currentVerse.text(appLanguage)}»\n— ${currentVerse.reference(appLanguage)}\n\n(Armenian Bible App)")
                                type = "text/plain"
                            }
                            val shareIntent = Intent.createChooser(sendIntent, "Կիսվել стихом")
                            context.startActivity(shareIntent)
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = "Share",
                            tint = Color(0xFF94A3B8),
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Fully Rounded Pill Buttons (Random Verse & AI Verse) with Zero Overflow
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Button(
                onClick = {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    val newVerse = dbHelper.getRandomVerse()
                    if (newVerse != null) {
                        currentVerse = newVerse
                    }
                },
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
                shape = CircleShape,
                contentPadding = PaddingValues(horizontal = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E293B)),
                border = ButtonDefaults.outlinedButtonBorder().copy(brush = Brush.linearGradient(listOf(Color(0xFF334155), Color(0xFF475569))))
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Պատահական",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        softWrap = false,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            Button(
                onClick = {
                    val key = when(prefs.activeProvider) {
                        AIProvider.GEMINI -> prefs.geminiApiKey
                        AIProvider.CHATGPT -> prefs.openaiApiKey
                        AIProvider.CLAUDE -> prefs.anthropicApiKey
                    }

                    if (key.trim().isEmpty()) {
                        Toast.makeText(context, "Впишите API Ключ в Настройках ⚙️", Toast.LENGTH_SHORT).show()
                        onOpenSettings()
                    } else {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        val newVerse = dbHelper.getRandomVerse()
                        if (newVerse != null) currentVerse = newVerse
                    }
                },
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
                shape = CircleShape,
                contentPadding = PaddingValues(horizontal = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = accentColor)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "ИИ Стих ✨",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        softWrap = false,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Banner 1: St. Gregory of Narek Card (Opens Bible Reader on Narek tab)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onOpenNarek() },
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
            shape = RoundedCornerShape(24.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = Color(0xFFF59E0B).copy(alpha = 0.2f),
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.MenuBook, contentDescription = null, tint = Color(0xFFF59E0B), modifier = Modifier.size(24.dp))
                    }
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("Գրիգոր Նարեկացի 📜", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    Text(
                        text = "Մատեան Ողբերգութեան (Book of Lamentations)",
                        color = Color(0xFF94A3B8),
                        fontSize = 11.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF64748B))
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Banner 2: Bible Quiz Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onOpenQuiz() },
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
            shape = RoundedCornerShape(24.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = Color(0xFF10B981).copy(alpha = 0.2f),
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = Color(0xFF10B981), modifier = Modifier.size(24.dp))
                    }
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("Աստվածաշնչյան Վիկտորինա 🏆", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    Text("Ռեկորդ: ${prefs.quizBestScore} միավոր", color = Color(0xFF10B981), fontSize = 11.sp)
                }
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF64748B))
            }
        }

        Spacer(modifier = Modifier.height(28.dp))
    }
}

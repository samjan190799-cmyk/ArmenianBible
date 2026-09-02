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
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Spa
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
import com.example.armenianbible.widget.BibleAppWidget
import kotlinx.coroutines.launch

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
    onOpenNarek: () -> Unit,
    onOpenCalendar: () -> Unit,
    onOpenAIGuide: () -> Unit
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    var currentVerse by remember {
        mutableStateOf(dbHelper.getRandomVerse(armenianEdition) ?: BibleVerse(
            textHy = "ՉԷ՞ որ ես քեզ պատվիրեցի․ զորացի՛ր և քա՛ջ եղիր, մի՛ վախեցիր և մի՛ զարհուրիր, որովհետև քո Տեր Աստվածը քեզ հետ է ամեն տեղ, ուր էլ որ գնաս։",
            textRu = "Вот Я повелеваю тебе: будь тверд и мужествен, не страшись и не ужасайся; ибо с тобою Господь Бог твой везде, куда ни пойдешь.",
            textEn = "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee whithersoever thou goest.",
            refHy = "Հեսու 1:9",
            refRu = "Иисус Навин 1:9",
            refEn = "Joshua 1:9"
        ))
    }

    var isFav by remember(currentVerse) {
        mutableStateOf(prefs.isFavorite(currentVerse.refHy))
    }

    var isGeneratingAI by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

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
            .background(Color(0xFFF8FAFC))
            .padding(horizontal = 18.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(10.dp))

        // Top Row: Only Settings Icon at Top Right (matching iOS Screenshot 2)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onOpenSettings()
                },
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFF1F5F9))
                    .border(1.dp, Color(0xFFE2E8F0), CircleShape)
            ) {
                Icon(
                    Icons.Default.Settings,
                    contentDescription = "Settings",
                    tint = Color(0xFF475569),
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // MARK: - Main iOS White Glassmorphic Verse Card (matching Screenshot 2)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 2.dp, shape = RoundedCornerShape(24.dp), spotColor = Color(0x1A000000))
                .clip(RoundedCornerShape(24.dp))
                .border(
                    width = 1.dp,
                    color = Color(0xFFE2E8F0),
                    shape = RoundedCornerShape(24.dp)
                )
                .clickable {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    val newVerse = dbHelper.getRandomVerse()
                    if (newVerse != null) currentVerse = newVerse
                },
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Laurel / Branch Decorative Icon at Top
                Icon(
                    imageVector = Icons.Default.Spa,
                    contentDescription = null,
                    tint = secondaryAccentColor.copy(alpha = 0.8f),
                    modifier = Modifier.size(32.dp)
                )

                Spacer(modifier = Modifier.height(18.dp))

                // Animated Verse Text
                AnimatedContent(
                    targetState = currentVerse,
                    transitionSpec = {
                        fadeIn() + slideInVertically { it / 3 } togetherWith fadeOut() + slideOutVertically { -it / 3 }
                    },
                    label = "VerseAnim"
                ) { verse ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = verse.text(appLanguage),
                            style = MaterialTheme.typography.headlineSmall.copy(
                                color = Color(0xFF0F172A),
                                fontSize = 19.sp,
                                lineHeight = 28.sp,
                                textAlign = TextAlign.Center,
                                fontWeight = FontWeight.SemiBold,
                                fontFamily = FontFamily.Serif
                            ),
                            modifier = Modifier.padding(horizontal = 4.dp)
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = verse.reference(appLanguage),
                            style = MaterialTheme.typography.bodyLarge.copy(
                                color = secondaryAccentColor,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center,
                                fontSize = 14.sp
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(22.dp))

                // Action Buttons Row (Heart Favorite and Share in rounded circular pills)
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Like / Favorite
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
                                Toast.makeText(
                                    context,
                                    when(appLanguage) {
                                        AppLanguage.ARMENIAN -> "Հեռացված է ընտրյալներից"
                                        AppLanguage.RUSSIAN -> "Удалено из избранного"
                                        AppLanguage.ENGLISH -> "Removed from favorites"
                                    },
                                    Toast.LENGTH_SHORT
                                ).show()
                            } else {
                                prefs.addFavorite(item)
                                isFav = true
                                Toast.makeText(
                                    context,
                                    when(appLanguage) {
                                        AppLanguage.ARMENIAN -> "Ավելացված է ընտրյալներում ❤️"
                                        AppLanguage.RUSSIAN -> "Добавлено в избранное ❤️"
                                        AppLanguage.ENGLISH -> "Added to favorites ❤️"
                                    },
                // Verse Card Action Buttons (Refresh, Favorite, Share, AI Guide)
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // 1. Refresh (Random verse)
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            val newVerse = dbHelper.getRandomVerse(armenianEdition)
                            if (newVerse != null) currentVerse = newVerse
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF8FAFC))
                            .border(1.dp, Color(0xFFE2E8F0), CircleShape)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = "Random Verse",
                            tint = Color(0xFF64748B),
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    // 2. Favorite
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            val item = FavoriteItem(
                                verse = currentVerse,
                                addedDate = System.currentTimeMillis()
                            )
                            if (isFav) {
                                prefs.removeFavorite(item)
                                isFav = false
                                Toast.makeText(
                                    context,
                                    when(appLanguage) {
                                        AppLanguage.ARMENIAN -> "Հեռացված է ընտրյալներից"
                                        AppLanguage.RUSSIAN -> "Удалено из избранного"
                                        AppLanguage.ENGLISH -> "Removed from favorites"
                                    },
                                    Toast.LENGTH_SHORT
                                ).show()
                            } else {
                                prefs.addFavorite(item)
                                isFav = true
                                Toast.makeText(
                                    context,
                                    when(appLanguage) {
                                        AppLanguage.ARMENIAN -> "Ավելացված է ընտրյալներում ❤️"
                                        AppLanguage.RUSSIAN -> "Добавлено в избранное ❤️"
                                        AppLanguage.ENGLISH -> "Added to favorites ❤️"
                                    },
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF8FAFC))
                            .border(1.dp, Color(0xFFE2E8F0), CircleShape)
                    ) {
                        Icon(
                            imageVector = if (isFav) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Favorite",
                            tint = if (isFav) Color(0xFFEF4444) else Color(0xFF94A3B8),
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    // 3. Share (Image Card)
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            VerseCardExporter.shareVerseAsImage(
                                context = context,
                                verse = currentVerse,
                                appLanguage = appLanguage,
                                accentTheme = prefs.accentTheme
                            )
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF8FAFC))
                            .border(1.dp, Color(0xFFE2E8F0), CircleShape)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = "Share",
                            tint = Color(0xFF94A3B8),
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    // 4. AI Guide (Spiritual Reflection)
                    IconButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            onOpenAIGuide()
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFE0F2FE))
                            .border(1.dp, Color(0xFFBAE6FD), CircleShape)
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = "AI Guide",
                            tint = Color(0xFF0284C7),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // MARK: - Banner 1: St. Gregory of Narek Card (matching Screenshot 2)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 1.dp, shape = RoundedCornerShape(20.dp), spotColor = Color(0x10000000))
                .clip(RoundedCornerShape(20.dp))
                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
                .clickable {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onOpenNarek()
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
                    color = Color(0xFFE0F2FE),
                    modifier = Modifier.size(46.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Default.LocalFireDepartment,
                            contentDescription = null,
                            tint = Color(0xFF0284C7),
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = when(appLanguage) {
                            AppLanguage.ARMENIAN -> "Գրիգոր Նարեկացի"
                            AppLanguage.RUSSIAN -> "Григор Нарекаци"
                            AppLanguage.ENGLISH -> "St. Gregory of Narek"
                        },
                        color = Color(0xFF0F172A),
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        fontFamily = FontFamily.Serif
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = when(appLanguage) {
                            AppLanguage.ARMENIAN -> "Մատեան Ողբերգութեան (Book of Lamentations)"
                            AppLanguage.RUSSIAN -> "Книга скорбных песнопений (95 глав)"
                            AppLanguage.ENGLISH -> "Book of Lamentations (95 prayers)"
                        },
                        color = Color(0xFF64748B),
                        fontSize = 12.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = Color(0xFF94A3B8),
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // MARK: - Banner 2: Bible Quiz Card (matching Screenshot 2)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 1.dp, shape = RoundedCornerShape(20.dp), spotColor = Color(0x10000000))
                .clip(RoundedCornerShape(20.dp))
                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
                .clickable {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onOpenQuiz()
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
                    color = Color(0xFFD1FAE5),
                    modifier = Modifier.size(46.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Default.EmojiEvents,
                            contentDescription = null,
                            tint = Color(0xFF059669),
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = when(appLanguage) {
                            AppLanguage.ARMENIAN -> "Աստվածաշնչյան Վիկտորինա"
                            AppLanguage.RUSSIAN -> "Библейская Викторина"
                            AppLanguage.ENGLISH -> "Bible Quiz Challenge"
                        },
                        color = Color(0xFF0F172A),
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        fontFamily = FontFamily.Serif
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = when(appLanguage) {
                            AppLanguage.ARMENIAN -> "Ռեկորդ: ${prefs.quizBestScore} միավոր"
                            AppLanguage.RUSSIAN -> "Рекорд: ${prefs.quizBestScore} очков"
                            AppLanguage.ENGLISH -> "Best Score: ${prefs.quizBestScore} pts"
                        },
                        color = Color(0xFF64748B),
                        fontSize = 12.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = Color(0xFF94A3B8),
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // MARK: - Banner 3: Church Calendar & Feasts Card
        val todayFeast = remember { ChurchCalendarService.todayFeast() }
        val nextDaghavar = remember { ChurchCalendarService.nextDaghavarFeast() }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = 1.dp, shape = RoundedCornerShape(20.dp), spotColor = Color(0x10000000))
                .clip(RoundedCornerShape(20.dp))
                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
                .clickable {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onOpenCalendar()
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
                    modifier = Modifier.size(46.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = todayFeast?.type?.icon ?: "⛪",
                            fontSize = 22.sp
                        )
                    }
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    if (todayFeast != null) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = Color(0xFFEF4444),
                                modifier = Modifier.padding(end = 6.dp)
                            ) {
                                Text(
                                    text = when (appLanguage) {
                                        AppLanguage.ARMENIAN -> "ԱՅՍՕՐ"
                                        AppLanguage.RUSSIAN -> "СЕГОДНЯ"
                                        AppLanguage.ENGLISH -> "TODAY"
                                    },
                                    color = Color.White,
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                                )
                            }
                            Text(
                                text = todayFeast.title(appLanguage),
                                color = Color(0xFF0F172A),
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                fontFamily = FontFamily.Serif,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = todayFeast.formattedDate(appLanguage) + if (todayFeast.isFasting) " • 🕯️ " + when (appLanguage) {
                                AppLanguage.ARMENIAN -> "Պահք"
                                AppLanguage.RUSSIAN -> "Пост"
                                AppLanguage.ENGLISH -> "Fast"
                            } else "",
                            color = Color(0xFFD97706),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    } else if (nextDaghavar != null) {
                        Text(
                            text = when (appLanguage) {
                                AppLanguage.ARMENIAN -> "Եկեղեցական Տոնացույց"
                                AppLanguage.RUSSIAN -> "Церковный Календарь"
                                AppLanguage.ENGLISH -> "Church Calendar"
                            },
                            color = Color(0xFF0F172A),
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            fontFamily = FontFamily.Serif
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "${nextDaghavar.first.title(appLanguage)} • ${nextDaghavar.second} " + when (appLanguage) {
                                AppLanguage.ARMENIAN -> "օրից"
                                AppLanguage.RUSSIAN -> "дн."
                                AppLanguage.ENGLISH -> "days left"
                            },
                            color = Color(0xFFD97706),
                            fontSize = 12.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    } else {
                        Text(
                            text = when (appLanguage) {
                                AppLanguage.ARMENIAN -> "Եկեղեցական Տոնացույց"
                                AppLanguage.RUSSIAN -> "Церковный Календарь"
                                AppLanguage.ENGLISH -> "Church Calendar"
                            },
                            color = Color(0xFF0F172A),
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            fontFamily = FontFamily.Serif
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = when (appLanguage) {
                                AppLanguage.ARMENIAN -> "Հայ Առաքելական Եկեղեցու տոներ"
                                AppLanguage.RUSSIAN -> "Праздники и посты Армянской Церкви"
                                AppLanguage.ENGLISH -> "Armenian Apostolic Church Feasts"
                            },
                            color = Color(0xFF64748B),
                            fontSize = 12.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = Color(0xFF94A3B8),
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}

package com.example.armenianbible

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*
import com.example.armenianbible.ui.screens.*

class MainActivity : ComponentActivity() {

    private lateinit var dbHelper: BibleDatabaseHelper
    private lateinit var prefs: PreferencesManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        dbHelper = BibleDatabaseHelper.getInstance(this)
        prefs = PreferencesManager(this)

        // Schedule daily notifications & update widget
        com.example.armenianbible.receiver.DailyNotificationReceiver.scheduleDailyNotification(this)
        com.example.armenianbible.widget.BibleAppWidget.sendUpdateBroadcast(this)

        setContent {
            var currentLanguage by remember { mutableStateOf(prefs.appLanguage) }
            var currentEdition by remember { mutableStateOf(prefs.armenianEdition) }
            var activeAccentTheme by remember { mutableStateOf(prefs.accentTheme) }
            var selectedTabScreen by remember { mutableIntStateOf(0) }

            var isShowingSettings by remember { mutableStateOf(false) }
            var isShowingQuiz by remember { mutableStateOf(false) }

            var deepLinkBookId by remember { mutableStateOf<Int?>(null) }
            var deepLinkChapter by remember { mutableStateOf<Int?>(null) }
            var bibleSubTab by remember { mutableIntStateOf(0) }

            val primaryAccent = Color(android.graphics.Color.parseColor(activeAccentTheme.colorHex))
            val secondaryAccent = Color(android.graphics.Color.parseColor(activeAccentTheme.secondaryColorHex))

            // iOS-styled Light / Clean Theme Palette
            MaterialTheme(
                colorScheme = lightColorScheme(
                    background = Color(0xFFF8FAFC),
                    surface = Color.White,
                    primary = primaryAccent,
                    onPrimary = Color.White,
                    onBackground = Color(0xFF0F172A),
                    onSurface = Color(0xFF0F172A)
                )
            ) {
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    containerColor = Color(0xFFF8FAFC),
                    bottomBar = {
                        // Exact iOS Bottom Navigation Bar
                        NavigationBar(
                            containerColor = Color.White,
                            contentColor = Color(0xFF64748B),
                            tonalElevation = 6.dp,
                            windowInsets = WindowInsets.navigationBars,
                            modifier = Modifier
                                .border(width = 0.8.dp, color = Color(0xFFE2E8F0).copy(alpha = 0.8f))
                        ) {
                            // Exact Tab Order matching iOS Screenshot:
                            // 1. Գլխավոր (Home)
                            // 2. Ընտրյալներ (Favorites)
                            // 3. Օգնական (AI Assistant)
                            // 4. Աստվածաշունչ (Bible)
                            val items = listOf(
                                Triple(0, when(currentLanguage) { AppLanguage.ARMENIAN -> "Գլխավոր"; AppLanguage.RUSSIAN -> "Главная"; AppLanguage.ENGLISH -> "Home" }, Icons.Default.Home),
                                Triple(1, when(currentLanguage) { AppLanguage.ARMENIAN -> "Ընտրյալներ"; AppLanguage.RUSSIAN -> "Избранное"; AppLanguage.ENGLISH -> "Favorites" }, Icons.Default.Favorite),
                                Triple(2, when(currentLanguage) { AppLanguage.ARMENIAN -> "Օգնական"; AppLanguage.RUSSIAN -> "Помощник"; AppLanguage.ENGLISH -> "Assistant" }, Icons.Default.AutoAwesome),
                                Triple(3, when(currentLanguage) { AppLanguage.ARMENIAN -> "Աստվածաշունչ"; AppLanguage.RUSSIAN -> "Библия"; AppLanguage.ENGLISH -> "Bible" }, Icons.Default.MenuBook)
                            )

                            items.forEach { (idx, label, icon) ->
                                NavigationBarItem(
                                    selected = selectedTabScreen == idx,
                                    onClick = {
                                        selectedTabScreen = idx
                                        if (idx == 3) bibleSubTab = 0
                                    },
                                    icon = {
                                        Icon(
                                            icon,
                                            contentDescription = label,
                                            modifier = Modifier.size(24.dp)
                                        )
                                    },
                                    label = {
                                        Text(
                                            text = label,
                                            fontSize = 11.sp,
                                            fontWeight = if (selectedTabScreen == idx) FontWeight.Bold else FontWeight.Medium,
                                            maxLines = 1,
                                            softWrap = false,
                                            overflow = TextOverflow.Ellipsis
                                        )
                                    },
                                    alwaysShowLabel = true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = primaryAccent,
                                        selectedTextColor = primaryAccent,
                                        indicatorColor = primaryAccent.copy(alpha = 0.14f),
                                        unselectedIconColor = Color(0xFF64748B),
                                        unselectedTextColor = Color(0xFF64748B)
                                    )
                                )
                            }
                        }
                    }
                ) { innerPadding ->
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(innerPadding)
                    ) {
                        when (selectedTabScreen) {
                            0 -> HomeScreen(
                                dbHelper = dbHelper,
                                prefs = prefs,
                                appLanguage = currentLanguage,
                                onLanguageChange = { lang ->
                                    currentLanguage = lang
                                    prefs.appLanguage = lang
                                },
                                armenianEdition = currentEdition,
                                onEditionChange = { ed ->
                                    currentEdition = ed
                                    prefs.armenianEdition = ed
                                },
                                onOpenSettings = { isShowingSettings = true },
                                onOpenQuiz = { isShowingQuiz = true },
                                onOpenNarek = {
                                    bibleSubTab = 2
                                    selectedTabScreen = 3 // Switch to Bible screen with Narek tab
                                }
                            )
                            1 -> FavoritesScreen(
                                prefs = prefs,
                                appLanguage = currentLanguage
                            )
                            2 -> AIGuideScreen(
                                prefs = prefs,
                                appLanguage = currentLanguage
                            )
                            3 -> BibleReaderScreen(
                                dbHelper = dbHelper,
                                prefs = prefs,
                                appLanguage = currentLanguage,
                                armenianEdition = currentEdition,
                                initialBookId = deepLinkBookId,
                                initialChapter = deepLinkChapter,
                                initialSubTab = bibleSubTab
                            )
                        }

                        // Settings Sheet Modal
                        if (isShowingSettings) {
                            SettingsSheet(
                                prefs = prefs,
                                onDismiss = { isShowingSettings = false },
                                onSettingsChanged = {
                                    currentLanguage = prefs.appLanguage
                                    currentEdition = prefs.armenianEdition
                                    activeAccentTheme = prefs.accentTheme
                                }
                            )
                        }

                        // Quiz Fullscreen Modal
                        if (isShowingQuiz) {
                            QuizScreen(
                                prefs = prefs,
                                appLanguage = currentLanguage,
                                onDismiss = { isShowingQuiz = false }
                            )
                        }
                    }
                }
            }
        }
    }
}

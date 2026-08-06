package com.example.armenianbible

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
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

            MaterialTheme(
                colorScheme = darkColorScheme(
                    background = Color(0xFF0F172A),
                    surface = Color(0xFF1E293B),
                    primary = primaryAccent,
                    onPrimary = Color.White,
                    onBackground = Color.White,
                    onSurface = Color.White
                )
            ) {
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    containerColor = Color(0xFF0F172A),
                    bottomBar = {
                        NavigationBar(
                            containerColor = Color(0xFF1E293B),
                            contentColor = Color(0xFF94A3B8),
                            tonalElevation = 8.dp,
                            windowInsets = WindowInsets.navigationBars
                        ) {
                            val items = listOf(
                                Triple(0, when(currentLanguage) { AppLanguage.ARMENIAN -> "Գլխավոր"; AppLanguage.RUSSIAN -> "Главная"; AppLanguage.ENGLISH -> "Home" }, Icons.Default.Home),
                                Triple(1, when(currentLanguage) { AppLanguage.ARMENIAN -> "Աստվածաշունչ"; AppLanguage.RUSSIAN -> "Библия"; AppLanguage.ENGLISH -> "Bible" }, Icons.Default.MenuBook),
                                Triple(2, when(currentLanguage) { AppLanguage.ARMENIAN -> "ИИ Ուղեցույց"; AppLanguage.RUSSIAN -> "ИИ ГИД"; AppLanguage.ENGLISH -> "AI Guide" }, Icons.Default.AutoAwesome),
                                Triple(3, when(currentLanguage) { AppLanguage.ARMENIAN -> "Էջանշաններ"; AppLanguage.RUSSIAN -> "Избранное"; AppLanguage.ENGLISH -> "Favorites" }, Icons.Default.Favorite)
                            )

                            items.forEach { (idx, label, icon) ->
                                NavigationBarItem(
                                    selected = selectedTabScreen == idx,
                                    onClick = {
                                        selectedTabScreen = idx
                                        if (idx == 1) bibleSubTab = 0
                                    },
                                    icon = { Icon(icon, contentDescription = label, modifier = Modifier.size(22.dp)) },
                                    label = {
                                        Text(
                                            text = label,
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Medium,
                                            maxLines = 1,
                                            softWrap = false,
                                            overflow = TextOverflow.Ellipsis
                                        )
                                    },
                                    alwaysShowLabel = true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = primaryAccent,
                                        selectedTextColor = primaryAccent,
                                        indicatorColor = primaryAccent.copy(alpha = 0.25f),
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
                                    selectedTabScreen = 1
                                }
                            )
                            1 -> BibleReaderScreen(
                                dbHelper = dbHelper,
                                prefs = prefs,
                                appLanguage = currentLanguage,
                                armenianEdition = currentEdition,
                                initialBookId = deepLinkBookId,
                                initialChapter = deepLinkChapter,
                                initialSubTab = bibleSubTab
                            )
                            2 -> AIGuideScreen(
                                prefs = prefs,
                                appLanguage = currentLanguage
                            )
                            3 -> FavoritesScreen(
                                prefs = prefs,
                                appLanguage = currentLanguage
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

                        // Quiz Modal
                        if (isShowingQuiz) {
                            Surface(
                                modifier = Modifier.fillMaxSize(),
                                color = Color(0xFF0F172A)
                            ) {
                                Column {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp),
                                        horizontalArrangement = Arrangement.End
                                    ) {
                                        IconButton(onClick = { isShowingQuiz = false }) {
                                            Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                                        }
                                    }
                                    QuizScreen(prefs = prefs, appLanguage = currentLanguage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

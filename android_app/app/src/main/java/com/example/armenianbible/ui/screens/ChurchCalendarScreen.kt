package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.example.armenianbible.data.*
import java.util.Calendar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChurchCalendarScreen(
    appLanguage: AppLanguage,
    accentTheme: AccentColorTheme,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    var selectedYear by remember { mutableStateOf(Calendar.getInstance().get(Calendar.YEAR)) }
    var selectedCategory by remember { mutableStateOf<FeastType?>(null) }
    var expandedFeastId by remember { mutableStateOf<String?>(null) }
    var yearMenuExpanded by remember { mutableStateOf(false) }

    val accentColor = Color(android.graphics.Color.parseColor(accentTheme.colorHex))
    val secondaryAccentColor = Color(android.graphics.Color.parseColor(accentTheme.secondaryColorHex))

    val allFeasts = remember(selectedYear) {
        ChurchCalendarService.feasts(selectedYear)
    }

    val filteredFeasts = remember(allFeasts, selectedCategory) {
        if (selectedCategory == null) allFeasts else allFeasts.filter { it.type == selectedCategory }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (appLanguage) {
                            AppLanguage.ARMENIAN -> "Եկեղեցական Տոնացույց"
                            AppLanguage.RUSSIAN -> "Церковный Календарь"
                            AppLanguage.ENGLISH -> "Church Calendar"
                        },
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                },
                navigationIcon = {
                    IconButton(onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        onBack()
                    }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFFF8FAFC)
                )
            )
        },
        containerColor = Color(0xFFF8FAFC)
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // MARK: - Header: Year selector + Export Full Calendar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Year Dropdown
                Box {
                    OutlinedButton(
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            yearMenuExpanded = true
                        },
                        shape = RoundedCornerShape(12.dp),
                        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = "$selectedYear",
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, modifier = Modifier.size(18.dp))
                    }

                    DropdownMenu(
                        expanded = yearMenuExpanded,
                        onDismissRequest = { yearMenuExpanded = false }
                    ) {
                        (2025..2030).forEach { year ->
                            DropdownMenuItem(
                                text = { Text("$year", fontWeight = if (year == selectedYear) FontWeight.Bold else FontWeight.Normal) },
                                onClick = {
                                    selectedYear = year
                                    yearMenuExpanded = false
                                }
                            )
                        }
                    }
                }

                // Export Full Calendar (.ics)
                Button(
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        val file = ChurchCalendarService.generateICSFile(context, selectedYear, appLanguage)
                        if (file != null) {
                            try {
                                val uri: Uri = FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.fileprovider",
                                    file
                                )
                                val sendIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/calendar"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    putExtra(Intent.EXTRA_SUBJECT, "Armenian Church Calendar $selectedYear")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(Intent.createChooser(sendIntent, "Export Calendar"))
                            } catch (e: Exception) {
                                Toast.makeText(context, "Error sharing calendar file", Toast.LENGTH_SHORT).show()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFF59E0B)
                    ),
                    shape = RoundedCornerShape(12.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Icon(Icons.Default.CalendarMonth, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = when (appLanguage) {
                            AppLanguage.ARMENIAN -> "Ներբեռնել օրացույց"
                            AppLanguage.RUSSIAN -> "В календарь"
                            AppLanguage.ENGLISH -> "Export .ics"
                        },
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            // MARK: - Category Filter Chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 18.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // "All" chip
                FilterChip(
                    selected = selectedCategory == null,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        selectedCategory = null
                    },
                    label = {
                        Text(
                            text = when (appLanguage) {
                                AppLanguage.ARMENIAN -> "Բոլորը"
                                AppLanguage.RUSSIAN -> "Все"
                                AppLanguage.ENGLISH -> "All"
                            },
                            fontWeight = if (selectedCategory == null) FontWeight.Bold else FontWeight.Normal
                        )
                    },
                    shape = RoundedCornerShape(16.dp)
                )

                FeastType.values().forEach { cat ->
                    val isSel = selectedCategory == cat
                    val catColor = Color(android.graphics.Color.parseColor(cat.colorHex))
                    FilterChip(
                        selected = isSel,
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            selectedCategory = if (isSel) null else cat
                        },
                        label = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(cat.icon, fontSize = 12.sp)
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = cat.localizedTitle(appLanguage),
                                    fontWeight = if (isSel) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        },
                        shape = RoundedCornerShape(16.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // MARK: - Feasts List
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 18.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                contentPadding = PaddingValues(bottom = 30.dp)
            ) {
                items(filteredFeasts, key = { it.id }) { feast ->
                    val isExpanded = expandedFeastId == feast.id
                    val feastColor = Color(android.graphics.Color.parseColor(feast.type.colorHex))

                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(elevation = 1.dp, shape = RoundedCornerShape(20.dp), spotColor = Color(0x10000000))
                            .clip(RoundedCornerShape(20.dp))
                            .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp)),
                        colors = CardDefaults.cardColors(containerColor = Color.White)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                        ) {
                            // Top Row: Category badge + Date
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = feastColor.copy(alpha = 0.15f),
                                    modifier = Modifier.padding(bottom = 4.dp)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(feast.type.icon, fontSize = 12.sp)
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = feast.type.localizedTitle(appLanguage),
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = feastColor
                                        )
                                    }
                                }

                                Text(
                                    text = feast.formattedDate(appLanguage),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = secondaryAccentColor
                                )
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            // Feast Title
                            Text(
                                text = feast.title(appLanguage),
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF0F172A),
                                fontFamily = FontFamily.Serif
                            )

                            Spacer(modifier = Modifier.height(6.dp))

                            // Feast Description
                            Text(
                                text = feast.description(appLanguage),
                                fontSize = 13.sp,
                                color = Color(0xFF334155),
                                lineHeight = 19.sp,
                                maxLines = if (isExpanded) Int.MAX_VALUE else 3,
                                overflow = TextOverflow.Ellipsis
                            )

                            // Expanded Section (Readings + Prayer)
                            AnimatedVisibility(visible = isExpanded) {
                                Column(modifier = Modifier.padding(top = 10.dp)) {
                                    if (feast.scriptureReading.isNotEmpty()) {
                                        Surface(
                                            shape = RoundedCornerShape(10.dp),
                                            color = Color(0xFFE0F2FE),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Row(
                                                modifier = Modifier.padding(10.dp),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Icon(
                                                    Icons.Default.MenuBook,
                                                    contentDescription = null,
                                                    tint = Color(0xFF0284C7),
                                                    modifier = Modifier.size(16.dp)
                                                )
                                                Spacer(modifier = Modifier.width(8.dp))
                                                Text(
                                                    text = feast.scriptureReading,
                                                    fontSize = 12.sp,
                                                    fontWeight = FontWeight.SemiBold,
                                                    color = Color(0xFF0F172A)
                                                )
                                            }
                                        }
                                        Spacer(modifier = Modifier.height(8.dp))
                                    }

                                    if (feast.prayer(appLanguage).isNotEmpty()) {
                                        Surface(
                                            shape = RoundedCornerShape(10.dp),
                                            color = Color(0xFFFEF3C7),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Column(modifier = Modifier.padding(12.dp)) {
                                                Text(
                                                    text = "🙏 " + when (appLanguage) {
                                                        AppLanguage.ARMENIAN -> "Տոնական աղոթք"
                                                        AppLanguage.RUSSIAN -> "Праздничная молитва"
                                                        AppLanguage.ENGLISH -> "Feast Prayer"
                                                    },
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = Color(0xFFD97706)
                                                )
                                                Spacer(modifier = Modifier.height(4.dp))
                                                Text(
                                                    text = feast.prayer(appLanguage),
                                                    fontSize = 13.sp,
                                                    color = Color(0xFF78350F),
                                                    fontFamily = FontFamily.Serif
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            // Bottom Actions Row
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                TextButton(
                                    onClick = {
                                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                        expandedFeastId = if (isExpanded) null else feast.id
                                    },
                                    contentPadding = PaddingValues(0.dp)
                                ) {
                                    Text(
                                        text = if (isExpanded) {
                                            when (appLanguage) {
                                                AppLanguage.ARMENIAN -> "Փակել"
                                                AppLanguage.RUSSIAN -> "Скрыть"
                                                AppLanguage.ENGLISH -> "Hide"
                                            }
                                        } else {
                                            when (appLanguage) {
                                                AppLanguage.ARMENIAN -> "Մանրամասն"
                                                AppLanguage.RUSSIAN -> "Подробнее"
                                                AppLanguage.ENGLISH -> "More details"
                                            }
                                        },
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = secondaryAccentColor
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Icon(
                                        if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                                        contentDescription = null,
                                        tint = secondaryAccentColor,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }

                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    // Add single feast to Google Calendar
                                    IconButton(
                                        onClick = {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            ChurchCalendarService.insertFeastToSystemCalendar(context, feast, appLanguage)
                                        },
                                        modifier = Modifier
                                            .size(34.dp)
                                            .clip(CircleShape)
                                            .background(Color(0xFFFEF3C7))
                                    ) {
                                        Icon(
                                            Icons.Default.Event,
                                            contentDescription = "Add to Calendar",
                                            tint = Color(0xFFD97706),
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }

                                    // Copy
                                    IconButton(
                                        onClick = {
                                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            val text = "✨ ${feast.title(appLanguage)}\n📅 ${feast.formattedDate(appLanguage)}\n\n${feast.description(appLanguage)}\n\n${feast.prayer(appLanguage)}"
                                            clipboard.setPrimaryClip(ClipData.newPlainText("Feast", text))
                                            Toast.makeText(
                                                context,
                                                when (appLanguage) {
                                                    AppLanguage.ARMENIAN -> "Պատճենված է"
                                                    AppLanguage.RUSSIAN -> "Скопировано"
                                                    AppLanguage.ENGLISH -> "Copied"
                                                },
                                                Toast.LENGTH_SHORT
                                            ).show()
                                        },
                                        modifier = Modifier
                                            .size(34.dp)
                                            .clip(CircleShape)
                                            .background(Color(0xFFF1F5F9))
                                    ) {
                                        Icon(
                                            Icons.Default.ContentCopy,
                                            contentDescription = "Copy",
                                            tint = Color(0xFF64748B),
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

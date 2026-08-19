package com.example.armenianbible.ui.screens

import android.app.TimePickerDialog
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*
import com.example.armenianbible.receiver.DailyNotificationReceiver
import com.example.armenianbible.widget.BibleAppWidget

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    prefs: PreferencesManager,
    onDismiss: () -> Unit,
    onSettingsChanged: () -> Unit
) {
    val context = LocalContext.current

    var selectedProvider by remember { mutableStateOf(prefs.activeProvider) }
    var geminiKey by remember { mutableStateOf(prefs.geminiApiKey) }
    var openaiKey by remember { mutableStateOf(prefs.openaiApiKey) }
    var claudeKey by remember { mutableStateOf(prefs.anthropicApiKey) }

    var selectedLanguage by remember { mutableStateOf(prefs.appLanguage) }
    var selectedEdition by remember { mutableStateOf(prefs.armenianEdition) }
    var selectedTheme by remember { mutableStateOf(prefs.accentTheme) }

    var dailyNotifEnabled by remember { mutableStateOf(prefs.dailyNotificationsEnabled) }
    var notifHour by remember { mutableIntStateOf(prefs.dailyNotificationHour) }
    var notifMinute by remember { mutableIntStateOf(prefs.dailyNotificationMinute) }

    var selectedCategory by remember { mutableStateOf(prefs.selectedCategory) }
    var selectedInterval by remember { mutableStateOf(prefs.updateInterval) }
    var selectedWidgetLang by remember { mutableStateOf(prefs.widgetLanguage) }

    var showWidgetInstructionDialog by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC)),
        color = Color(0xFFF8FAFC)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = Color(0xFFE0F2FE),
                        modifier = Modifier.size(40.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Settings, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(22.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = when(selectedLanguage) {
                            AppLanguage.ARMENIAN -> "Կարգավորումներ"
                            AppLanguage.RUSSIAN -> "Настройки"
                            AppLanguage.ENGLISH -> "Settings"
                        },
                        style = MaterialTheme.typography.titleLarge.copy(color = Color(0xFF0F172A), fontWeight = FontWeight.Bold, fontSize = 22.sp)
                    )
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFF1F5F9))
                ) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color(0xFF475569), modifier = Modifier.size(18.dp))
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 1: AI Provider & API Keys
            Text(
                text = "🤖 ИИ Провайдер и Ключи API",
                color = Color(0xFF0284C7),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text("Выберите модель ИИ:", color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))

                    AIProvider.entries.forEach { provider ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedProvider = provider }
                                .padding(vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedProvider == provider,
                                onClick = { selectedProvider = provider },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(provider.displayName, color = Color(0xFF1E293B), fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    val currentKeyLabel = when(selectedProvider) {
                        AIProvider.GEMINI -> "Gemini API Key"
                        AIProvider.CHATGPT -> "OpenAI API Key"
                        AIProvider.CLAUDE -> "Anthropic Claude API Key"
                    }
                    val currentKeyValue = when(selectedProvider) {
                        AIProvider.GEMINI -> geminiKey
                        AIProvider.CHATGPT -> openaiKey
                        AIProvider.CLAUDE -> claudeKey
                    }

                    OutlinedTextField(
                        value = currentKeyValue,
                        onValueChange = { newVal ->
                            when(selectedProvider) {
                                AIProvider.GEMINI -> geminiKey = newVal
                                AIProvider.CHATGPT -> openaiKey = newVal
                                AIProvider.CLAUDE -> claudeKey = newVal
                            }
                        },
                        label = { Text(currentKeyLabel, color = Color(0xFF64748B)) },
                        leadingIcon = { Icon(Icons.Default.Key, contentDescription = null, tint = Color(0xFFF59E0B)) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color(0xFF0EA5E9),
                            unfocusedBorderColor = Color(0xFFE2E8F0),
                            focusedContainerColor = Color(0xFFF8FAFC),
                            unfocusedContainerColor = Color(0xFFF8FAFC),
                            focusedTextColor = Color(0xFF0F172A),
                            unfocusedTextColor = Color(0xFF0F172A)
                        ),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 2: Daily Notifications (Ежедневные уведомления)
            Text(
                text = "🔔 Ежедневный Стих Дня (Уведомления)",
                color = Color(0xFF0284C7),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = when(selectedLanguage) {
                                    AppLanguage.ARMENIAN -> "Օրվա համարի ծանուցում"
                                    AppLanguage.RUSSIAN -> "Включить уведомления"
                                    AppLanguage.ENGLISH -> "Daily Verse Notification"
                                },
                                color = Color(0xFF0F172A),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = when(selectedLanguage) {
                                    AppLanguage.ARMENIAN -> "Ամեն օր ոգեշնչող համար առավոտյան"
                                    AppLanguage.RUSSIAN -> "Вдохновляющий стих каждое утро"
                                    AppLanguage.ENGLISH -> "Inspirational verse every morning"
                                },
                                color = Color(0xFF64748B),
                                fontSize = 12.sp
                            )
                        }
                        Switch(
                            checked = dailyNotifEnabled,
                            onCheckedChange = { dailyNotifEnabled = it },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = Color(0xFF0EA5E9)
                            )
                        )
                    }

                    if (dailyNotifEnabled) {
                        Spacer(modifier = Modifier.height(14.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFFF1F5F9))
                                .clickable {
                                    val dialog = TimePickerDialog(
                                        context,
                                        { _, h, m ->
                                            notifHour = h
                                            notifMinute = m
                                        },
                                        notifHour,
                                        notifMinute,
                                        true
                                    )
                                    dialog.show()
                                }
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.AccessTime, contentDescription = null, tint = Color(0xFF0EA5E9))
                                Spacer(modifier = Modifier.width(10.dp))
                                Text("Время напоминания:", color = Color(0xFF0F172A), fontSize = 14.sp)
                            }
                            Text(
                                text = String.format("%02d:%02d", notifHour, notifMinute),
                                color = Color(0xFF0EA5E9),
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 3: Widget Configuration & Instruction (Настройки виджета)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "📱 Виджет рабочего стола",
                    color = Color(0xFF0284C7),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )

                TextButton(
                    onClick = { showWidgetInstructionDialog = true }
                ) {
                    Icon(Icons.Default.HelpOutline, contentDescription = null, tint = Color(0xFF0EA5E9), modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Инструкция", color = Color(0xFF0EA5E9), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(modifier = Modifier.height(6.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    // Update Interval
                    Text("Частота смены стихов в виджете:", color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    UpdateInterval.entries.forEach { interval ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedInterval = interval }
                                .padding(vertical = 5.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedInterval == interval,
                                onClick = { selectedInterval = interval },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(interval.localizedTitle(selectedLanguage), color = Color(0xFF1E293B), fontSize = 13.sp)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Content Type Category
                    Text("Тип контента для виджета:", color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    TextCategory.entries.forEach { cat ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedCategory = cat }
                                .padding(vertical = 5.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedCategory == cat,
                                onClick = { selectedCategory = cat },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(cat.localizedTitle(selectedLanguage), color = Color(0xFF1E293B), fontSize = 13.sp)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // Widget Language
                    Text("Язык виджета:", color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(6.dp))
                    WidgetLanguage.entries.forEach { wLang ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedWidgetLang = wLang }
                                .padding(vertical = 5.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedWidgetLang == wLang,
                                onClick = { selectedWidgetLang = wLang },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(wLang.localizedTitle(selectedLanguage), color = Color(0xFF1E293B), fontSize = 13.sp)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 4: Armenian Edition
            Text(
                text = "📖 Армянская редакция Библии",
                color = Color(0xFF0284C7),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    ArmenianEdition.entries.forEach { edition ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedEdition = edition }
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedEdition == edition,
                                onClick = { selectedEdition = edition },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(edition.displayName, color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 5: Accent Theme
            Text(
                text = "🎨 Цветовая тема оформления",
                color = Color(0xFF0284C7),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    AccentColorTheme.entries.forEach { theme ->
                        val themeColor = Color(android.graphics.Color.parseColor(theme.colorHex))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedTheme = theme }
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedTheme == theme,
                                onClick = { selectedTheme = theme },
                                colors = RadioButtonDefaults.colors(selectedColor = themeColor)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .size(20.dp)
                                    .clip(CircleShape)
                                    .background(themeColor)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(theme.displayName, color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 6: Language
            Text(
                text = "🌐 Язык интерфейса",
                color = Color(0xFF0284C7),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    AppLanguage.entries.forEach { lang ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedLanguage = lang }
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedLanguage == lang,
                                onClick = { selectedLanguage = lang },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF0EA5E9))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(lang.displayName, color = Color(0xFF0F172A), fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 7: About App
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(1.dp, RoundedCornerShape(18.dp))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(18.dp)),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(18.dp)) {
                    Text("✝️ О приложении", color = Color(0xFF0F172A), fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Версия", color = Color(0xFF64748B), fontSize = 13.sp)
                        Text("1.2.0 (Release)", color = Color(0xFF0EA5E9), fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Разработчик", color = Color(0xFF64748B), fontSize = 13.sp)
                        Text("Samvel", color = Color(0xFF0F172A), fontWeight = FontWeight.Medium, fontSize = 13.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Save Button
            Button(
                onClick = {
                    prefs.activeProvider = selectedProvider
                    prefs.geminiApiKey = geminiKey
                    prefs.openaiApiKey = openaiKey
                    prefs.anthropicApiKey = claudeKey

                    prefs.appLanguage = selectedLanguage
                    prefs.armenianEdition = selectedEdition
                    prefs.accentTheme = selectedTheme

                    prefs.dailyNotificationsEnabled = dailyNotifEnabled
                    prefs.dailyNotificationHour = notifHour
                    prefs.dailyNotificationMinute = notifMinute

                    prefs.selectedCategory = selectedCategory
                    prefs.updateInterval = selectedInterval
                    prefs.widgetLanguage = selectedWidgetLang

                    // Schedule or cancel notification
                    DailyNotificationReceiver.scheduleDailyNotification(context)

                    // Update widget
                    BibleAppWidget.sendUpdateBroadcast(context)

                    onSettingsChanged()
                    Toast.makeText(context, "Настройки успешно сохранены! ✅", Toast.LENGTH_SHORT).show()
                    onDismiss()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9))
            ) {
                Text(
                    text = when(selectedLanguage) {
                        AppLanguage.ARMENIAN -> "Պահպանել կարգավորումները"
                        AppLanguage.RUSSIAN -> "Сохранить настройки"
                        AppLanguage.ENGLISH -> "Save Changes"
                    },
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(30.dp))
        }

        // Widget Instruction Dialog
        if (showWidgetInstructionDialog) {
            AlertDialog(
                onDismissRequest = { showWidgetInstructionDialog = false },
                title = {
                    Text("📱 Как добавить виджет на экран", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Color(0xFF0F172A))
                },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("1. Зажмите пальцем свободное место на главном экране вашего телефона.", color = Color(0xFF334155), fontSize = 14.sp)
                        Text("2. В появившемся меню выберите «Виджеты» (Widgets).", color = Color(0xFF334155), fontSize = 14.sp)
                        Text("3. Найдите в списке «Armenian Bible» (Աստվածաշունչ).", color = Color(0xFF334155), fontSize = 14.sp)
                        Text("4. Перетащите виджет на рабочий стол и настройте его размер.", color = Color(0xFF334155), fontSize = 14.sp)
                        Text("💡 На самом виджете можно нажимать кнопки «🔄 Новый стих» и «❤️ В избранное» прямо с рабочего стола!", color = Color(0xFF0284C7), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    }
                },
                confirmButton = {
                    Button(
                        onClick = { showWidgetInstructionDialog = false },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9))
                    ) {
                        Text("Понятно", color = Color.White, fontWeight = FontWeight.Bold)
                    }
                },
                containerColor = Color.White,
                shape = RoundedCornerShape(20.dp)
            )
        }
    }
}

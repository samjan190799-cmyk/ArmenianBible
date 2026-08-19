package com.example.armenianbible.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Settings
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
    var selectedCategory by remember { mutableStateOf(prefs.selectedCategory) }
    var selectedInterval by remember { mutableStateOf(prefs.updateInterval) }
    var selectedTheme by remember { mutableStateOf(prefs.accentTheme) }

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
                        modifier = Modifier.size(38.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Settings, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(10.dp))
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

                    Spacer(modifier = Modifier.height(12.dp))

                    // API Key Input for selected provider
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

            // SECTION 2: Accent Theme
            Text(
                text = "🎨 Цветовая тема (Акцент)",
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

            // SECTION 3: Language
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

            Spacer(modifier = Modifier.height(24.dp))

            // Save Button
            Button(
                onClick = {
                    prefs.activeProvider = selectedProvider
                    prefs.geminiApiKey = geminiKey
                    prefs.openaiApiKey = openaiKey
                    prefs.anthropicApiKey = claudeKey
                    prefs.appLanguage = selectedLanguage
                    prefs.selectedCategory = selectedCategory
                    prefs.updateInterval = selectedInterval
                    prefs.accentTheme = selectedTheme

                    onSettingsChanged()
                    Toast.makeText(context, "Настройки сохранены! ✅", Toast.LENGTH_SHORT).show()
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
                        AppLanguage.ARMENIAN -> "Պահպանել"
                        AppLanguage.RUSSIAN -> "Сохранить"
                        AppLanguage.ENGLISH -> "Save Changes"
                    },
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(30.dp))
        }
    }
}

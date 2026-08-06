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
            .background(Color(0xFF0F172A)),
        color = Color(0xFF0F172A)
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
                    Icon(Icons.Default.Settings, contentDescription = null, tint = Color(0xFF6366F1))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = when(selectedLanguage) {
                            AppLanguage.ARMENIAN -> "Կարգավորումներ"
                            AppLanguage.RUSSIAN -> "Настройки"
                            AppLanguage.ENGLISH -> "Settings"
                        },
                        style = MaterialTheme.typography.titleLarge.copy(color = Color.White, fontWeight = FontWeight.Bold)
                    )
                }

                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 1: AI Provider & API Keys
            Text(
                text = "🤖 ИИ Провайдер и Ключи API",
                color = Color(0xFF818CF8),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Выберите модели ИИ:", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Medium)
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
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF6366F1))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(provider.displayName, color = Color.White, fontSize = 14.sp)
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
                        label = { Text(currentKeyLabel, color = Color(0xFF94A3B8)) },
                        leadingIcon = { Icon(Icons.Default.Key, contentDescription = null, tint = Color(0xFFF59E0B)) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color(0xFF6366F1),
                            unfocusedBorderColor = Color(0xFF334155),
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White
                        ),
                        shape = RoundedCornerShape(12.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 2: Accent Theme Picker
            Text(
                text = "🎨 Цветовая Тема (Accent Theme)",
                color = Color(0xFF818CF8),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        AccentColorTheme.entries.forEach { theme ->
                            val color = Color(android.graphics.Color.parseColor(theme.colorHex))
                            val isSelected = selectedTheme == theme

                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(color)
                                    .border(
                                        width = if (isSelected) 3.dp else 0.dp,
                                        color = Color.White,
                                        shape = CircleShape
                                    )
                                    .clickable { selectedTheme = theme }
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // SECTION 3: App Language
            Text(
                text = "🌐 Язык интерфейса / Լեզու",
                color = Color(0xFF818CF8),
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    AppLanguage.entries.forEach { lang ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { selectedLanguage = lang }
                                .padding(vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedLanguage == lang,
                                onClick = { selectedLanguage = lang },
                                colors = RadioButtonDefaults.colors(selectedColor = Color(0xFF6366F1))
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(lang.displayName, color = Color.White, fontSize = 14.sp)
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
                    Toast.makeText(context, "Настройки сохранены!", Toast.LENGTH_SHORT).show()
                    onDismiss()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6366F1))
            ) {
                Text("Պահպանել (Сохранить)", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

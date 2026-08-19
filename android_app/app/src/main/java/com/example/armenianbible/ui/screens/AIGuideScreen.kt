package com.example.armenianbible.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Send
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
import kotlinx.coroutines.launch

@Composable
fun AIGuideScreen(
    prefs: PreferencesManager,
    appLanguage: AppLanguage
) {
    var messages by remember {
        mutableStateOf(
            listOf(
                ChatMessage(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Ողջույն: Ես ձեր Հոգևոր ИИ Ուղեցույցն եմ (${prefs.activeProvider.displayName}): Ինչպե՞ս կարող եմ օգնել ձեզ այսօր Աստվածաշնչի կամ աղոթքների հարցում:"
                        AppLanguage.RUSSIAN -> "Приветствую! Я ваш Духовный ИИ-Наставник (${prefs.activeProvider.displayName}). Чем могу помочь вам сегодня в изучении Писания или молитве?"
                        AppLanguage.ENGLISH -> "Greetings! I am your Spiritual AI Guide (${prefs.activeProvider.displayName}). How can I assist you with Scripture or prayer today?"
                    },
                    isUser = false
                )
            )
        )
    }

    var inputText by remember { mutableStateOf("") }
    var isThinking by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    val promptSuggestions = listOf(
        when(appLanguage) { AppLanguage.ARMENIAN -> "Բացատրիր Սաղմոս 23-ը"; AppLanguage.RUSSIAN -> "Объясни Псалом 22"; AppLanguage.ENGLISH -> "Explain Psalm 23" },
        when(appLanguage) { AppLanguage.ARMENIAN -> "Աղոթք խաղաղության համար"; AppLanguage.RUSSIAN -> "Молитва о мире"; AppLanguage.ENGLISH -> "Prayer for peace" },
        when(appLanguage) { AppLanguage.ARMENIAN -> "Ինչ է սերը ըստ Պողոսի"; AppLanguage.RUSSIAN -> "Что есть любовь по Павлу"; AppLanguage.ENGLISH -> "Love according to Paul" }
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F172A))
            .padding(16.dp)
    ) {
        // Top Bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color(0xFFA855F7), modifier = Modifier.size(28.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Column {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "ИИ Հոգևոր Ուղեցույց"
                        AppLanguage.RUSSIAN -> "Духовный ИИ-Наставник"
                        AppLanguage.ENGLISH -> "Spiritual AI Guide"
                    },
                    style = MaterialTheme.typography.titleLarge.copy(color = Color.White, fontWeight = FontWeight.Bold)
                )
                Text(
                    text = prefs.activeProvider.displayName,
                    color = Color(0xFFA855F7),
                    fontSize = 11.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Chat Messages
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(messages) { msg ->
                val bubbleBg = if (msg.isUser) Color(0xFF6366F1) else Color(0xFF1E293B)
                val align = if (msg.isUser) Alignment.End else Alignment.Start

                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = align
                ) {
                    Surface(
                        color = bubbleBg,
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.widthIn(max = 280.dp)
                    ) {
                        Text(
                            text = msg.text,
                            color = Color.White,
                            fontSize = 14.sp,
                            lineHeight = 20.sp,
                            modifier = Modifier.padding(12.dp)
                        )
                    }
                }
            }

            if (isThinking) {
                item {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), color = Color(0xFFA855F7))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("ИИ думает...", color = Color(0xFF94A3B8), fontSize = 12.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Prompt Suggestions Chips
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            promptSuggestions.forEach { suggestion ->
                SuggestionChip(
                    onClick = { inputText = suggestion },
                    label = { Text(suggestion, fontSize = 11.sp, color = Color(0xFFC084FC)) },
                    colors = SuggestionChipDefaults.suggestionChipColors(containerColor = Color(0xFF1E293B))
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Input Field
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = { inputText = it },
                placeholder = {
                    Text(
                        text = when(appLanguage) {
                            AppLanguage.ARMENIAN -> "Հարցրեք ИИ-ին..."
                            AppLanguage.RUSSIAN -> "Спросите у ИИ..."
                            AppLanguage.ENGLISH -> "Ask spiritual AI..."
                        },
                        color = Color(0xFF64748B)
                    )
                },
                modifier = Modifier.weight(1f),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = Color(0xFFA855F7),
                    unfocusedBorderColor = Color(0xFF334155),
                    focusedContainerColor = Color(0xFF1E293B),
                    unfocusedContainerColor = Color(0xFF1E293B),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                ),
                shape = RoundedCornerShape(16.dp)
            )

            Spacer(modifier = Modifier.width(8.dp))

            IconButton(
                onClick = {
                    if (inputText.trim().isNotEmpty() && !isThinking) {
                        val userMsgText = inputText.trim()
                        inputText = ""
                        messages = messages + ChatMessage(text = userMsgText, isUser = true)
                        isThinking = true

                        val key = when(prefs.activeProvider) {
                            AIProvider.GEMINI -> prefs.geminiApiKey
                            AIProvider.CHATGPT -> prefs.openaiApiKey
                            AIProvider.CLAUDE -> prefs.anthropicApiKey
                        }

                        scope.launch {
                            if (key.trim().isNotEmpty()) {
                                val result = AIService.chatGuide(
                                    provider = prefs.activeProvider,
                                    apiKey = key,
                                    userQuestion = userMsgText,
                                    appLanguage = appLanguage
                                )
                                isThinking = false
                                result.onSuccess { reply ->
                                    messages = messages + ChatMessage(text = reply, isUser = false)
                                }.onFailure { err ->
                                    val fallbackReply = when(appLanguage) {
                                        AppLanguage.ARMENIAN -> "«$userMsgText» — Աստծո Խոսքը ասում է. «Քո խօսքը ճրագ է իմ ոտքերի համար» (Սաղմոս 118:105): Հավատքը և հույսը միշտ լուսավորում են մեր ճանապարհը: (Ցանցային սխալ՝ ${err.localizedMessage ?: "Offline"})"
                                        AppLanguage.RUSSIAN -> "На ваш вопрос «$userMsgText»: Слово Божие напоминает: «Слово Твое — светильник ноге моей» (Пс. 118:105). Вера и надежда преображают сердце."
                                        AppLanguage.ENGLISH -> "Regarding «$userMsgText»: The Scripture reminds us: 'Your word is a lamp to my feet' (Psalm 119:105). Faith brings true peace."
                                    }
                                    messages = messages + ChatMessage(text = fallbackReply, isUser = false)
                                }
                            } else {
                                isThinking = false
                                val hintReply = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> "Ավելի խորը պատասխանների համար խնդրում ենք Կարգավորումներում ⚙️ մուտքագրել ${prefs.activeProvider.displayName} API բանալին:"
                                    AppLanguage.RUSSIAN -> "Для развернутых ответов искусственного интеллекта введите API Ключ в Настройках ⚙️ (${prefs.activeProvider.displayName})."
                                    AppLanguage.ENGLISH -> "To receive deep AI answers, please enter your ${prefs.activeProvider.displayName} API Key in Settings ⚙️."
                                }
                                messages = messages + ChatMessage(text = hintReply, isUser = false)
                            }
                        }
                    }
                },
                enabled = !isThinking,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFA855F7))
            ) {
                Icon(Icons.Default.Send, contentDescription = "Send", tint = Color.White, modifier = Modifier.size(20.dp))
            }
        }
    }
}

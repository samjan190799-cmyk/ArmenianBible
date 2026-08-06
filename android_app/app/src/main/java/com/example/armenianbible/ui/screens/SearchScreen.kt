package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*

@Composable
fun SearchScreen(
    dbHelper: BibleDatabaseHelper,
    appLanguage: AppLanguage,
    onOpenReader: (Int, Int) -> Unit
) {
    val context = LocalContext.current
    var queryText by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<BibleSearchResult>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }

    LaunchedEffect(queryText) {
        if (queryText.trim().length >= 2) {
            isSearching = true
            results = dbHelper.searchVerses(queryText, appLanguage)
            isSearching = false
        } else {
            results = emptyList()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F172A))
            .padding(16.dp)
    ) {
        Text(
            text = when(appLanguage) {
                AppLanguage.ARMENIAN -> "Որոնում Библии 🔍"
                AppLanguage.RUSSIAN -> "Поиск по Библии 🔍"
                AppLanguage.ENGLISH -> "Search Bible 🔍"
            },
            style = MaterialTheme.typography.titleLarge.copy(color = Color.White, fontWeight = FontWeight.Bold)
        )

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = queryText,
            onValueChange = { queryText = it },
            placeholder = {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Մուտքագրեք բառ կամ արտահայտություն..."
                        AppLanguage.RUSSIAN -> "Введите слово или фразу..."
                        AppLanguage.ENGLISH -> "Search for words or verses..."
                    },
                    color = Color(0xFF64748B)
                )
            },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF64748B)) },
            trailingIcon = if (queryText.isNotEmpty()) {
                { IconButton(onClick = { queryText = "" }) { Icon(Icons.Default.Close, contentDescription = null, tint = Color.White) } }
            } else null,
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Color(0xFF6366F1),
                unfocusedBorderColor = Color(0xFF334155),
                focusedContainerColor = Color(0xFF1E293B),
                unfocusedContainerColor = Color(0xFF1E293B),
                focusedTextColor = Color.White,
                unfocusedTextColor = Color.White
            ),
            shape = RoundedCornerShape(16.dp)
        )

        Spacer(modifier = Modifier.height(12.dp))

        if (queryText.trim().length >= 2) {
            Text(
                text = "Գտնվել է: ${results.size} стихов",
                color = Color(0xFF94A3B8),
                fontSize = 12.sp
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        if (isSearching) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Color(0xFF6366F1))
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(results) { res ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpenReader(res.bookId, res.chapter) },
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "${res.bookName} ${res.chapter}:${res.verseNumber}",
                                    color = Color(0xFF38BDF8),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )

                                IconButton(
                                    onClick = {
                                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                        val clip = ClipData.newPlainText("Verse", "«${res.text}» — ${res.bookName} ${res.chapter}:${res.verseNumber}")
                                        clipboard.setPrimaryClip(clip)
                                        Toast.makeText(context, "Պատճենված է", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF64748B), modifier = Modifier.size(16.dp))
                                }
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            Text(
                                text = res.text,
                                color = Color(0xFFE2E8F0),
                                fontSize = 14.sp,
                                lineHeight = 20.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

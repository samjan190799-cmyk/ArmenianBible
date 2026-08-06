package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.AppLanguage
import com.example.armenianbible.data.FavoriteItem
import com.example.armenianbible.data.PreferencesManager

@Composable
fun FavoritesScreen(
    prefs: PreferencesManager,
    appLanguage: AppLanguage
) {
    val context = LocalContext.current
    var favoritesList by remember { mutableStateOf(prefs.getFavorites()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F172A))
            .padding(16.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Default.Favorite, contentDescription = null, tint = Color(0xFFEF4444))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = when(appLanguage) {
                    AppLanguage.ARMENIAN -> "Էջանշաններ (Favorites)"
                    AppLanguage.RUSSIAN -> "Избранное"
                    AppLanguage.ENGLISH -> "Favorites"
                },
                style = MaterialTheme.typography.titleLarge.copy(color = Color.White, fontWeight = FontWeight.Bold)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (favoritesList.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Էջանշաններում դեռևս ոչինչ չկա"
                        AppLanguage.RUSSIAN -> "В избранном пока ничего нет"
                        AppLanguage.ENGLISH -> "No favorites added yet"
                    },
                    color = Color(0xFF64748B),
                    fontSize = 16.sp
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(favoritesList, key = { it.id }) { item ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                val ref = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> item.refHy
                                    AppLanguage.RUSSIAN -> item.refRu
                                    AppLanguage.ENGLISH -> item.refEn
                                }
                                Text(
                                    text = ref,
                                    color = Color(0xFF38BDF8),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )

                                Row {
                                    IconButton(
                                        onClick = {
                                            val text = when(appLanguage) {
                                                AppLanguage.ARMENIAN -> item.textHy
                                                AppLanguage.RUSSIAN -> item.textRu
                                                AppLanguage.ENGLISH -> item.textEn
                                            }
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            val clip = ClipData.newPlainText("Verse", "«$text» — $ref")
                                            clipboard.setPrimaryClip(clip)
                                            Toast.makeText(context, "Պատճենված է", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                    }

                                    IconButton(
                                        onClick = {
                                            prefs.removeFavorite(item)
                                            favoritesList = prefs.getFavorites()
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color(0xFFEF4444), modifier = Modifier.size(16.dp))
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            val txt = when(appLanguage) {
                                AppLanguage.ARMENIAN -> item.textHy
                                AppLanguage.RUSSIAN -> item.textRu
                                AppLanguage.ENGLISH -> item.textEn
                            }
                            Text(
                                text = "«$txt»",
                                color = Color(0xFFF1F5F9),
                                fontSize = 15.sp,
                                lineHeight = 22.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

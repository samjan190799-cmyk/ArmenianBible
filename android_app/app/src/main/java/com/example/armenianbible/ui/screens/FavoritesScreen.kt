package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
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
            .background(Color(0xFFF8FAFC))
            .padding(16.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Default.Favorite, contentDescription = null, tint = Color(0xFFEF4444), modifier = Modifier.size(26.dp))
            Spacer(modifier = Modifier.width(10.dp))
            Text(
                text = when(appLanguage) {
                    AppLanguage.ARMENIAN -> "Ընտրյալներ"
                    AppLanguage.RUSSIAN -> "Избранное"
                    AppLanguage.ENGLISH -> "Favorites"
                },
                style = MaterialTheme.typography.titleLarge.copy(
                    color = Color(0xFF0F172A),
                    fontWeight = FontWeight.Bold,
                    fontSize = 22.sp
                )
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (favoritesList.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Ընտրյալներում դեռևս ոչինչ չկա"
                        AppLanguage.RUSSIAN -> "В избранном пока ничего нет"
                        AppLanguage.ENGLISH -> "No favorites added yet"
                    },
                    color = Color(0xFF94A3B8),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(favoritesList, key = { it.id }) { item ->
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
                                val ref = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> item.refHy
                                    AppLanguage.RUSSIAN -> item.refRu
                                    AppLanguage.ENGLISH -> item.refEn
                                }
                                Text(
                                    text = ref,
                                    color = Color(0xFF0EA5E9),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )

                                Row {
                                    IconButton(
                                        onClick = {
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            val text = when(appLanguage) {
                                                AppLanguage.ARMENIAN -> item.textHy
                                                AppLanguage.RUSSIAN -> item.textRu
                                                AppLanguage.ENGLISH -> item.textEn
                                            }
                                            val clip = ClipData.newPlainText("Favorite Verse", "«$text» — $ref")
                                            clipboard.setPrimaryClip(clip)
                                            Toast.makeText(context, "Պատճենված է!", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(36.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.ContentCopy,
                                            contentDescription = "Copy",
                                            tint = Color(0xFF94A3B8),
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }

                                    IconButton(
                                        onClick = {
                                            prefs.removeFavorite(item)
                                            favoritesList = prefs.getFavorites()
                                            Toast.makeText(context, "Հեռացված է", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(36.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = "Delete",
                                            tint = Color(0xFFEF4444),
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            val text = when(appLanguage) {
                                AppLanguage.ARMENIAN -> item.textHy
                                AppLanguage.RUSSIAN -> item.textRu
                                AppLanguage.ENGLISH -> item.textEn
                            }

                            Text(
                                text = "«$text»",
                                color = Color(0xFF1E293B),
                                fontSize = 16.sp,
                                lineHeight = 24.sp,
                                fontFamily = FontFamily.Serif
                            )
                        }
                    }
                }
            }
        }
    }
}

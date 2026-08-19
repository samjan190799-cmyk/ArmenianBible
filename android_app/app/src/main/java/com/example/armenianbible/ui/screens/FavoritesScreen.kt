package com.example.armenianbible.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.armenianbible.data.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesScreen(
    prefs: PreferencesManager,
    appLanguage: AppLanguage
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    var selectedTab by remember { mutableIntStateOf(0) } // 0: Все, 1: Избранное, 2: Заметки, 3: Выделения
    var selectedTagFilter by remember { mutableStateOf<VerseTag?>(null) }
    var searchText by remember { mutableStateOf("") }

    var favoritesList by remember { mutableStateOf(prefs.getFavorites()) }
    var annotationsList by remember { mutableStateOf(prefs.getAllAnnotations()) }
    var editingAnnotation by remember { mutableStateOf<VerseAnnotation?>(null) }

    val filteredAnnotations = remember(annotationsList, selectedTab, selectedTagFilter, searchText) {
        var list = annotationsList
        if (selectedTab == 2) {
            list = list.filter { it.note.trim().isNotEmpty() }
        } else if (selectedTab == 3) {
            list = list.filter { !it.colorHex.isNullOrEmpty() }
        }
        if (selectedTagFilter != null) {
            list = list.filter { it.tags.contains(selectedTagFilter) }
        }
        if (searchText.trim().isNotEmpty()) {
            val q = searchText.lowercase()
            list = list.filter {
                it.text(appLanguage).lowercase().contains(q) ||
                        it.reference(appLanguage).lowercase().contains(q) ||
                        it.note.lowercase().contains(q)
            }
        }
        list
    }

    val filteredFavorites = remember(favoritesList, selectedTab, selectedTagFilter, searchText) {
        if (selectedTab == 2 || selectedTab == 3 || selectedTagFilter != null) {
            emptyList()
        } else {
            if (searchText.trim().isEmpty()) {
                favoritesList
            } else {
                val q = searchText.lowercase()
                favoritesList.filter {
                    val t = when(appLanguage) {
                        AppLanguage.ARMENIAN -> it.textHy
                        AppLanguage.RUSSIAN -> it.textRu
                        AppLanguage.ENGLISH -> it.textEn
                    }
                    val r = when(appLanguage) {
                        AppLanguage.ARMENIAN -> it.refHy
                        AppLanguage.RUSSIAN -> it.refRu
                        AppLanguage.ENGLISH -> it.refEn
                    }
                    t.lowercase().contains(q) || r.lowercase().contains(q)
                }
            }
        }
    }

    val showFavorites = (selectedTab == 0 || selectedTab == 1) && selectedTagFilter == null
    val hasContent = filteredAnnotations.isNotEmpty() || (showFavorites && filteredFavorites.isNotEmpty())

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8FAFC))
            .padding(16.dp)
    ) {
        // Header
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(Icons.Default.Bookmark, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(26.dp))
            Spacer(modifier = Modifier.width(10.dp))
            Text(
                text = when(appLanguage) {
                    AppLanguage.ARMENIAN -> "Նշումներ և ընտրյալներ"
                    AppLanguage.RUSSIAN -> "Заметки и Избранное"
                    AppLanguage.ENGLISH -> "Notes & Favorites"
                },
                style = MaterialTheme.typography.titleLarge.copy(
                    color = Color(0xFF0F172A),
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp
                )
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Tab Selector (Segmented Pill)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFFE2E8F0).copy(alpha = 0.6f))
                .padding(3.dp)
        ) {
            val tabs = when(appLanguage) {
                AppLanguage.ARMENIAN -> listOf("Բոլորը", "Ընտրյալ", "Նշումներ", "Մարկեր")
                AppLanguage.RUSSIAN -> listOf("Все", "Избранное", "Заметки", "Маркер")
                AppLanguage.ENGLISH -> listOf("All", "Favorites", "Notes", "Highlights")
            }

            tabs.forEachIndexed { index, title ->
                val isSelected = selectedTab == index
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (isSelected) Color.White else Color.Transparent)
                        .clickable {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            selectedTab = index
                        }
                        .padding(vertical = 7.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = title,
                        color = if (isSelected) Color(0xFF0284C7) else Color(0xFF64748B),
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                        fontSize = 11.5.sp
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Tags Filter Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            // "All Tags" Pill
            val isAllSelected = selectedTagFilter == null
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = if (isAllSelected) Color(0xFF0284C7) else Color.White,
                border = ButtonDefaults.outlinedButtonBorder().copy(
                    brush = androidx.compose.ui.graphics.SolidColor(if (isAllSelected) Color(0xFF0284C7) else Color(0xFFE2E8F0))
                ),
                modifier = Modifier.clickable {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    selectedTagFilter = null
                }
            ) {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Բոլոր թեգերը"
                        AppLanguage.RUSSIAN -> "Все теги"
                        AppLanguage.ENGLISH -> "All Tags"
                    },
                    color = if (isAllSelected) Color.White else Color(0xFF64748B),
                    fontWeight = if (isAllSelected) FontWeight.Bold else FontWeight.Medium,
                    fontSize = 11.sp,
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                )
            }

            VerseTag.entries.forEach { tag ->
                val isTagSelected = selectedTagFilter == tag
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = if (isTagSelected) {
                        try {
                            Color(android.graphics.Color.parseColor(tag.colorHex)).copy(alpha = 0.25f)
                        } catch (e: Exception) {
                            Color(0xFFE0F2FE)
                        }
                    } else Color.White,
                    border = ButtonDefaults.outlinedButtonBorder().copy(
                        brush = androidx.compose.ui.graphics.SolidColor(
                            if (isTagSelected) {
                                try {
                                    Color(android.graphics.Color.parseColor(tag.colorHex))
                                } catch (e: Exception) {
                                    Color(0xFF0284C7)
                                }
                            } else Color(0xFFE2E8F0)
                        )
                    ),
                    modifier = Modifier.clickable {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        selectedTagFilter = if (isTagSelected) null else tag
                    }
                ) {
                    Text(
                        text = "${tag.icon} ${tag.localizedTitle(appLanguage)}",
                        color = if (isTagSelected) {
                            try {
                                Color(android.graphics.Color.parseColor(tag.colorHex))
                            } catch (e: Exception) {
                                Color(0xFF0284C7)
                            }
                        } else Color(0xFF64748B),
                        fontWeight = if (isTagSelected) FontWeight.Bold else FontWeight.Medium,
                        fontSize = 11.sp,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Search Bar
        OutlinedTextField(
            value = searchText,
            onValueChange = { searchText = it },
            placeholder = {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Որոնել նշումներում և համարներում..."
                        AppLanguage.RUSSIAN -> "Поиск по заметкам и стихам..."
                        AppLanguage.ENGLISH -> "Search notes & verses..."
                    },
                    color = Color(0xFF94A3B8),
                    fontSize = 13.sp
                )
            },
            leadingIcon = {
                Icon(Icons.Default.Search, contentDescription = null, tint = Color(0xFF94A3B8), modifier = Modifier.size(18.dp))
            },
            trailingIcon = {
                if (searchText.isNotEmpty()) {
                    IconButton(onClick = { searchText = "" }) {
                        Icon(Icons.Default.Close, contentDescription = "Clear", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Color(0xFF0284C7),
                unfocusedBorderColor = Color(0xFFE2E8F0),
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White
            ),
            singleLine = true
        )

        Spacer(modifier = Modifier.height(14.dp))

        if (!hasContent) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Ոչինչ չի գտնվել"
                        AppLanguage.RUSSIAN -> "Ничего не найдено"
                        AppLanguage.ENGLISH -> "No items found"
                    },
                    color = Color(0xFF94A3B8),
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                // Annotations (Notes & Highlights)
                items(filteredAnnotations, key = { it.id }) { ann ->
                    val cardBgColor = if (ann.colorHex != null) {
                        try {
                            Color(android.graphics.Color.parseColor(ann.colorHex)).copy(alpha = 0.22f)
                        } catch (e: Exception) {
                            Color.White
                        }
                    } else Color.White

                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(1.dp, RoundedCornerShape(16.dp))
                            .clip(RoundedCornerShape(16.dp))
                            .border(
                                if (ann.colorHex != null) 1.5.dp else 1.dp,
                                if (ann.colorHex != null) {
                                    try {
                                        Color(android.graphics.Color.parseColor(ann.colorHex))
                                    } catch (e: Exception) {
                                        Color(0xFFE2E8F0)
                                    }
                                } else Color(0xFFE2E8F0),
                                RoundedCornerShape(16.dp)
                            ),
                        colors = CardDefaults.cardColors(containerColor = cardBgColor)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = ann.reference(appLanguage),
                                    color = Color(0xFF0284C7),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )

                                Row {
                                    // Edit
                                    IconButton(
                                        onClick = {
                                            editingAnnotation = ann
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.Edit, contentDescription = "Edit", tint = Color(0xFF0284C7), modifier = Modifier.size(16.dp))
                                    }

                                    // Copy
                                    IconButton(
                                        onClick = {
                                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                            var text = "«${ann.text(appLanguage)}» — ${ann.reference(appLanguage)}"
                                            if (ann.note.isNotEmpty()) {
                                                text += "\n\n📝 ${ann.note}"
                                            }
                                            val clip = ClipData.newPlainText("Annotation", text)
                                            clipboard.setPrimaryClip(clip)
                                            Toast.makeText(context, "Պատճենված է!", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                    }

                                    // Delete
                                    IconButton(
                                        onClick = {
                                            prefs.deleteAnnotation(ann.bookId, ann.chapter, ann.verseNumber)
                                            annotationsList = prefs.getAllAnnotations()
                                            Toast.makeText(context, "Հեռացված է", Toast.LENGTH_SHORT).show()
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color(0xFFEF4444), modifier = Modifier.size(16.dp))
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            Text(
                                text = "«${ann.text(appLanguage)}»",
                                color = Color(0xFF1E293B),
                                fontSize = 15.sp,
                                lineHeight = 22.sp,
                                fontFamily = FontFamily.Serif
                            )

                            // Note body
                            if (ann.note.isNotEmpty()) {
                                Spacer(modifier = Modifier.height(10.dp))
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = Color(0xFF0284C7).copy(alpha = 0.08f),
                                    border = ButtonDefaults.outlinedButtonBorder().copy(
                                        brush = androidx.compose.ui.graphics.SolidColor(Color(0xFF0284C7).copy(alpha = 0.2f))
                                    ),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Column(modifier = Modifier.padding(10.dp)) {
                                        Text(
                                            text = "📝 " + when(appLanguage) {
                                                AppLanguage.ARMENIAN -> "Անձնական նշում"
                                                AppLanguage.RUSSIAN -> "Личная заметка"
                                                AppLanguage.ENGLISH -> "Personal Note"
                                            },
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF0284C7)
                                        )
                                        Spacer(modifier = Modifier.height(3.dp))
                                        Text(
                                            text = ann.note,
                                            fontSize = 13.sp,
                                            color = Color(0xFF0F172A),
                                            lineHeight = 18.sp
                                        )
                                    }
                                }
                            }

                            // Tags
                            if (ann.tags.isNotEmpty()) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    ann.tags.forEach { tag ->
                                        Surface(
                                            shape = RoundedCornerShape(6.dp),
                                            color = try {
                                                Color(android.graphics.Color.parseColor(tag.colorHex)).copy(alpha = 0.18f)
                                            } catch (e: Exception) {
                                                Color(0xFFE2E8F0)
                                            }
                                        ) {
                                            Text(
                                                text = "${tag.icon} ${tag.localizedTitle(appLanguage)}",
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = try {
                                                    Color(android.graphics.Color.parseColor(tag.colorHex))
                                                } catch (e: Exception) {
                                                    Color(0xFF0F172A)
                                                },
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Favorites Items
                if (showFavorites) {
                    items(filteredFavorites, key = { it.id }) { item ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .shadow(1.dp, RoundedCornerShape(16.dp))
                                .clip(RoundedCornerShape(16.dp))
                                .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(16.dp)),
                            colors = CardDefaults.cardColors(containerColor = Color.White)
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
                                        color = Color(0xFF0284C7),
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
                                            modifier = Modifier.size(32.dp)
                                        ) {
                                            Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                                        }

                                        IconButton(
                                            onClick = {
                                                prefs.removeFavorite(item)
                                                favoritesList = prefs.getFavorites()
                                                Toast.makeText(context, "Հեռացված է", Toast.LENGTH_SHORT).show()
                                            },
                                            modifier = Modifier.size(32.dp)
                                        ) {
                                            Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color(0xFFEF4444), modifier = Modifier.size(16.dp))
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                val text = when(appLanguage) {
                                    AppLanguage.ARMENIAN -> item.textHy
                                    AppLanguage.RUSSIAN -> item.textRu
                                    AppLanguage.ENGLISH -> item.textEn
                                }

                                Text(
                                    text = "«$text»",
                                    color = Color(0xFF1E293B),
                                    fontSize = 15.sp,
                                    lineHeight = 22.sp,
                                    fontFamily = FontFamily.Serif
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Modal Edit Annotation Bottom Sheet
    if (editingAnnotation != null) {
        val ann = editingAnnotation!!
        var editNoteText by remember(ann) { mutableStateOf(ann.note) }
        var editColorHex by remember(ann) { mutableStateOf(ann.colorHex) }
        var editTags by remember(ann) { mutableStateOf(ann.tags.toSet()) }

        val markerColors = listOf(
            null,
            "#FEF08A",
            "#BBF7D0",
            "#BAE6FD",
            "#FECDD3",
            "#E9D5FF"
        )

        ModalBottomSheet(
            onDismissRequest = {
                val updated = ann.copy(
                    note = editNoteText.trim(),
                    colorHex = editColorHex,
                    tags = editTags.toList(),
                    updatedAtMillis = System.currentTimeMillis()
                )
                prefs.saveAnnotation(updated)
                annotationsList = prefs.getAllAnnotations()
                editingAnnotation = null
            },
            containerColor = Color.White,
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Text(
                    text = ann.reference(appLanguage),
                    fontWeight = FontWeight.Bold,
                    fontSize = 17.sp,
                    color = Color(0xFF0F172A)
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Marker colors
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Գունավոր մարկեր"
                        AppLanguage.RUSSIAN -> "Цветной маркер"
                        AppLanguage.ENGLISH -> "Highlight Color"
                    },
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF64748B)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    markerColors.forEach { cHex ->
                        val isSelected = editColorHex == cHex
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(
                                    if (cHex == null) Color(0xFFF1F5F9)
                                    else try {
                                        Color(android.graphics.Color.parseColor(cHex))
                                    } catch (e: Exception) {
                                        Color.LightGray
                                    }
                                )
                                .border(
                                    if (isSelected) 2.5.dp else 1.dp,
                                    if (isSelected) Color(0xFF0284C7) else Color(0xFFCBD5E1),
                                    CircleShape
                                )
                                .clickable {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    editColorHex = cHex
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            if (cHex == null) {
                                Icon(Icons.Default.Block, contentDescription = "None", tint = Color(0xFF94A3B8), modifier = Modifier.size(18.dp))
                            } else if (isSelected) {
                                Icon(Icons.Default.Check, contentDescription = "Selected", tint = Color(0xFF0F172A), modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Note
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Անձնական նշում"
                        AppLanguage.RUSSIAN -> "Личная заметка"
                        AppLanguage.ENGLISH -> "Personal Note"
                    },
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF64748B)
                )
                Spacer(modifier = Modifier.height(6.dp))
                OutlinedTextField(
                    value = editNoteText,
                    onValueChange = { editNoteText = it },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    minLines = 3,
                    maxLines = 5
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Tags
                Text(
                    text = when(appLanguage) {
                        AppLanguage.ARMENIAN -> "Թեմատիկ պիտակներ"
                        AppLanguage.RUSSIAN -> "Тематические теги"
                        AppLanguage.ENGLISH -> "Topic Tags"
                    },
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF64748B)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    VerseTag.entries.forEach { tag ->
                        val isSelected = editTags.contains(tag)
                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            color = if (isSelected) {
                                try {
                                    Color(android.graphics.Color.parseColor(tag.colorHex)).copy(alpha = 0.3f)
                                } catch (e: Exception) {
                                    Color(0xFFE0F2FE)
                                }
                            } else Color(0xFFF1F5F9),
                            modifier = Modifier.clickable {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                editTags = if (isSelected) editTags - tag else editTags + tag
                            }
                        ) {
                            Text(
                                text = "${tag.icon} ${tag.localizedTitle(appLanguage)}",
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = Color(0xFF0F172A),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Button(
                    onClick = {
                        val updated = ann.copy(
                            note = editNoteText.trim(),
                            colorHex = editColorHex,
                            tags = editTags.toList(),
                            updatedAtMillis = System.currentTimeMillis()
                        )
                        prefs.saveAnnotation(updated)
                        annotationsList = prefs.getAllAnnotations()
                        editingAnnotation = null
                        Toast.makeText(context, "Պահպանված է!", Toast.LENGTH_SHORT).show()
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0284C7)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Պահպանել", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
                }

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

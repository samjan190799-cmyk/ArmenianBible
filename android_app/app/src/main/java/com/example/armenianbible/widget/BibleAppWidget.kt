package com.example.armenianbible.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.Toast
import com.example.armenianbible.MainActivity
import com.example.armenianbible.R
import com.example.armenianbible.data.*

class BibleAppWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_WIDGET_NEXT_VERSE -> {
                val prefs = PreferencesManager(context)
                val dbHelper = BibleDatabaseHelper.getInstance(context)

                val newVerse: BibleVerse? = when (prefs.selectedCategory) {
                    TextCategory.VERSES -> dbHelper.getRandomShortVerse() ?: dbHelper.getRandomVerse()
                    TextCategory.PRAYERS -> {
                        val prayer = NarekatsiDatabase.prayers.randomOrNull()
                        if (prayer != null) {
                            BibleVerse(
                                textHy = prayer.textHy,
                                textRu = prayer.textRu,
                                textEn = prayer.textEn,
                                refHy = prayer.banNumber,
                                refRu = prayer.banNumber,
                                refEn = prayer.banNumber,
                                isPrayer = true
                            )
                        } else (dbHelper.getRandomShortVerse() ?: dbHelper.getRandomVerse())
                    }
                    TextCategory.FAVORITES -> {
                        val favs = prefs.getFavorites()
                        if (favs.isNotEmpty()) {
                            val f = favs.random()
                            BibleVerse(
                                textHy = f.textHy,
                                textRu = f.textRu,
                                textEn = f.textEn,
                                refHy = f.refHy,
                                refRu = f.refRu,
                                refEn = f.refEn
                            )
                        } else (dbHelper.getRandomShortVerse() ?: dbHelper.getRandomVerse())
                    }
                    TextCategory.BOTH -> {
                        if ((0..1).random() == 0) {
                            dbHelper.getRandomShortVerse() ?: dbHelper.getRandomVerse()
                        } else {
                            val prayer = NarekatsiDatabase.prayers.randomOrNull()
                            if (prayer != null) {
                                BibleVerse(
                                    textHy = prayer.textHy,
                                    textRu = prayer.textRu,
                                    textEn = prayer.textEn,
                                    refHy = prayer.banNumber,
                                    refRu = prayer.banNumber,
                                    refEn = prayer.banNumber,
                                    isPrayer = true
                                )
                            } else (dbHelper.getRandomShortVerse() ?: dbHelper.getRandomVerse())
                        }
                    }
                }

                if (newVerse != null) {
                    prefs.saveCurrentVerseForWidget(newVerse)
                    sendUpdateBroadcast(context)
                }
            }

            ACTION_WIDGET_TOGGLE_FAVORITE -> {
                val prefs = PreferencesManager(context)
                val (text, ref) = prefs.getWidgetVerse(prefs.appLanguage)
                val item = FavoriteItem(
                    textHy = text,
                    textRu = text,
                    textEn = text,
                    refHy = ref,
                    refRu = ref,
                    refEn = ref
                )
                if (prefs.isFavorite(ref)) {
                    prefs.removeFavorite(item)
                    Toast.makeText(context, "Հեռացված է ընտրյալներից", Toast.LENGTH_SHORT).show()
                } else {
                    prefs.addFavorite(item)
                    Toast.makeText(context, "Ավելացված է ընտրյալներում ❤️", Toast.LENGTH_SHORT).show()
                }
                sendUpdateBroadcast(context)
            }

            ACTION_WIDGET_TOGGLE_PRAYER -> {
                val prefs = PreferencesManager(context)
                val isDone = prefs.togglePrayerCompletedToday()
                val msg = if (isDone) {
                    when(prefs.appLanguage) {
                        AppLanguage.ARMENIAN -> "Օրվա աղոթքը կատարված է 🙏"
                        AppLanguage.RUSSIAN -> "Молитва дня выполнена 🙏"
                        AppLanguage.ENGLISH -> "Daily prayer marked as completed 🙏"
                    }
                } else {
                    when(prefs.appLanguage) {
                        AppLanguage.ARMENIAN -> "Աղոթքի կարգավիճակը չեղարկված է"
                        AppLanguage.RUSSIAN -> "Статус молитвы сброшен"
                        AppLanguage.ENGLISH -> "Prayer status reset"
                    }
                }
                Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                sendUpdateBroadcast(context)
            }
        }
    }

    companion object {
        const val ACTION_WIDGET_NEXT_VERSE = "com.example.armenianbible.ACTION_WIDGET_NEXT_VERSE"
        const val ACTION_WIDGET_TOGGLE_FAVORITE = "com.example.armenianbible.ACTION_WIDGET_TOGGLE_FAVORITE"
        const val ACTION_WIDGET_TOGGLE_PRAYER = "com.example.armenianbible.ACTION_WIDGET_TOGGLE_PRAYER"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = PreferencesManager(context)
            val (verseText, verseRef) = prefs.getWidgetVerse(prefs.appLanguage)

            val views = RemoteViews(context.packageName, R.layout.widget_bible)
            views.setTextViewText(R.id.widget_verse_text, "«$verseText»")
            views.setTextViewText(R.id.widget_verse_ref, "— $verseRef")

            // Title
            val titleText = when (prefs.widgetLanguage) {
                WidgetLanguage.FOLLOW_APP -> when(prefs.appLanguage) {
                    AppLanguage.ARMENIAN -> "🕊️ Աստվածաշունչ"
                    AppLanguage.RUSSIAN -> "🕊️ Библия"
                    AppLanguage.ENGLISH -> "🕊️ Holy Bible"
                }
                WidgetLanguage.ARMENIAN -> "🕊️ Աստվածաշունչ"
                WidgetLanguage.RUSSIAN -> "🕊️ Библия"
                WidgetLanguage.ENGLISH -> "🕊️ Holy Bible"
            }
            views.setTextViewText(R.id.widget_title, titleText)

            // 1. Click on Body / Read Button -> Open Main Activity
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                101,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_verse_text, openPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_btn_read, openPendingIntent)

            // 2. Click on Refresh Icon & "Next" Button -> Next Random Verse
            val nextIntent = Intent(context, BibleAppWidget::class.java).apply {
                action = ACTION_WIDGET_NEXT_VERSE
            }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context,
                102,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_icon, nextPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_btn_next, nextPendingIntent)

            // 3. Click on Favorite Button -> Toggle Favorite
            val favIntent = Intent(context, BibleAppWidget::class.java).apply {
                action = ACTION_WIDGET_TOGGLE_FAVORITE
            }
            val favPendingIntent = PendingIntent.getBroadcast(
                context,
                103,
                favIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val isFav = prefs.isFavorite(verseRef)
            views.setTextViewText(R.id.widget_btn_fav, if (isFav) "❤️ Պահված" else "🤍 Ընտրյալ")
            views.setOnClickPendingIntent(R.id.widget_btn_fav, favPendingIntent)

            // 4. Click on Prayer Button -> Toggle Daily Prayer Status
            val prayIntent = Intent(context, BibleAppWidget::class.java).apply {
                action = ACTION_WIDGET_TOGGLE_PRAYER
            }
            val prayPendingIntent = PendingIntent.getBroadcast(
                context,
                104,
                prayIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val isPrayed = prefs.isPrayerCompletedToday()
            val prayBtnText = if (isPrayed) {
                when(prefs.appLanguage) {
                    AppLanguage.ARMENIAN -> "✓ Աղոթել եմ"
                    AppLanguage.RUSSIAN -> "✓ Помолился"
                    AppLanguage.ENGLISH -> "✓ Prayed"
                }
            } else {
                when(prefs.appLanguage) {
                    AppLanguage.ARMENIAN -> "🙏 Աղոթել"
                    AppLanguage.RUSSIAN -> "🙏 Помолиться"
                    AppLanguage.ENGLISH -> "🙏 Pray"
                }
            }
            views.setTextViewText(R.id.widget_btn_pray, prayBtnText)
            views.setOnClickPendingIntent(R.id.widget_btn_pray, prayPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun sendUpdateBroadcast(context: Context) {
            val intent = Intent(context, BibleAppWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, BibleAppWidget::class.java))
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            context.sendBroadcast(intent)
        }
    }
}

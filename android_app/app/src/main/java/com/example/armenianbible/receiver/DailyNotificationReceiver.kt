package com.example.armenianbible.receiver

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.armenianbible.MainActivity
import com.example.armenianbible.R
import com.example.armenianbible.data.AppLanguage
import com.example.armenianbible.data.BibleDatabaseHelper
import com.example.armenianbible.data.PreferencesManager
import com.example.armenianbible.widget.BibleAppWidget
import java.util.Calendar

class DailyNotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = PreferencesManager(context)

        // Reschedule on boot
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            if (prefs.dailyNotificationsEnabled) {
                scheduleDailyNotification(context)
            }
            return
        }

        // Only show if notifications enabled
        if (!prefs.dailyNotificationsEnabled) return

        val dbHelper = BibleDatabaseHelper.getInstance(context)
        val verse = dbHelper.getRandomVerse() ?: return

        // Update widget with new verse
        prefs.saveCurrentVerseForWidget(verse)
        BibleAppWidget.sendUpdateBroadcast(context)

        // Build & Show Notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "armenian_bible_daily_verse"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Օրվա Աստվածաշնչյան համար (Стих Дня)",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Daily inspirational Bible verse"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val lang = prefs.appLanguage
        val title = when (lang) {
            AppLanguage.ARMENIAN -> "✝️ Օրվա համար — ${verse.refHy}"
            AppLanguage.RUSSIAN -> "✝️ Стих дня — ${verse.refRu}"
            AppLanguage.ENGLISH -> "✝️ Verse of the Day — ${verse.refEn}"
        }

        val text = verse.text(lang)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_cross)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text).setSummaryText(verse.reference(lang)))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(1001, notification)

        // Schedule next alarm for tomorrow
        scheduleDailyNotification(context)
    }

    companion object {
        fun scheduleDailyNotification(context: Context) {
            val prefs = PreferencesManager(context)
            if (!prefs.dailyNotificationsEnabled) {
                cancelDailyNotification(context)
                return
            }

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, DailyNotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val calendar = Calendar.getInstance().apply {
                timeInMillis = System.currentTimeMillis()
                set(Calendar.HOUR_OF_DAY, prefs.dailyNotificationHour)
                set(Calendar.MINUTE, prefs.dailyNotificationMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)

                // If scheduled time has already passed today, set for tomorrow
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                }
            } catch (e: SecurityException) {
                // If exact alarm permission is missing on Android 12+, fallback to inexact
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            }
        }

        fun cancelDailyNotification(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, DailyNotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}

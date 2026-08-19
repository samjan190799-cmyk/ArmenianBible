package com.example.armenianbible.data

import android.content.Context
import android.content.Intent
import android.graphics.*
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

object VerseCardExporter {

    fun shareVerseAsImage(
        context: Context,
        verse: BibleVerse,
        appLanguage: AppLanguage,
        accentTheme: AccentColorTheme
    ) {
        try {
            val width = 1080
            val height = 1080
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            // 1. Background
            val bgPaint = Paint().apply {
                color = Color.parseColor("#F8FAFC")
                style = Paint.Style.FILL
            }
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)

            // 2. Subtle Glow in Center
            val accentInt = Color.parseColor(accentTheme.colorHex)
            val glowPaint = Paint().apply {
                shader = RadialGradient(
                    width / 2f,
                    height / 2f - 40f,
                    450f,
                    intArrayOf(Color.argb(35, Color.red(accentInt), Color.green(accentInt), Color.blue(accentInt)), Color.TRANSPARENT),
                    floatArrayOf(0f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawCircle(width / 2f, height / 2f - 40f, 450f, glowPaint)

            // 3. Card Container Border
            val cardRect = RectF(60f, 60f, width - 60f, height - 60f)
            val cardBgPaint = Paint().apply {
                color = Color.WHITE
                style = Paint.Style.FILL
                isAntiAlias = true
            }
            val cardBorderPaint = Paint().apply {
                color = Color.parseColor("#E2E8F0")
                style = Paint.Style.STROKE
                strokeWidth = 3f
                isAntiAlias = true
            }
            canvas.drawRoundRect(cardRect, 40f, 40f, cardBgPaint)
            canvas.drawRoundRect(cardRect, 40f, 40f, cardBorderPaint)

            // 4. Laurel / Dove Icon at Top
            val iconPaint = Paint().apply {
                color = Color.parseColor(accentTheme.colorHex)
                textSize = 64f
                textAlign = Paint.Align.CENTER
                isAntiAlias = true
            }
            canvas.drawText("🕊️", width / 2f, 180f, iconPaint)

            // 5. Verse Text
            val textPaint = TextPaint().apply {
                color = Color.parseColor("#0F172A")
                textSize = 42f
                typeface = Typeface.create(Typeface.SERIF, Typeface.BOLD)
                isAntiAlias = true
            }

            val text = "«${verse.text(appLanguage)}»"
            val textWidth = width - 240
            val staticLayout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, textWidth)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setLineSpacing(14f, 1.2f)
                .setIncludePad(false)
                .build()

            val textHeight = staticLayout.height
            val startY = ((height - textHeight) / 2f) - 20f

            canvas.save()
            canvas.translate(120f, startY)
            staticLayout.draw(canvas)
            canvas.restore()

            // 6. Verse Reference
            val refPaint = Paint().apply {
                color = Color.parseColor(accentTheme.colorHex)
                textSize = 30f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
                isAntiAlias = true
            }
            val refY = startY + textHeight + 60f
            canvas.drawText("— ${verse.reference(appLanguage)}", width / 2f, refY, refPaint)

            // 7. Watermark / App Title at bottom
            val watermarkPaint = Paint().apply {
                color = Color.parseColor("#94A3B8")
                textSize = 24f
                typeface = Typeface.DEFAULT
                textAlign = Paint.Align.CENTER
                isAntiAlias = true
            }
            canvas.drawText("✝️ Armenian Bible (Աստվածաշունչ)", width / 2f, height - 110f, watermarkPaint)

            // 8. Save to cache
            val imagesFolder = File(context.cacheDir, "images")
            imagesFolder.mkdirs()
            val file = File(imagesFolder, "verse_share.png")
            val stream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.flush()
            stream.close()

            // 9. Launch Share Intent
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, "«${verse.text(appLanguage)}»\n\n${verse.reference(appLanguage)}\n\n(Armenian Bible)")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(
                shareIntent,
                when(appLanguage) {
                    AppLanguage.ARMENIAN -> "Կիսվել մեջբերումով"
                    AppLanguage.RUSSIAN -> "Поделиться открыткой со стихом"
                    AppLanguage.ENGLISH -> "Share verse card"
                }
            )
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

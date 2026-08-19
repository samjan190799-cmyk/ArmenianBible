package com.example.armenianbible.data

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.widget.Toast
import androidx.compose.runtime.mutableStateOf
import java.util.Locale

class NarekAudioPlayer private constructor(private val context: Context) {

    private var mediaPlayer: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    val isPlaying = mutableStateOf(false)
    val currentlyPlayingId = mutableStateOf<Int?>(null)
    val isStreaming = mutableStateOf(false)

    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            isTtsReady = (status == TextToSpeech.SUCCESS)
        }
    }

    fun togglePlay(prayer: NarekPrayer, language: AppLanguage) {
        if (isPlaying.value && currentlyPlayingId.value == prayer.id) {
            stop()
            return
        }

        stop()
        currentlyPlayingId.value = prayer.id
        isPlaying.value = true

        val urlString = if (language == AppLanguage.ARMENIAN) prayer.audioUrlHy else (prayer.audioUrlRu ?: prayer.audioUrlHy)

        if (!urlString.isNullOrEmpty()) {
            playFromUrl(urlString, prayer, language)
        } else {
            fallbackToTts(prayer, language)
        }
    }

    private fun playFromUrl(url: String, prayer: NarekPrayer, language: AppLanguage) {
        try {
            isStreaming.value = true
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(url)
                setOnPreparedListener { mp ->
                    if (currentlyPlayingId.value == prayer.id) {
                        mp.start()
                        isStreaming.value = false
                        this@NarekAudioPlayer.isPlaying.value = true
                    }
                }
                setOnCompletionListener {
                    stop()
                }
                setOnErrorListener { _, _, _ ->
                    isStreaming.value = false
                    fallbackToTts(prayer, language)
                    true
                }
                prepareAsync()
            }

            // Safety timeout: if stream takes > 3.5s to start, fallback to TTS
            mainHandler.postDelayed({
                if (currentlyPlayingId.value == prayer.id && isStreaming.value) {
                    if (mediaPlayer?.isPlaying != true) {
                        fallbackToTts(prayer, language)
                    }
                }
            }, 3500)

        } catch (e: Exception) {
            fallbackToTts(prayer, language)
        }
    }

    private fun fallbackToTts(prayer: NarekPrayer, language: AppLanguage) {
        try {
            mediaPlayer?.release()
            mediaPlayer = null
            isStreaming.value = false

            val textToRead = "${prayer.title(language)}. ${prayer.text(language)}"
            val locale = when (language) {
                AppLanguage.ARMENIAN -> Locale("hy")
                AppLanguage.RUSSIAN -> Locale("ru")
                AppLanguage.ENGLISH -> Locale("en")
            }

            tts?.language = locale
            tts?.speak(textToRead, TextToSpeech.QUEUE_FLUSH, null, "NarekTTS")
            isPlaying.value = true

        } catch (e: Exception) {
            stop()
            Toast.makeText(context, "Не удалось воспроизвести аудио", Toast.LENGTH_SHORT).show()
        }
    }

    fun stop() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {}

        try {
            tts?.stop()
        } catch (e: Exception) {}

        isPlaying.value = false
        currentlyPlayingId.value = null
        isStreaming.value = false
    }

    companion object {
        @Volatile
        private var instance: NarekAudioPlayer? = null

        fun getInstance(context: Context): NarekAudioPlayer {
            return instance ?: synchronized(this) {
                instance ?: NarekAudioPlayer(context.applicationContext).also { instance = it }
            }
        }
    }
}

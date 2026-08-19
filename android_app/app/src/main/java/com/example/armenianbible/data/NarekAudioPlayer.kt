package com.example.armenianbible.data

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.widget.Toast
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import java.util.Locale

class NarekAudioPlayer private constructor(private val context: Context) {

    private val prefs = PreferencesManager(context)
    private var mediaPlayer: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    val isPlaying = mutableStateOf(false)
    val currentlyPlayingId = mutableStateOf<Int?>(null)
    val isStreaming = mutableStateOf(false)
    val currentTimeMs = mutableLongStateOf(0L)
    val durationMs = mutableLongStateOf(0L)
    val voiceLanguage = mutableStateOf(prefs.narekVoiceLanguage)

    val savedPrayerId = mutableStateOf(prefs.narekLastPrayerId)
    val savedTimeMs = mutableLongStateOf(prefs.narekLastTimeMs)

    private val mainHandler = Handler(Looper.getMainLooper())

    private val progressUpdater = object : Runnable {
        override fun run() {
            if (isPlaying.value && mediaPlayer != null) {
                try {
                    val pos = mediaPlayer?.currentPosition?.toLong() ?: 0L
                    val dur = mediaPlayer?.duration?.toLong() ?: 0L
                    currentTimeMs.longValue = pos
                    if (dur > 0) durationMs.longValue = dur
                    savePlaybackState()
                } catch (e: Exception) {}
                mainHandler.postDelayed(this, 500)
            }
        }
    }

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            isTtsReady = (status == TextToSpeech.SUCCESS)
        }
        currentTimeMs.longValue = savedTimeMs.longValue
        currentlyPlayingId.value = savedPrayerId.value
    }

    fun savePlaybackState() {
        currentlyPlayingId.value?.let { id ->
            savedPrayerId.value = id
            savedTimeMs.longValue = currentTimeMs.longValue
            prefs.narekLastPrayerId = id
            prefs.narekLastTimeMs = currentTimeMs.longValue
            prefs.narekVoiceLanguage = voiceLanguage.value
        }
    }

    fun togglePlay(prayer: NarekPrayer, language: AppLanguage? = null) {
        val lang = language ?: voiceLanguage.value
        voiceLanguage.value = lang

        if (isPlaying.value && currentlyPlayingId.value == prayer.id) {
            pause()
            return
        }

        if (!isPlaying.value && currentlyPlayingId.value == prayer.id && mediaPlayer != null) {
            resume()
            return
        }

        val startAt = if (currentlyPlayingId.value == prayer.id) currentTimeMs.longValue else 0L
        play(prayer, lang, startAt)
    }

    fun play(prayer: NarekPrayer, language: AppLanguage, startAtMs: Long = 0L) {
        stop()
        currentlyPlayingId.value = prayer.id
        voiceLanguage.value = language
        isPlaying.value = true
        currentTimeMs.longValue = startAtMs

        // Check if bundled asset exists
        val assetPath = if (language == AppLanguage.ARMENIAN) "audio/narek_sos_sargsyan.mp3" else "audio/narek_russian_prayers.mp3"
        try {
            val afd = context.assets.openFd(assetPath)
            playFromAsset(afd, prayer, startAtMs)
            return
        } catch (e: Exception) {
            // Asset not found, try url
        }

        val urlString = if (language == AppLanguage.ARMENIAN) prayer.audioUrlHy else (prayer.audioUrlRu ?: prayer.audioUrlHy)

        if (!urlString.isNullOrEmpty()) {
            playFromUrl(urlString, prayer, language, startAtMs)
        } else {
            fallbackToTts(prayer, language)
        }
    }

    private fun playFromAsset(afd: android.content.res.AssetFileDescriptor, prayer: NarekPrayer, startAtMs: Long) {
        try {
            isStreaming.value = false
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setOnPreparedListener { mp ->
                    if (currentlyPlayingId.value == prayer.id) {
                        if (startAtMs > 0) {
                            mp.seekTo(startAtMs.toInt())
                        }
                        mp.start()
                        this@NarekAudioPlayer.isPlaying.value = true
                        durationMs.longValue = mp.duration.toLong()
                        mainHandler.post(progressUpdater)
                    }
                }
                setOnCompletionListener {
                    playNextPrayer()
                }
                setOnErrorListener { _, _, _ ->
                    fallbackToTts(prayer, voiceLanguage.value)
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            fallbackToTts(prayer, voiceLanguage.value)
        }
    }

    private fun playFromUrl(url: String, prayer: NarekPrayer, language: AppLanguage, startAtMs: Long) {
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
                        if (startAtMs > 0) {
                            mp.seekTo(startAtMs.toInt())
                        }
                        mp.start()
                        isStreaming.value = false
                        this@NarekAudioPlayer.isPlaying.value = true
                        durationMs.longValue = mp.duration.toLong()
                        mainHandler.post(progressUpdater)
                    }
                }
                setOnCompletionListener {
                    playNextPrayer()
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
            tts?.setSpeechRate(0.88f)
            tts?.setPitch(0.95f)
            tts?.speak(textToRead, TextToSpeech.QUEUE_FLUSH, null, "NarekTTS")
            isPlaying.value = true
            durationMs.longValue = (textToRead.length * 80).toLong()

        } catch (e: Exception) {
            stop()
            Toast.makeText(context, "Не удалось воспроизвести аудио", Toast.LENGTH_SHORT).show()
        }
    }

    fun pause() {
        try {
            mediaPlayer?.pause()
        } catch (e: Exception) {}
        try {
            tts?.stop()
        } catch (e: Exception) {}

        isPlaying.value = false
        mainHandler.removeCallbacks(progressUpdater)
        savePlaybackState()
    }

    fun resume() {
        try {
            mediaPlayer?.start()
            isPlaying.value = true
            mainHandler.post(progressUpdater)
        } catch (e: Exception) {
            currentlyPlayingId.value?.let { id ->
                NarekatsiDatabase.prayers.find { it.id == id }?.let { p ->
                    play(p, voiceLanguage.value, currentTimeMs.longValue)
                }
            }
        }
    }

    fun seekTo(positionMs: Long) {
        currentTimeMs.longValue = positionMs
        try {
            mediaPlayer?.seekTo(positionMs.toInt())
        } catch (e: Exception) {}
        savePlaybackState()
    }

    fun skipForward(seconds: Int = 15) {
        val newPos = minOf(currentTimeMs.longValue + seconds * 1000L, if (durationMs.longValue > 0) durationMs.longValue else currentTimeMs.longValue + seconds * 1000L)
        seekTo(newPos)
    }

    fun skipBackward(seconds: Int = 15) {
        val newPos = maxOf(currentTimeMs.longValue - seconds * 1000L, 0L)
        seekTo(newPos)
    }

    fun playNextPrayer() {
        val currentId = currentlyPlayingId.value ?: savedPrayerId.value
        val nextId = if (currentId < 95) currentId + 1 else 1
        NarekatsiDatabase.prayers.find { it.id == nextId }?.let { next ->
            play(next, voiceLanguage.value)
        }
    }

    fun playPreviousPrayer() {
        val currentId = currentlyPlayingId.value ?: savedPrayerId.value
        val prevId = if (currentId > 1) currentId - 1 else 95
        NarekatsiDatabase.prayers.find { it.id == prevId }?.let { prev ->
            play(prev, voiceLanguage.value)
        }
    }

    fun stop() {
        savePlaybackState()
        mainHandler.removeCallbacks(progressUpdater)
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {}

        try {
            tts?.stop()
        } catch (e: Exception) {}

        isPlaying.value = false
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

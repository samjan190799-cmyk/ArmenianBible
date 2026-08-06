package com.example.armenianbible.data

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class PreferencesManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("armenian_bible_prefs", Context.MODE_PRIVATE)
    private val gson = Gson()

    companion object {
        private const val KEY_APP_LANG = "app_language"
        private const val KEY_ARMENIAN_EDITION = "armenian_edition"
        private const val KEY_ACCENT_THEME = "accent_theme"
        private const val KEY_AI_PROVIDER = "ai_provider"
        private const val KEY_TEXT_CATEGORY = "text_category"
        private const val KEY_UPDATE_INTERVAL = "update_interval"
        private const val KEY_FONT_SIZE = "font_size"
        private const val KEY_FAVORITES = "favorites_json"
        private const val KEY_QUIZ_BEST_SCORE = "quiz_best_score"

        private const val KEY_GEMINI_API_KEY = "gemini_api_key"
        private const val KEY_OPENAI_API_KEY = "openai_api_key"
        private const val KEY_CLAUDE_API_KEY = "claude_api_key"

        private const val KEY_WIDGET_TEXT_HY = "widget_text_hy"
        private const val KEY_WIDGET_TEXT_RU = "widget_text_ru"
        private const val KEY_WIDGET_TEXT_EN = "widget_text_en"
        private const val KEY_WIDGET_REF_HY = "widget_ref_hy"
        private const val KEY_WIDGET_REF_RU = "widget_ref_ru"
        private const val KEY_WIDGET_REF_EN = "widget_ref_en"
    }

    var appLanguage: AppLanguage
        get() {
            val code = prefs.getString(KEY_APP_LANG, AppLanguage.ARMENIAN.code)
            return AppLanguage.entries.find { it.code == code } ?: AppLanguage.ARMENIAN
        }
        set(value) = prefs.edit().putString(KEY_APP_LANG, value.code).apply()

    var armenianEdition: ArmenianEdition
        get() {
            val name = prefs.getString(KEY_ARMENIAN_EDITION, ArmenianEdition.ARARAT.name)
            return try { ArmenianEdition.valueOf(name!!) } catch (e: Exception) { ArmenianEdition.ARARAT }
        }
        set(value) = prefs.edit().putString(KEY_ARMENIAN_EDITION, value.name).apply()

    var accentTheme: AccentColorTheme
        get() {
            val name = prefs.getString(KEY_ACCENT_THEME, AccentColorTheme.INDIGO.name)
            return try { AccentColorTheme.valueOf(name!!) } catch (e: Exception) { AccentColorTheme.INDIGO }
        }
        set(value) = prefs.edit().putString(KEY_ACCENT_THEME, value.name).apply()

    var activeProvider: AIProvider
        get() {
            val name = prefs.getString(KEY_AI_PROVIDER, AIProvider.GEMINI.name)
            return try { AIProvider.valueOf(name!!) } catch (e: Exception) { AIProvider.GEMINI }
        }
        set(value) = prefs.edit().putString(KEY_AI_PROVIDER, value.name).apply()

    var selectedCategory: TextCategory
        get() {
            val name = prefs.getString(KEY_TEXT_CATEGORY, TextCategory.BOTH.name)
            return try { TextCategory.valueOf(name!!) } catch (e: Exception) { TextCategory.BOTH }
        }
        set(value) = prefs.edit().putString(KEY_TEXT_CATEGORY, value.name).apply()

    var updateInterval: UpdateInterval
        get() {
            val name = prefs.getString(KEY_UPDATE_INTERVAL, UpdateInterval.EVERY_HOUR.name)
            return try { UpdateInterval.valueOf(name!!) } catch (e: Exception) { UpdateInterval.EVERY_HOUR }
        }
        set(value) = prefs.edit().putString(KEY_UPDATE_INTERVAL, value.name).apply()

    var geminiApiKey: String
        get() = prefs.getString(KEY_GEMINI_API_KEY, "") ?: ""
        set(value) = prefs.edit().putString(KEY_GEMINI_API_KEY, value).apply()

    var openaiApiKey: String
        get() = prefs.getString(KEY_OPENAI_API_KEY, "") ?: ""
        set(value) = prefs.edit().putString(KEY_OPENAI_API_KEY, value).apply()

    var anthropicApiKey: String
        get() = prefs.getString(KEY_CLAUDE_API_KEY, "") ?: ""
        set(value) = prefs.edit().putString(KEY_CLAUDE_API_KEY, value).apply()

    var fontSize: Float
        get() = prefs.getFloat(KEY_FONT_SIZE, 18f)
        set(value) = prefs.edit().putFloat(KEY_FONT_SIZE, value).apply()

    var quizBestScore: Int
        get() = prefs.getInt(KEY_QUIZ_BEST_SCORE, 0)
        set(value) = prefs.edit().putInt(KEY_QUIZ_BEST_SCORE, value).apply()

    fun getFavorites(): List<FavoriteItem> {
        val json = prefs.getString(KEY_FAVORITES, null) ?: return emptyList()
        val type = object : TypeToken<List<FavoriteItem>>() {}.type
        return try { gson.fromJson(json, type) ?: emptyList() } catch (e: Exception) { emptyList() }
    }

    fun addFavorite(item: FavoriteItem) {
        val list = getFavorites().toMutableList()
        if (list.none { it.refHy == item.refHy || (it.textHy == item.textHy && it.textHy.isNotEmpty()) }) {
            list.add(0, item)
            prefs.edit().putString(KEY_FAVORITES, gson.toJson(list)).apply()
        }
    }

    fun removeFavorite(item: FavoriteItem) {
        val list = getFavorites().filterNot { it.id == item.id || (it.refHy == item.refHy && it.refRu == item.refRu) }
        prefs.edit().putString(KEY_FAVORITES, gson.toJson(list)).apply()
    }

    fun isFavorite(refHy: String): Boolean {
        return getFavorites().any { it.refHy == refHy }
    }

    fun saveCurrentVerseForWidget(verse: BibleVerse) {
        prefs.edit()
            .putString(KEY_WIDGET_TEXT_HY, verse.textHy)
            .putString(KEY_WIDGET_TEXT_RU, verse.textRu)
            .putString(KEY_WIDGET_TEXT_EN, verse.textEn)
            .putString(KEY_WIDGET_REF_HY, verse.refHy)
            .putString(KEY_WIDGET_REF_RU, verse.refRu)
            .putString(KEY_WIDGET_REF_EN, verse.refEn)
            .apply()
    }

    fun getWidgetVerse(language: AppLanguage): Pair<String, String> {
        val text = when(language) {
            AppLanguage.ARMENIAN -> prefs.getString(KEY_WIDGET_TEXT_HY, "Ի սկզբանէ էր Բանն, եւ Բանն էր առ Աստուած, եւ Աստուած էր Բանն:")
            AppLanguage.RUSSIAN -> prefs.getString(KEY_WIDGET_TEXT_RU, "В начале было Слово, и Слово было у Бога, и Слово было Бог.")
            AppLanguage.ENGLISH -> prefs.getString(KEY_WIDGET_TEXT_EN, "In the beginning was the Word, and the Word was with God, and the Word was God.")
        } ?: ""
        val ref = when(language) {
            AppLanguage.ARMENIAN -> prefs.getString(KEY_WIDGET_REF_HY, "Յովհաննէս 1:1")
            AppLanguage.RUSSIAN -> prefs.getString(KEY_WIDGET_REF_RU, "От Иоанна 1:1")
            AppLanguage.ENGLISH -> prefs.getString(KEY_WIDGET_REF_EN, "John 1:1")
        } ?: ""
        return Pair(text, ref)
    }
}

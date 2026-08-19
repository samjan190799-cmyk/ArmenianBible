package com.example.armenianbible.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

object AIService {

    suspend fun generateVerse(
        provider: AIProvider,
        apiKey: String,
        appLanguage: AppLanguage
    ): Result<BibleVerse> = withContext(Dispatchers.IO) {
        val trimmedKey = apiKey.trim()
        if (trimmedKey.isEmpty()) {
            return@withContext Result.failure(Exception("API Key is empty"))
        }

        val prompt = when (appLanguage) {
            AppLanguage.ARMENIAN -> "Դու Աստվածաշնչի փորձագետ ես: Գեներացրու մեկ պատահական, ոգեշնչող, իմաստալից և գեղեցիկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (Արարատ թարգմանությունից): Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների կամ բազմակետերի (...): Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
            AppLanguage.RUSSIAN -> "Ты эксперт по Библии. Сгенерируй одну случайную, вдохновляющую, глубокую и красивую библейскую цитату на русском языке (из Синодального перевода). Пиши ПОЛНЫЙ текст цитаты без сокращений и многоточий (...). Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
            AppLanguage.ENGLISH -> "You are a Bible expert. Generate one random, inspiring, meaningful, and beautiful Bible quote in English (from KJV or ESV translation). Write the COMPLETE text of the quote without abbreviations or ellipses (...). Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }

        try {
            val rawOutput = queryModel(provider, trimmedKey, prompt)
            val parts = rawOutput.split("|")
            val (text, ref) = if (parts.size >= 2) {
                Pair(parts[0].trim().trim('"', '«', '»'), parts[1].trim())
            } else {
                Pair(rawOutput.trim().trim('"', '«', '»'), when(appLanguage) {
                    AppLanguage.ARMENIAN -> "Աստվածաշունչ"
                    AppLanguage.RUSSIAN -> "Священное Писание"
                    AppLanguage.ENGLISH -> "Holy Bible"
                })
            }

            val verse = BibleVerse(
                textHy = if (appLanguage == AppLanguage.ARMENIAN) text else text,
                textRu = if (appLanguage == AppLanguage.RUSSIAN) text else text,
                textEn = if (appLanguage == AppLanguage.ENGLISH) text else text,
                refHy = if (appLanguage == AppLanguage.ARMENIAN) ref else ref,
                refRu = if (appLanguage == AppLanguage.RUSSIAN) ref else ref,
                refEn = if (appLanguage == AppLanguage.ENGLISH) ref else ref
            )
            Result.success(verse)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun chatGuide(
        provider: AIProvider,
        apiKey: String,
        userQuestion: String,
        appLanguage: AppLanguage
    ): Result<String> = withContext(Dispatchers.IO) {
        val trimmedKey = apiKey.trim()
        if (trimmedKey.isEmpty()) {
            return@withContext Result.failure(Exception("API Key is empty"))
        }

        val systemInstruction = when (appLanguage) {
            AppLanguage.ARMENIAN -> "Դու բարի, իմաստուն և հոգատար քրիստոնյա աստվածաբանական օգնական ես: Պատասխանիր հարցերին Սուրբ Գրքի հիման վրա, հայերեն լեզվով, պարզ և մխիթարիչ:"
            AppLanguage.RUSSIAN -> "Ты мудрый, добрый и чуткий христианский богословский наставник. Отвечай на вопросы на основе Священного Писания, на русском языке, ясно, с любовью и утешением."
            AppLanguage.ENGLISH -> "You are a wise, kind, and compassionate Christian theological guide. Answer questions based on Holy Scripture in English, clearly, with love and comfort."
        }

        val prompt = "$systemInstruction\n\nВопрос верующего: $userQuestion"

        try {
            val response = queryModel(provider, trimmedKey, prompt)
            Result.success(response.trim())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun queryModel(provider: AIProvider, apiKey: String, prompt: String): String {
        return when (provider) {
            AIProvider.GEMINI -> {
                val endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"
                val json = JSONObject().apply {
                    put("contents", JSONArray().apply {
                        put(JSONObject().apply {
                            put("parts", JSONArray().apply {
                                put(JSONObject().apply {
                                    put("text", prompt)
                                })
                            })
                        })
                    })
                }
                val responseStr = httpPost(endpoint, json.toString(), null)
                val respJson = JSONObject(responseStr)
                val candidates = respJson.optJSONArray("candidates")
                if (candidates != null && candidates.length() > 0) {
                    val candidate = candidates.getJSONObject(0)
                    val content = candidate.optJSONObject("content")
                    val parts = content?.optJSONArray("parts")
                    if (parts != null && parts.length() > 0) {
                        return parts.getJSONObject(0).optString("text", "")
                    }
                }
                throw Exception("Invalid Gemini response format")
            }

            AIProvider.CHATGPT -> {
                val endpoint = "https://api.openai.com/v1/chat/completions"
                val json = JSONObject().apply {
                    put("model", "gpt-4o-mini")
                    put("messages", JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", prompt)
                        })
                    })
                }
                val headers = mapOf("Authorization" to "Bearer $apiKey")
                val responseStr = httpPost(endpoint, json.toString(), headers)
                val respJson = JSONObject(responseStr)
                val choices = respJson.optJSONArray("choices")
                if (choices != null && choices.length() > 0) {
                    val message = choices.getJSONObject(0).optJSONObject("message")
                    return message?.optString("content", "") ?: ""
                }
                throw Exception("Invalid OpenAI response format")
            }

            AIProvider.CLAUDE -> {
                val endpoint = "https://api.anthropic.com/v1/messages"
                val json = JSONObject().apply {
                    put("model", "claude-3-5-haiku-20241022")
                    put("max_tokens", 500)
                    put("messages", JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", prompt)
                        })
                    })
                }
                val headers = mapOf(
                    "x-api-key" to apiKey,
                    "anthropic-version" to "2023-06-01"
                )
                val responseStr = httpPost(endpoint, json.toString(), headers)
                val respJson = JSONObject(responseStr)
                val contents = respJson.optJSONArray("content")
                if (contents != null && contents.length() > 0) {
                    return contents.getJSONObject(0).optString("text", "")
                }
                throw Exception("Invalid Claude response format")
            }
        }
    }

    private fun httpPost(urlString: String, jsonBody: String, headers: Map<String, String>?): String {
        val url = URL(urlString)
        val conn = url.openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.doOutput = true
        conn.connectTimeout = 15000
        conn.readTimeout = 15000
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
        headers?.forEach { (k, v) -> conn.setRequestProperty(k, v) }

        OutputStreamWriter(conn.outputStream, "UTF-8").use { os ->
            os.write(jsonBody)
            os.flush()
        }

        val responseCode = conn.responseCode
        val isSuccess = responseCode in 200..299
        val stream = if (isSuccess) conn.inputStream else conn.errorStream
            ?: throw Exception("HTTP $responseCode: Connection failed")

        val responseText = BufferedReader(InputStreamReader(stream, "UTF-8")).use { it.readText() }

        if (!isSuccess) {
            throw Exception("HTTP $responseCode: $responseText")
        }

        return responseText
    }
}

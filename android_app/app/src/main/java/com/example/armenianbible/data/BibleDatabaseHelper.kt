package com.example.armenianbible.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

class BibleDatabaseHelper(private val context: Context) : SQLiteOpenHelper(context, DB_NAME, null, DB_VERSION) {

    companion object {
        private const val DB_NAME = "bible.db"
        private const val DB_VERSION = 1
        @Volatile private var instance: BibleDatabaseHelper? = null

        fun getInstance(context: Context): BibleDatabaseHelper {
            return instance ?: synchronized(this) {
                instance ?: BibleDatabaseHelper(context.applicationContext).also { instance = it }
            }
        }
    }

    private val dbPath: String = context.getDatabasePath(DB_NAME).path

    init {
        copyDatabaseIfNeeded()
    }

    private fun copyDatabaseIfNeeded() {
        val dbFile = File(dbPath)
        if (!dbFile.exists()) {
            dbFile.parentFile?.mkdirs()
            try {
                context.assets.open(DB_NAME).use { input ->
                    FileOutputStream(dbFile).use { output ->
                        input.copyTo(output)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase?) {}
    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {}

    fun getBooks(): List<BibleBook> {
        val books = mutableListOf<BibleBook>()
        val db = readableDatabase
        val cursor = db.rawQuery("SELECT id, name_hy, name_ru, name_en, short_name_hy, short_name_ru, short_name_en, chapters_count FROM books ORDER BY id ASC;", null)
        cursor.use { c ->
            while (c.moveToNext()) {
                val id = c.getInt(0)
                val nameHy = c.getString(1) ?: ""
                val nameRu = c.getString(2) ?: ""
                val nameEn = c.getString(3) ?: ""
                val shortNameHy = if (!c.isNull(4)) c.getString(4) else ""
                val shortNameRu = if (!c.isNull(5)) c.getString(5) else ""
                val shortNameEn = if (!c.isNull(6)) c.getString(6) else ""
                val chaptersCount = c.getInt(7)
                books.add(BibleBook(id, nameHy, nameRu, nameEn, shortNameHy, shortNameRu, shortNameEn, chaptersCount))
            }
        }
        return books
    }

    fun getBook(bookId: Int): BibleBook? {
        val db = readableDatabase
        val cursor = db.rawQuery("SELECT id, name_hy, name_ru, name_en, short_name_hy, short_name_ru, short_name_en, chapters_count FROM books WHERE id = ? LIMIT 1;", arrayOf(bookId.toString()))
        cursor.use { c ->
            if (c.moveToNext()) {
                return BibleBook(
                    c.getInt(0),
                    c.getString(1) ?: "",
                    c.getString(2) ?: "",
                    c.getString(3) ?: "",
                    if (!c.isNull(4)) c.getString(4) else "",
                    if (!c.isNull(5)) c.getString(5) else "",
                    if (!c.isNull(6)) c.getString(6) else "",
                    c.getInt(7)
                )
            }
        }
        return null
    }

    fun getChapterVerses(bookId: Int, chapter: Int): List<BibleVerseText> {
        val verses = mutableListOf<BibleVerseText>()
        val db = readableDatabase
        val cursor = db.rawQuery("SELECT id, verse, text_hy, text_ru, text_en FROM verses WHERE book_id = ? AND chapter = ? ORDER BY verse ASC;", arrayOf(bookId.toString(), chapter.toString()))
        cursor.use { c ->
            while (c.moveToNext()) {
                verses.add(
                    BibleVerseText(
                        id = c.getInt(0),
                        bookId = bookId,
                        chapter = chapter,
                        verseNumber = c.getInt(1),
                        textHy = c.getString(2) ?: "",
                        textRu = c.getString(3) ?: "",
                        textEn = c.getString(4) ?: ""
                    )
                )
            }
        }
        return verses
    }

    fun getRandomVerse(): BibleVerse? {
        val db = readableDatabase
        val query = """
            SELECT v.text_hy, v.text_ru, v.text_en, v.chapter, v.verse, b.name_hy, b.name_ru, b.name_en
            FROM verses v
            JOIN books b ON v.book_id = b.id
            ORDER BY RANDOM() LIMIT 1;
        """.trimIndent()
        val cursor = db.rawQuery(query, null)
        cursor.use { c ->
            if (c.moveToNext()) {
                val textHy = c.getString(0) ?: ""
                val textRu = c.getString(1) ?: ""
                val textEn = c.getString(2) ?: ""
                val ch = c.getInt(3)
                val v = c.getInt(4)
                val bHy = c.getString(5) ?: ""
                val bRu = c.getString(6) ?: ""
                val bEn = c.getString(7) ?: ""
                return BibleVerse(
                    textHy = textHy,
                    textRu = textRu,
                    textEn = textEn,
                    refHy = "$bHy $ch:$v",
                    refRu = "$bRu $ch:$v",
                    refEn = "$bEn $ch:$v"
                )
            }
        }
        return null
    }

    fun getRandomShortVerse(maxLength: Int = 120): BibleVerse? {
        val db = readableDatabase
        val query = """
            SELECT v.text_hy, v.text_ru, v.text_en, v.chapter, v.verse, b.name_hy, b.name_ru, b.name_en
            FROM verses v
            JOIN books b ON v.book_id = b.id
            WHERE LENGTH(v.text_hy) <= ?
            ORDER BY RANDOM() LIMIT 1;
        """.trimIndent()
        val cursor = db.rawQuery(query, arrayOf(maxLength.toString()))
        cursor.use { c ->
            if (c.moveToNext()) {
                val textHy = c.getString(0) ?: ""
                val textRu = c.getString(1) ?: ""
                val textEn = c.getString(2) ?: ""
                val ch = c.getInt(3)
                val v = c.getInt(4)
                val bHy = c.getString(5) ?: ""
                val bRu = c.getString(6) ?: ""
                val bEn = c.getString(7) ?: ""
                return BibleVerse(
                    textHy = textHy,
                    textRu = textRu,
                    textEn = textEn,
                    refHy = "$bHy $ch:$v",
                    refRu = "$bRu $ch:$v",
                    refEn = "$bEn $ch:$v"
                )
            }
        }
        return getRandomVerse()
    }

    fun searchVerses(queryText: String, language: AppLanguage): List<BibleSearchResult> {
        if (queryText.trim().length < 2) return emptyList()
        val db = readableDatabase
        val colName = when (language) {
            AppLanguage.ARMENIAN -> "text_hy"
            AppLanguage.RUSSIAN -> "text_ru"
            AppLanguage.ENGLISH -> "text_en"
        }
        val bColName = when (language) {
            AppLanguage.ARMENIAN -> "name_hy"
            AppLanguage.RUSSIAN -> "name_ru"
            AppLanguage.ENGLISH -> "name_en"
        }

        val sql = """
            SELECT v.book_id, b.$bColName, v.chapter, v.verse, v.$colName
            FROM verses v
            JOIN books b ON v.book_id = b.id
            WHERE v.$colName LIKE ?
            ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
            LIMIT 100;
        """.trimIndent()

        val results = mutableListOf<BibleSearchResult>()
        val cursor = db.rawQuery(sql, arrayOf("%${queryText.trim()}%"))
        cursor.use { c ->
            while (c.moveToNext()) {
                results.add(
                    BibleSearchResult(
                        bookId = c.getInt(0),
                        bookName = c.getString(1) ?: "",
                        chapter = c.getInt(2),
                        verseNumber = c.getInt(3),
                        text = c.getString(4) ?: ""
                    )
                )
            }
        }
        return results
    }
}

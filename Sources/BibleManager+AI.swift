import Foundation
import SwiftUI
import WidgetKit
import UserNotifications

extension BibleManager {
    
    // MARK: - Генерация цитаты через Gemini API / ChatGPT / Claude
    func generateVerseWithAI(completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .chatgpt:
            apiKey = openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude:
            apiKey = anthropicApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is empty"])))
            return
        }
        
        let prompt: String
        switch appLanguage {
        case .armenian:
            let editionNote = armenianEdition == .echmiadzin ? "Էջմիածնի դասական թարգմանությունից" : "Արարատ ժամանակակից թարգմանությունից"
            prompt = "Դու Աստվածաշնչի փորձագետ ես: Գեներացրու մեկ պատահական, ոգեշնչող, իմաստալից և գեղեցիկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (\(editionNote)): Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների կամ բազմակետերի (...): Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        case .russian:
            prompt = "Ты эксперт по Библии. Сгенерируй одну случайную, вдохновляющую, глубокую и красивую библейскую цитату на русском языке (из Синодального перевода). Пиши ПОЛНЫЙ текст цитаты без сокращений и многоточий (...). Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
        case .english:
            prompt = "You are a Bible expert. Generate one random, inspiring, meaningful, and beautiful Bible quote in English (from KJV or ESV translation). Write the COMPLETE text of the quote without abbreviations or ellipses (...). Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }
        
        isGeneratingAI = true
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (textResult, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 1024
                )
                await MainActor.run {
                    self.isGeneratingAI = false
                    let cleanResult = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
                    let components = cleanResult.components(separatedBy: "|")
                    
                    if components.count >= 2 {
                        let text = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        let reference = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"”'«»"))
                        
                        let newVerse = BibleVerse(text: text, reference: reference)
                        self.updateCurrentVerse(newVerse)
                        completion(.success(newVerse))
                    } else {
                        let cleanText = cleanResult.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        if !cleanText.isEmpty {
                            let newVerse = BibleVerse(text: cleanText, reference: NSLocalizedString("widget_title", comment: ""))
                            self.updateCurrentVerse(newVerse)
                            completion(.success(newVerse))
                        } else {
                            completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingAI = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Состояние генерации текста толкования
    @Published var isGeneratingText: Bool = false
    
    // MARK: - Общая генерация текста через ИИ (для толкований и свободных молитв)
    func generateTextFromAI(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey
        case .chatgpt:
            apiKey = openaiApiKey
        case .claude:
            apiKey = anthropicApiKey
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])))
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isGeneratingText = true
        }
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (resultText, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 2048
                )
                await MainActor.run {
                    self.isGeneratingText = false
                    completion(.success(resultText.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingText = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Подбор библейского стиха под тему / настроение пользователя
    func generateContextVerse(mood: String, customPrompt: String?, completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let targetTopic = customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (customPrompt ?? "") : mood
        
        let prompt: String
        switch appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ ես: Գտիր կամ գեներացրու մեկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (Արարատ թարգմանությունից), որը լավագույնս համապատասխանում է հետևյալ թեմային կամ տրամադրությանը՝ «\(targetTopic)»։ Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների: Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        case .russian:
            prompt = "Ты эксперт по Библии. Найди или сгенерируй одну библейскую цитату на русском языке (из Синодального перевода), которая идеально подходит под следующую тему или настроение: «\(targetTopic)». Пиши ПОЛНЫЙ текст цитаты без сокращений. Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
        case .english:
            prompt = "You are a Bible expert. Find or generate a Bible quote in English (KJV or ESV translation) that perfectly fits the following theme or mood: \"\(targetTopic)\". Write the COMPLETE text of the quote without abbreviations. Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }
        
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey
        case .chatgpt:
            apiKey = openaiApiKey
        case .claude:
            apiKey = anthropicApiKey
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])))
            }
            return
        }
        
        isGeneratingAI = true
        let provider = activeProvider
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (textResult, _) = try await AIModelRegistry.shared.executeRequest(
                    provider: provider,
                    apiKey: apiKey,
                    prompt: prompt,
                    jsonMode: false,
                    maxTokens: 1024
                )
                await MainActor.run {
                    self.isGeneratingAI = false
                    let cleanResult = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
                    let components = cleanResult.components(separatedBy: "|")
                    
                    if components.count >= 2 {
                        let text = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        let reference = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"”'«»"))
                        
                        let newVerse = BibleVerse(text: text, reference: reference)
                        self.updateCurrentVerse(newVerse)
                        completion(.success(newVerse))
                    } else {
                        let cleanText = cleanResult.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                        if !cleanText.isEmpty {
                            let newVerse = BibleVerse(text: cleanText, reference: "Armenian Bible")
                            self.updateCurrentVerse(newVerse)
                            completion(.success(newVerse))
                        } else {
                            completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingAI = false
                    let friendlyMsg = self.getFriendlyErrorMessage(for: provider, statusCode: (error as NSError).code, rawMessage: error.localizedDescription)
                    completion(.failure(NSError(domain: "BibleManager", code: (error as NSError).code, userInfo: [NSLocalizedDescriptionKey: friendlyMsg])))
                }
            }
        }
    }
    
    // MARK: - Парсинг и локализация ошибок ИИ
    func getFriendlyErrorMessage(for provider: AIProvider, statusCode: Int, rawMessage: String) -> String {
        let msg = rawMessage.lowercased()
        
        // 1. Проверяем нехватку баланса (Out of Credits)
        if msg.contains("credit balance is too low") || msg.contains("insufficient_quota") || msg.contains("billing") || msg.contains("credits") {
            switch appLanguage {
            case .armenian:
                return "Ձեր \(provider.displayName) API հաշվեկշռին բավարար միջոցներ չկան: Այս սահմանաչափը ինքնաբերաբար չի վերականգնվում, անհրաժեշտ է լիցքավորել հաշիվը \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google")) կայքում:"
            case .russian:
                return "Недостаточно средств на балансе вашего аккаунта \(provider.displayName) API. Этот лимит не восстанавливается автоматически, вам нужно пополнить баланс в личном кабинете \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google"))."
            case .english:
                return "Your \(provider.displayName) API credit balance is too low. This limit does not restore automatically; you need to top up your balance in your \(provider == .claude ? "Anthropic" : (provider == .chatgpt ? "OpenAI" : "Google")) developer dashboard."
            }
        }
        
        // 2. Проверяем лимит частоты запросов (Rate Limit)
        if msg.contains("rate limit") || msg.contains("too many requests") || msg.contains("rate_limit_exceeded") || statusCode == 429 {
            switch appLanguage {
            case .armenian:
                return "Հարցումների սահմանաչափը գերազանցվել է: Այս սահմանաչափը վերականգնվում է ինքնաբերաբար: Խնդրում ենք սպասել 1-ից 5 րոպե նորից փորձելուց առաջ:"
            case .russian:
                return "Превышен лимит запросов. Этот лимит восстанавливается автоматически. Пожалуйста, подождите от 1 до 5 минут перед повторной попыткой."
            case .english:
                return "Rate limit exceeded. This limit restores automatically. Please wait 1 to 5 minutes before trying again."
            }
        }
        
        // 3. Проверяем неверный ключ (Invalid API Key)
        if msg.contains("invalid api key") || msg.contains("invalid_api_key") || msg.contains("key is invalid") || msg.contains("authentication") || msg.contains("unauthorized") || statusCode == 401 {
            switch appLanguage {
            case .armenian:
                return "Անվավեր API բանալի: Խնդրում ենք ստուգել բանալու ճշտությունը հավելվածի Կարգավորումներում:"
            case .russian:
                return "Неверный API-ключ. Проверьте правильность ввода ключа в Настройках приложения."
            case .english:
                return "Invalid API Key. Please check the correctness of the key in the app Settings."
            }
        }
        
        // По умолчанию возвращаем исходное сообщение от провайдера
        return "\(provider.displayName) API: \(rawMessage)"
    }
    
    // MARK: - Духовный ответчик ИИ по Библии
    func askBibleAI(question: String, completion: @escaping (Result<BibleAnswer, Error>) -> Void) {
        let toneGuidance = aiTheologicalTone.promptGuidance(for: appLanguage)
        let prompt: String
        switch appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ և հոգևոր առաջնորդ ես: Օգտատերը հարցնում է. «\(question)»: \(toneGuidance) Տուր մանրամասն, իմաստուն և մխիթարական պատասխան հայերեն լեզվով՝ հիմնված Սուրբ Գրքի վրա: Պատասխանի վերջում անպայման բեր մեկ հիմնական աստվածաշնչյան տող հետևյալ ճշգրիտ ֆորմատով՝\nVERSE_START\n[Տեքստ] | [Հղում]\nVERSE_END"
        case .russian:
            prompt = "Ты эксперт по Библии и духовный наставник. Пользователь спрашивает: «\(question)». \(toneGuidance) Дай подробный, мудрый и поддерживающий ответ на русском языке, основанный на Священном Писании. В самом конце ответа обязательно приведи один ключевой библейский стих в следующем точном формате:\nVERSE_START\n[Текст стиха] | [Ссылка на стих]\nVERSE_END"
        case .english:
            prompt = "You are a Bible expert and spiritual guide. The user asks: \"\(question)\". \(toneGuidance) Provide a detailed, wise, and comforting answer in English based on the Holy Scriptures. At the very end of your response, include one key Bible verse in the following exact format:\nVERSE_START\n[Verse Text] | [Reference]\nVERSE_END"
        }
        
        generateTextFromAI(prompt: prompt) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fullText):
                var answerText = fullText
                var verse: BibleVerse? = nil
                
                if let startRange = fullText.range(of: "VERSE_START"),
                   let endRange = fullText.range(of: "VERSE_END") {
                    
                    answerText = String(fullText[..<startRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let verseContent = String(fullText[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let components = verseContent.components(separatedBy: "|")
                    if components.count >= 2 {
                        let vText = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let vRef = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        verse = BibleVerse(
                            textHy: self.appLanguage == .armenian ? vText : "",
                            textRu: self.appLanguage == .russian ? vText : "",
                            textEn: self.appLanguage == .english ? vText : "",
                            refHy: self.appLanguage == .armenian ? vRef : "",
                            refRu: self.appLanguage == .russian ? vRef : "",
                            refEn: self.appLanguage == .english ? vRef : ""
                        )
                    }
                }
                DispatchQueue.main.async {
                    completion(.success(BibleAnswer(answerText: answerText, verse: verse)))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Управление богословским тоном ИИ
    func setAITheologicalTone(_ tone: AITheologicalTone) {
        self.aiTheologicalTone = tone
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(tone.rawValue, forKey: aiTheologicalToneKey)
        triggerHapticNotification(.success)
        objectWillChange.send()
    }
    
    // MARK: - Управление настройками викторины
    func setQuizDefaultQuestionCount(_ count: Int) {
        self.quizDefaultQuestionCount = count
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(count, forKey: quizDefaultQuestionCountKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    func setQuizTimerDuration(_ duration: Int) {
        self.quizTimerDuration = duration
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(duration, forKey: quizTimerDurationKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    func setQuizSoundEffectsEnabled(_ enabled: Bool) {
        self.quizSoundEffectsEnabled = enabled
        let defaults = sharedDefaults ?? UserDefaults.standard
        defaults.set(enabled, forKey: quizSoundEffectsEnabledKey)
        triggerHapticImpact(.light)
        objectWillChange.send()
    }
    
    @MainActor
    func resetQuizFullStats() {
        self.quizBestScore = 0
        if let defaults = sharedDefaults {
            defaults.set(0, forKey: "quiz_best_score")
        }
        QuizAdaptiveDiary.shared.resetDiary()
        AchievementsManager.shared.resetQuizStatistics()
        triggerHapticNotification(.success)
        objectWillChange.send()
    }
    
    // MARK: - Управление рекордами Викторины
    func updateQuizBestScore(_ score: Int) {
        if score > quizBestScore {
            quizBestScore = score
            if let defaults = sharedDefaults {
                defaults.set(score, forKey: "quiz_best_score")
            }
        }
    }
    
    // MARK: - Управление Заметками, Тегами и Маркерами (Annotations, Notes, Tags & Highlighters)
    func annotation(bookId: Int, chapter: Int, verseNumber: Int) -> VerseAnnotation? {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        return annotations[key]
    }
    
    func saveAnnotation(_ item: VerseAnnotation) {
        let key = item.key
        if item.hasContent {
            annotations[key] = item
            if let color = item.colorHex {
                highlightedVerses[key] = color
            } else {
                highlightedVerses.removeValue(forKey: key)
            }
        } else {
            annotations.removeValue(forKey: key)
            highlightedVerses.removeValue(forKey: key)
        }
        
        persistAnnotations()
        objectWillChange.send()
    }
    
    func deleteAnnotation(bookId: Int, chapter: Int, verseNumber: Int) {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        annotations.removeValue(forKey: key)
        highlightedVerses.removeValue(forKey: key)
        persistAnnotations()
        objectWillChange.send()
    }
    
    private func persistAnnotations() {
        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(annotations) {
            defaults.set(encoded, forKey: "verse_annotations_map")
        }
        defaults.set(highlightedVerses, forKey: "highlighted_verses_map")
        defaults.synchronize()
    }
    
    var allAnnotations: [VerseAnnotation] {
        annotations.values.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func setHighlight(
        bookId: Int,
        chapter: Int,
        verseNumber: Int,
        colorHex: String?,
        bookNameHy: String = "",
        bookNameRu: String = "",
        bookNameEn: String = "",
        textHy: String = "",
        textHyArarat: String = "",
        textRu: String = "",
        textEn: String = ""
    ) {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        var item = annotations[key] ?? VerseAnnotation(
            bookId: bookId,
            chapter: chapter,
            verseNumber: verseNumber,
            bookNameHy: bookNameHy,
            bookNameRu: bookNameRu,
            bookNameEn: bookNameEn,
            textHy: textHy,
            textHyArarat: textHyArarat,
            textRu: textRu,
            textEn: textEn
        )
        item.colorHex = colorHex
        if !bookNameHy.isEmpty {
            item = VerseAnnotation(
                id: item.id,
                bookId: bookId,
                chapter: chapter,
                verseNumber: verseNumber,
                bookNameHy: bookNameHy,
                bookNameRu: bookNameRu,
                bookNameEn: bookNameEn,
                textHy: textHy,
                textHyArarat: textHyArarat.isEmpty ? item.textHyArarat : textHyArarat,
                textRu: textRu,
                textEn: textEn,
                colorHex: colorHex,
                note: item.note,
                tags: item.tags,
                updatedAt: Date()
            )
        }
        saveAnnotation(item)
    }
    
    func highlightColor(bookId: Int, chapter: Int, verseNumber: Int) -> String? {
        let key = "\(bookId)_\(chapter)_\(verseNumber)"
        if let annColor = annotations[key]?.colorHex, !annColor.isEmpty {
            return annColor
        }
        return highlightedVerses[key]
    }
    
    // MARK: - Молитва дня и статус выполнения (Widget & Lockscreen)
    func checkPrayerCompletionStatus() {
        let defaults = AppGroupConstants.sharedDefaults
        if let lastDate = defaults.object(forKey: "daily_prayer_completed_date") as? Date {
            let isToday = Calendar.current.isDateInToday(lastDate)
            self.isPrayerCompletedToday = isToday
        } else {
            self.isPrayerCompletedToday = false
        }
    }
    
    func togglePrayerCompletedToday() {
        let newValue = !isPrayerCompletedToday
        isPrayerCompletedToday = newValue
        AppGroupConstants.syncToAll { defaults in
            if newValue {
                defaults.set(Date(), forKey: "daily_prayer_completed_date")
            } else {
                defaults.removeObject(forKey: "daily_prayer_completed_date")
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        objectWillChange.send()
    }
    
    // MARK: - Закрепление стиха на Виджете
    func pinVerseToWidget(textHy: String, textRu: String, textEn: String, refHy: String, refRu: String, refEn: String) {
        let baseVerse = BibleVerse(textHy: textHy, textRu: textRu, textEn: textEn, refHy: refHy, refRu: refRu, refEn: refEn)
        let enriched = BibleDatabase.shared.enrichVerse(baseVerse)
        
        AppGroupConstants.syncToAll { defaults in
            defaults.set(enriched.text(for: .armenian), forKey: "currentVerseTextHy")
            defaults.set(enriched.textHy, forKey: "currentVerseTextHyEchmiadzin")
            defaults.set(enriched.textHyArarat, forKey: "currentVerseTextHyArarat")
            defaults.set(enriched.textRu, forKey: "currentVerseTextRu")
            defaults.set(enriched.textEn, forKey: "currentVerseTextEn")
            
            defaults.set(enriched.refHy, forKey: "currentVerseReferenceHy")
            defaults.set(enriched.refRu, forKey: "currentVerseReferenceRu")
            defaults.set(enriched.refEn, forKey: "currentVerseReferenceEn")
            
            // Устанавливаем текущий текст в зависимости от языка приложения
            switch appLanguage {
            case .armenian:
                defaults.set(enriched.text(for: .armenian), forKey: textKey)
                defaults.set(enriched.refHy, forKey: referenceKey)
            case .russian:
                defaults.set(enriched.textRu, forKey: textKey)
                defaults.set(enriched.refRu, forKey: referenceKey)
            case .english:
                defaults.set(enriched.textEn, forKey: textKey)
                defaults.set(enriched.refEn, forKey: referenceKey)
            }
        }
        self.currentVerse = enriched
        
        WidgetCenter.shared.reloadAllTimelines()
        objectWillChange.send()
    }
}

// MARK: - Армянский редактор текста Библии
enum ArmenianBibleEdition: String, CaseIterable, Identifiable, Codable {
    case ararat = "ararat"
    case echmiadzin = "echmiadzin"
    case grabar = "grabar"
    
    var id: String { rawValue }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .ararat:
            return "edition_ararat_title".localized(for: language)
        case .echmiadzin:
            return "edition_echmiadzin_title".localized(for: language)
        case .grabar:
            return "edition_grabar_title".localized(for: language)
        }
    }
}


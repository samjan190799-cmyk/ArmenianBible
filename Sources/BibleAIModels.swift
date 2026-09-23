import Foundation
import SwiftUI

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

// MARK: - Ответ Библейского ИИ
struct BibleAnswer {
    let answerText: String
    let verse: BibleVerse?
}

// MARK: - Сообщение в чате Духовного Помощника
struct AIChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let isUser: Bool
    let text: String
    let verse: BibleVerse?
    let timestamp: Date
    
    init(id: UUID = UUID(), isUser: Bool, text: String, verse: BibleVerse? = nil, timestamp: Date = Date()) {
        self.id = id
        self.isUser = isUser
        self.text = text
        self.verse = verse
        self.timestamp = timestamp
    }
}

// MARK: - Богословский тон ответов ИИ
enum AITheologicalTone: String, CaseIterable, Identifiable, Codable {
    case patristic = "patristic"
    case pastoral = "pastoral"
    case historical = "historical"
    case simple = "simple"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .patristic: return "cross.fill"
        case .pastoral: return "heart.fill"
        case .historical: return "book.fill"
        case .simple: return "sun.max.fill"
        }
    }
    var iconName: String { icon }
    
    var colorHex: String {
        switch self {
        case .patristic: return "D97706"
        case .pastoral: return "EC4899"
        case .historical: return "3B82F6"
        case .simple: return "10B981"
        }
    }
    var accentColorHex: String { colorHex }
    
    func title(for lang: AppLanguage) -> String { localizedTitle(for: lang) }
    func description(for lang: AppLanguage) -> String { localizedDesc(for: lang) }
    
    func localizedTitle(for lang: AppLanguage) -> String {
        switch self {
        case .patristic: return "ai_tone_patristic".localized(for: lang)
        case .pastoral: return "ai_tone_pastoral".localized(for: lang)
        case .historical: return "ai_tone_historical".localized(for: lang)
        case .simple: return "ai_tone_simple".localized(for: lang)
        }
    }
    
    func localizedDesc(for lang: AppLanguage) -> String {
        switch self {
        case .patristic: return "ai_tone_patristic_desc".localized(for: lang)
        case .pastoral: return "ai_tone_pastoral_desc".localized(for: lang)
        case .historical: return "ai_tone_historical_desc".localized(for: lang)
        case .simple: return "ai_tone_simple_desc".localized(for: lang)
        }
    }
    
    func promptGuidance(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.patristic, .armenian):
            return "Հատուկ ուշադրություն դարձրու Հայ Առաքելական Սուրբ Եկեղեցու հայրերի և վարդապետների (Գրիգոր Լուսավորիչ, Գրիգոր Նարեկացի, Ներսես Շնորհալի) ավանդությանը:"
        case (.patristic, .russian):
            return "Придерживайся святоотеческого толкования и древней традиции Армянской Апостольской Церкви и святых вардапетов (св. Григор Просветитель, св. Григор Нарекаци, св. Нерсес Шнорали)."
        case (.patristic, .english):
            return "Adhere to the patristic interpretations and the ancient sacred tradition of the Armenian Apostolic Church and holy vardapets (St. Gregory the Illuminator, St. Gregory of Narek, St. Nerses the Gracious)."
            
        case (.pastoral, .armenian):
            return "Պատասխանիր հոգևոր հոգատարությամբ, ջերմությամբ և քաջալերանքով՝ շեշտելով հոգևոր մխիթարությունն ու գործնական կիրառումը քրիստոնեական կյանքում:"
        case (.pastoral, .russian):
            return "Отвечай пастырски, тепло и ободряюще, делая главный акцент на духовном утешении, укреплении веры и практическом применении в христианской жизни."
        case (.pastoral, .english):
            return "Provide a pastoral, warm, and uplifting response emphasizing personal spiritual life, faith strengthening, and comforting guidance."
            
        case (.historical, .armenian):
            return "Մանրամասն ներկայացրու գրքի պատմական, աստվածաբանական և մշակութային համատեքստը՝ անդրադառնալով բնագրի լեզվին և իմաստային շերտերին:"
        case (.historical, .russian):
            return "Раскрой исторический, богословский и культурный контекст книги и стихов, уделяя особое внимание языку оригинала, эпохе и экзегетическому смыслу Писания."
        case (.historical, .english):
            return "Explore the historical, theological, and cultural context, noting original language nuances, historical era, and biblical exegesis."
            
        case (.simple, .armenian):
            return "Բացատրիր հնարավորինս պարզ, մատչելի և հասկանալի լեզվով՝ առանց բարդ տերմինների, նրանց համար, ովքեր նոր են սկսում ծանոթանալ Սուրբ Գրքին:"
        case (.simple, .russian):
            return "Объясняй максимально просто, тепло и доступно, избегая перегруженных терминов, специально для тех, кто только начинает читать и постигать Священное Писание."
        case (.simple, .english):
            return "Explain simply, clearly, and accessibly without complex theological jargon, specifically tailored for beginners exploring Holy Scripture."
        }
    }
}

import Foundation

// MARK: - Навигационные состояния

enum BibleNavigationState: Hashable {
    case reader(book: BibleBook, chapter: Int, targetVerse: Int?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .reader(let book, let chapter, let verse):
            hasher.combine("reader")
            hasher.combine(book.id)
            hasher.combine(chapter)
            hasher.combine(verse)
        }
    }
    
    static func == (lhs: BibleNavigationState, rhs: BibleNavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.reader(let b1, let c1, let v1), .reader(let b2, let c2, let v2)):
            return b1.id == b2.id && c1 == c2 && v1 == v2
        default:
            return false
        }
    }
}


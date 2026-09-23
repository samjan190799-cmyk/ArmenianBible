import Foundation
import SwiftUI

extension BibleVerse {
    // MARK: - 6. ⚓ Короткие стихи о Вере и Мужестве (PRO) — до 45 символов
    static let shortFaith: [BibleVerse] = [
        BibleVerse(
            textHy: "Հավատքո՛վ ենք ընթանում։",
            textRu: "Мы ходим верою, а не видением.",
            textEn: "For we walk by faith, not by sight.",
            refHy: "Բ Կորնթացիս 5:7",
            refRu: "2 Коринфянам 5:7",
            refEn: "2 Corinthians 5:7"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, միայն հավատա՛։",
            textRu: "Не бойся, только веруй.",
            textEn: "Be not afraid, only believe.",
            refHy: "Մարկոս 5:36",
            refRu: "Марка 5:36",
            refEn: "Mark 5:36"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ հնարավոր է հավատացողին։",
            textRu: "Все возможно верующему.",
            textEn: "All things are possible to him that believeth.",
            refHy: "Մարկոս 9:23",
            refRu: "Марка 9:23",
            refEn: "Mark 9:23"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսով։",
            textRu: "Все могу в укрепляющем меня Христе.",
            textEn: "I can do all things through Christ.",
            refHy: "Փիլիպպեցիներին 4:13",
            refRu: "Филиппийцам 4:13",
            refEn: "Philippians 4:13"
        ),
        BibleVerse(
            textHy: "Հավատը հուսացված բաների հաստատումն է։",
            textRu: "Вера есть уверенность в невидимом.",
            textEn: "Faith is the substance of things hoped for.",
            refHy: "Եբրայեցիս 11:1",
            refRu: "Евреям 11:1",
            refEn: "Hebrews 11:1"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, քանզի ես քեզ հետ եմ։",
            textRu: "Не бойся, ибо Я с тобою; Я Бог твой.",
            textEn: "Fear thou not; for I am with thee.",
            refHy: "Եսայի 41:10",
            refRu: "Исаия 41:10",
            refEn: "Isaiah 41:10"
        ),
        BibleVerse(
            textHy: "Տիրոջն ապավինողները կնորոգվեն ուժով։",
            textRu: "Надеющиеся на Господа обновятся в силе.",
            textEn: "They that wait upon the Lord renew strength.",
            refHy: "Եսայի 40:31",
            refRu: "Исаия 40:31",
            refEn: "Isaiah 40:31"
        ),
        BibleVerse(
            textHy: "Զորացե՛ք Տիրոջով և Նրա զորության կարողությամբ։",
            textRu: "Укрепляйтесь Господом и силою Его.",
            textEn: "Be strong in the Lord and in His power.",
            refHy: "Եփեսացիս 6:10",
            refRu: "Ефесянам 6:10",
            refEn: "Ephesians 6:10"
        ),
        BibleVerse(
            textHy: "Զորացի՛ր և քա՛ջ եղիր, Տերը քեզ հետ է։",
            textRu: "Будь тверд и мужествен, Господь с тобою.",
            textEn: "Be strong and courageous; God is with thee.",
            refHy: "Հեսու 1:9",
            refRu: "Иисус Навин 1:9",
            refEn: "Joshua 1:9"
        ),
        BibleVerse(
            textHy: "Հավատարիմ է Խոստացողը։",
            textRu: "Будем держаться веры, ибо верен Обещавший.",
            textEn: "Hold fast our faith, for He is faithful.",
            refHy: "Եբրայեցիս 10:23",
            refRu: "Евреям 10:23",
            refEn: "Hebrews 10:23"
        ),
        BibleVerse(
            textHy: "Եթե Աստված մեր կողմն է, ո՞վ է մեզ հակառակ։",
            textRu: "Если Бог за нас, кто против нас?",
            textEn: "If God be for us, who can be against us?",
            refHy: "Հռոմեացիս 8:31",
            refRu: "Римлянам 8:31",
            refEn: "Romans 8:31"
        ),
        BibleVerse(
            textHy: "Աստված մեզ զորության և սիրո ոգի տվեց։",
            textRu: "Дал нам Бог духа силы, любви и целомудрия.",
            textEn: "God gave us the spirit of power and of love.",
            refHy: "Բ Տիմոթեոս 1:7",
            refRu: "2 Тимофею 1:7",
            refEn: "2 Timothy 1:7"
        )
    ]

    /// Обратная совместимость для виджетов и представлений
    static var lockScreenPearls: [BibleVerse] {
        return shortPearls
    }

    /// Получение строго уникального массива коротких стихов для выбранной категории экрана блокировки
    static func lockScreenVerses(for category: LockScreenCategory) -> [BibleVerse] {
        switch category {
        case .pearls:
            return shortPearls
        case .narekatsi:
            return shortNarekatsi
        case .psalms:
            return shortPsalms
        case .wisdom:
            return shortWisdom
        case .love:
            return shortLove
        case .faith:
            return shortFaith
        }
    }

}

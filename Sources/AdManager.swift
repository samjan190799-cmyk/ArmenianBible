import Foundation

// MARK: - Обратная совместимость AdManager -> LuysAdManager
/// Вся логика монетизации, гео-роутинга и показа рекламы перенесена в `LuysAdManager`
/// с поддержкой Yandex Mobile Ads v8.x, Swift 6 Concurrency и багфиксом удержания RewardedAd.
///
/// Псевдоним `public typealias AdManager = LuysAdManager` определен в `LuysAdManager.swift`.

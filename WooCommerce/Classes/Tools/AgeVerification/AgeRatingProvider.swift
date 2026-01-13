import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

/// Abstraction over how we obtain the app's age rating code (e.g., via StoreKit).
protocol AgeRatingProviding {
    /// Returns the current age rating code if available.
    func currentAgeRating() async -> Int?
}

/// StoreKit-backed age rating provider.
final class StoreKitAgeRatingProvider: AgeRatingProviding {
    func currentAgeRating() async -> Int? {
        #if canImport(StoreKit)
        if #available(iOS 26.2, *) {
            return await AppStore.ageRatingCode
        }
        #endif
        return nil
    }
}

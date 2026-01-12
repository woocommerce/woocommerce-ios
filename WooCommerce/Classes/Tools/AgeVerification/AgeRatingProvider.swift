import Foundation
import CocoaLumberjack
#if canImport(StoreKit)
import StoreKit
#endif

/// Abstraction over how we obtain the app's age rating (e.g., via StoreKit).
protocol AgeRatingProviding {
    /// Returns the current age rating string (for example, "17+") if available.
    func currentAgeRating() async throws -> String?
}

/// StoreKit-backed age rating provider (stubbed until the SDK property is available).
final class StoreKitAgeRatingProvider: AgeRatingProviding {
    func currentAgeRating() async throws -> String? {
        #if canImport(StoreKit)
        if #available(iOS 26.2, *) {
            // TODO: Read the StoreKit age rating property when available in the SDK.
            DDLogInfo("AgeRatingProvider: StoreKit age rating not yet wired; returning nil.")
            return nil
        }
        #endif
        return nil
    }
}

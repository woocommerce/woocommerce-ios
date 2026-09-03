import Foundation

/// Result emitted when the app's age rating changes on device.
enum AgeRatingChangeCheckResult: Equatable {
    case ageRatingChanged(previous: Int?, current: Int)
}

/// Detector that tracks the last acknowledged age rating and reports when the current one differs.
///
/// Detection is intentionally non-consuming: `checkForChange()` never writes the cache, so an
/// unresolved change (consent pending or denied) is re-reported on every launch until the consent
/// flow acknowledges it via `acknowledge(ratingCode:)`.
final class AgeRatingChangeDetector: AgeRatingChangeDetecting {
    private enum Key {
        static let lastSeenAgeRating = "ageRatingChangeDetector.lastSeenAgeRating"
    }

    private let defaults: UserDefaults
    private let provider: AgeRatingProviding

    init(
        defaults: UserDefaults = .standard,
        provider: AgeRatingProviding = StoreKitAgeRatingProvider()
    ) {
        self.defaults = defaults
        self.provider = provider
    }

    @discardableResult
    func checkForChange() async -> AgeRatingChangeCheckResult? {
        guard let ratingCode = await provider.currentAgeRating() else {
            return nil
        }
        guard let previous = cachedAgeRatingCode() else {
            // First observation is the baseline, not a change: consent for the download itself
            // was already handled by the App Store, so only later rating increases need consent.
            cacheAgeRatingCode(ratingCode)
            return nil
        }
        guard previous != ratingCode else { return nil }
        return .ageRatingChanged(previous: previous, current: ratingCode)
    }

    func acknowledge(ratingCode: Int) {
        cacheAgeRatingCode(ratingCode)
    }

    /// Clears the acknowledged-rating cache so the next check re-baselines. Debug/testing helper.
    static func resetCache(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Key.lastSeenAgeRating)
    }
}

private extension AgeRatingChangeDetector {
    func cachedAgeRatingCode() -> Int? {
        defaults.value(forKey: Key.lastSeenAgeRating) as? Int
    }

    func cacheAgeRatingCode(_ code: Int) {
        defaults.set(code, forKey: Key.lastSeenAgeRating)
    }
}

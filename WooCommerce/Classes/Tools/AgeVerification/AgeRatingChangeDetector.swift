import Foundation

/// Result emitted when the app's age rating changes on device.
enum AgeRatingChangeCheckResult: Equatable {
    case ageRatingChanged(previous: Int?, current: Int)
}

/// Lightweight detector that tracks the last seen age rating and reports when it changes.
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

    /// Fetches the latest age rating code via the injected provider and reports a change event if detected.
    @discardableResult
    func checkForChange() async -> AgeRatingChangeCheckResult? {
        guard let ratingCode = await provider.currentAgeRating() else {
            return nil
        }
        return process(ageRatingCode: ratingCode)
    }
}

private extension AgeRatingChangeDetector {
    func cachedAgeRatingCode() -> Int? {
        defaults.value(forKey: Key.lastSeenAgeRating) as? Int
    }

    func cacheAgeRatingCode(_ code: Int) {
        defaults.set(code, forKey: Key.lastSeenAgeRating)
    }

    /// Processes a new age rating code and returns a result if it differs from the last seen value.
    func process(ageRatingCode: Int) -> AgeRatingChangeCheckResult? {
        let previous = cachedAgeRatingCode()
        guard previous != ageRatingCode else { return nil }

        cacheAgeRatingCode(ageRatingCode)
        return .ageRatingChanged(previous: previous, current: ageRatingCode)
    }
}

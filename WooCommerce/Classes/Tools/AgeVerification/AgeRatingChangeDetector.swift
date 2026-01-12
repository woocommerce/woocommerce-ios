import Foundation
import CocoaLumberjack

/// Event emitted when the app's age rating changes on device.
enum AgeRatingChangeEvent: Equatable {
    case ageRatingChanged(previous: Int?, current: Int)
}

/// Lightweight detector that tracks the last seen age rating and reports when it changes.
final class AgeRatingChangeDetector {
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
    func checkForChange() async -> AgeRatingChangeEvent? {
        guard let ratingCode = await provider.currentAgeRating() else {
            return nil
        }
        return process(ageRatingCode: ratingCode)
    }
}

private extension AgeRatingChangeDetector {
    /// Processes a new age rating code and returns an event if it differs from the last seen value.
    func process(ageRatingCode: Int) -> AgeRatingChangeEvent? {
        let previous = defaults.value(forKey: Key.lastSeenAgeRating) as? Int
        guard previous != ageRatingCode else { return nil }

        defaults.set(ageRatingCode, forKey: Key.lastSeenAgeRating)
        return .ageRatingChanged(previous: previous, current: ageRatingCode)
    }
}

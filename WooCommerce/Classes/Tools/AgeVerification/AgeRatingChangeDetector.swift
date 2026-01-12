import Foundation
import CocoaLumberjack

/// Event emitted when the app's age rating changes on device.
enum AgeRatingChangeEvent: Equatable {
    case ageRatingChanged(previous: String?, current: String)
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

    /// Fetches the latest age rating via the injected provider and reports a change event if detected.
    @discardableResult
    func checkForChange() async -> AgeRatingChangeEvent? {
        do {
            guard let rating = try await provider.currentAgeRating(), rating.isEmpty == false else {
                return nil
            }
            return process(ageRating: rating)
        } catch {
            DDLogError("AgeRatingChangeDetector: Failed to fetch age rating. Error: \(error)")
            return nil
        }
    }

    /// Processes a new age rating string and returns an event if it differs from the last seen value.
    /// Empty strings are ignored.
    func process(ageRating: String) -> AgeRatingChangeEvent? {
        guard ageRating.isEmpty == false else { return nil }

        let previous = defaults.string(forKey: Key.lastSeenAgeRating)
        guard previous != ageRating else { return nil }

        defaults.set(ageRating, forKey: Key.lastSeenAgeRating)
        return .ageRatingChanged(previous: previous, current: ageRating)
    }
}

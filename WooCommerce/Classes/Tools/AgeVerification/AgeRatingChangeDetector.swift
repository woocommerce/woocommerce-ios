import Foundation

/// Event emitted when the app's age rating changes on device.
enum AgeRatingChangeEvent: Equatable {
    case ageRatingChanged(previous: String?, current: String)
}

/// Lightweight detector that tracks the last seen age rating and reports when it changes.
///
/// This is intentionally decoupled from StoreKit; callers supply the latest age rating
/// (e.g., read from StoreKit's age rating property). The detector persists the last
/// value to avoid duplicate events.
final class AgeRatingChangeDetector {
    private enum Key {
        static let lastSeenAgeRating = "ageRatingChangeDetector.lastSeenAgeRating"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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


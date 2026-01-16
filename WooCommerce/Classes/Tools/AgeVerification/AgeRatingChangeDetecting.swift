import Foundation

enum AgeRatingChangeCheckResult: Equatable {
    case ageRatingChanged(previous: Int?, current: Int)
}

protocol AgeRatingChangeDetecting {
    func checkForChange() async -> AgeRatingChangeCheckResult?
}

/// Fallback detector used until the age rating change detector is merged.
struct NoOpAgeRatingChangeDetector: AgeRatingChangeDetecting {
    func checkForChange() async -> AgeRatingChangeCheckResult? {
        nil
    }
}

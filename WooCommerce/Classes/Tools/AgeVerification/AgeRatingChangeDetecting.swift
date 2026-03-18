import Foundation

protocol AgeRatingChangeDetecting {
    func checkForChange() async -> AgeRatingChangeCheckResult?
}

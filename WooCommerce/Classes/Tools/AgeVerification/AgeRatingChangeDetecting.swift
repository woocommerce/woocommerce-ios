import Foundation

protocol AgeRatingChangeDetecting {
    /// Returns the outstanding age rating change, if any, without acknowledging it.
    /// The same change keeps being reported until `acknowledge(ratingCode:)` is called,
    /// so a pending or denied consent survives app relaunches.
    func checkForChange() async -> AgeRatingChangeCheckResult?

    /// Marks the given rating code as handled (e.g. consent granted), so it is no longer
    /// reported as a change.
    func acknowledge(ratingCode: Int)
}

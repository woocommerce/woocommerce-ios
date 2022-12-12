import Foundation

/// Analytics Hub Time Range Card ViewModel.
/// Used to transmit analytics time range data.
///
struct AnalyticsTimeRangeCardViewModel {
    /// Time Range Title.
    ///
    let selectedRangeTitle: String

    /// Current Range Subtitle.
    ///
    let currentRangeSubtitle: String

    /// Previous Range Subtitle.
    ///
    let previousRangeSubtitle: String

    /// Analytics Usage Tracks Event Emitter
    ///
    let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
}

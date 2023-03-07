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

    /// Closure invoked when the time range card is tapped.
    ///
    var onTapped: () -> Void = {}

    /// Closure invoked when a time range is selected.
    ///
    var onSelected: (AnalyticsTimeRangeCard.Range) -> Void = { _ in }
}

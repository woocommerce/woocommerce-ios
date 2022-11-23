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
}

/// Convenience extension to create an `AnalyticsTimeRangeCard` from a view model.
///
extension AnalyticsTimeRangeCard {
    init(viewModel: AnalyticsTimeRangeCardViewModel) {
        self.timeRangeTitle = viewModel.selectedRangeTitle
        self.currentRangeDescription = viewModel.currentRangeSubtitle
        self.previousRangeDescription = viewModel.previousRangeSubtitle
    }
}

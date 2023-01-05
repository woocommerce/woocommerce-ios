import Foundation

/// Analytics Hub Report Card Current Period ViewModel.
/// Used to transmit analytics report data for the current period (no comparison to previous periods).
///
struct AnalyticsReportCardCurrentPeriodViewModel {
    /// Report Card Title.
    ///
    let title: String

    /// First Column Title
    ///
    let leadingTitle: String

    /// First Column Value
    ///
    let leadingValue: String

    /// Second Column Title
    ///
    let trailingTitle: String

    /// Second Column Value
    ///
    let trailingValue: String

    /// Indicates if the values should be hidden (for loading state)
    ///
    let isRedacted: Bool

    /// Indicates if there was an error loading the data for the card
    ///
    let showSyncError: Bool

    /// Message to display if there was an error loading the data for the card
    ///
    let syncErrorMessage: String
}

extension AnalyticsReportCardCurrentPeriodViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(title: title,
              leadingTitle: leadingTitle,
              leadingValue: "$1000",
              trailingTitle: trailingTitle,
              trailingValue: "$1000",
              isRedacted: true,
              showSyncError: false,
              syncErrorMessage: "")
    }
}

/// Convenience extension to create an `AnalyticsReportCard` from a view model.
///
extension AnalyticsReportCard {
    init(viewModel: AnalyticsReportCardCurrentPeriodViewModel) {
        self.title = viewModel.title
        self.leadingTitle = viewModel.leadingTitle
        self.leadingValue = viewModel.leadingValue
        self.leadingDelta = nil
        self.leadingDeltaColor = nil
        self.leadingDeltaTextColor = nil
        self.leadingChartData = []
        self.leadingChartColor = nil
        self.trailingTitle = viewModel.trailingTitle
        self.trailingValue = viewModel.trailingValue
        self.trailingDelta = nil
        self.trailingDeltaColor = nil
        self.trailingDeltaTextColor = nil
        self.trailingChartData = []
        self.trailingChartColor = nil
        self.isRedacted = viewModel.isRedacted
        self.showSyncError = viewModel.showSyncError
        self.syncErrorMessage = viewModel.syncErrorMessage
    }
}

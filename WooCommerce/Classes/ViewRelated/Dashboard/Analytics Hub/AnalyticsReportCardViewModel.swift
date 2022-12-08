import Foundation
import class UIKit.UIColor

/// Analytics Hub Report Card ViewModel.
/// Used to transmit analytics report data.
///
struct AnalyticsReportCardViewModel {
    /// Report Card Title.
    ///
    let title: String

    /// First Column Title
    ///
    let leadingTitle: String

    /// First Column Value
    ///
    let leadingValue: String

    /// First Column Delta Percentage
    ///
    let leadingDelta: DeltaPercentage

    /// First Column Chart Data
    ///
    let leadingChartData: [Double]

    /// Second Column Title
    ///
    let trailingTitle: String

    /// Second Column Value
    ///
    let trailingValue: String

    /// Second Column Delta Percentage
    ///
    let trailingDelta: DeltaPercentage

    /// Second Column Chart Data
    ///
    let trailingChartData: [Double]

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

extension AnalyticsReportCardViewModel {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    var redacted: Self {
        // Values here are placeholders and will be redacted in the UI
        .init(title: title,
              leadingTitle: leadingTitle,
              leadingValue: "$1000",
              leadingDelta: DeltaPercentage(string: "0%", direction: .zero),
              leadingChartData: [],
              trailingTitle: trailingTitle,
              trailingValue: "$1000",
              trailingDelta: DeltaPercentage(string: "0%", direction: .zero),
              trailingChartData: [],
              isRedacted: true,
              showSyncError: false,
              syncErrorMessage: "")
    }
}

/// Convenience extension to create an `AnalyticsReportCard` from a view model.
///
extension AnalyticsReportCard {
    init(viewModel: AnalyticsReportCardViewModel) {
        self.title = viewModel.title
        self.leadingTitle = viewModel.leadingTitle
        self.leadingValue = viewModel.leadingValue
        self.leadingDelta = viewModel.leadingDelta.string
        self.leadingDeltaColor = viewModel.leadingDelta.direction.deltaBackgroundColor
        self.leadingDeltaTextColor = viewModel.leadingDelta.direction.deltaTextColor
        self.leadingChartData = viewModel.leadingChartData
        self.leadingChartColor = viewModel.leadingDelta.direction.chartColor
        self.trailingTitle = viewModel.trailingTitle
        self.trailingValue = viewModel.trailingValue
        self.trailingDelta = viewModel.trailingDelta.string
        self.trailingDeltaColor = viewModel.trailingDelta.direction.deltaBackgroundColor
        self.trailingDeltaTextColor = viewModel.trailingDelta.direction.deltaTextColor
        self.trailingChartData = viewModel.trailingChartData
        self.trailingChartColor = viewModel.trailingDelta.direction.chartColor
        self.isRedacted = viewModel.isRedacted
        self.showSyncError = viewModel.showSyncError
        self.syncErrorMessage = viewModel.syncErrorMessage
    }
}

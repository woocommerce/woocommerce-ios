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

    /// First Column Delta Value
    ///
    let leadingDelta: String

    /// First Column delta background color.
    ///
    let leadingDeltaColor: UIColor

    /// First Column delta text color.
    ///
    let leadingDeltaTextColor: UIColor

    /// First Column Chart Data
    ///
    let leadingChartData: [Double]

    /// Second Column Title
    ///
    let trailingTitle: String

    /// Second Column Value
    ///
    let trailingValue: String

    /// Second Column Delta Value
    ///
    let trailingDelta: String

    /// Second Column Delta Background Color
    ///
    let trailingDeltaColor: UIColor

    /// Second Column delta text color.
    ///
    let trailingDeltaTextColor: UIColor

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
              leadingDelta: "+50%",
              leadingDeltaColor: .lightGray,
              leadingDeltaTextColor: .text,
              leadingChartData: [],
              trailingTitle: trailingTitle,
              trailingValue: "$1000",
              trailingDelta: "+50%",
              trailingDeltaColor: .lightGray,
              trailingDeltaTextColor: .text,
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
        self.leadingDelta = viewModel.leadingDelta
        self.leadingDeltaColor = viewModel.leadingDeltaColor
        self.leadingDeltaTextColor = viewModel.leadingDeltaTextColor
        self.leadingChartData = viewModel.leadingChartData
        self.trailingTitle = viewModel.trailingTitle
        self.trailingValue = viewModel.trailingValue
        self.trailingDelta = viewModel.trailingDelta
        self.trailingDeltaColor = viewModel.trailingDeltaColor
        self.trailingDeltaTextColor = viewModel.trailingDeltaTextColor
        self.trailingChartData = viewModel.trailingChartData
        self.isRedacted = viewModel.isRedacted
        self.showSyncError = viewModel.showSyncError
        self.syncErrorMessage = viewModel.syncErrorMessage
    }
}

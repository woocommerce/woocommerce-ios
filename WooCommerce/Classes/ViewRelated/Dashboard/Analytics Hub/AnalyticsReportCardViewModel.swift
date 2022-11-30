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

    /// First Column Chart Data
    ///
    let leadingChartData: [Double]

    /// Second Column Titlke
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

    /// Second Column Chart Data
    ///
    let trailingChartData: [Double]
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
        self.leadingChartData = viewModel.leadingChartData
        self.trailingTitle = viewModel.trailingTitle
        self.trailingValue = viewModel.trailingValue
        self.trailingDelta = viewModel.trailingDelta
        self.trailingDeltaColor = viewModel.trailingDeltaColor
        self.trailingChartData = viewModel.trailingChartData
    }
}

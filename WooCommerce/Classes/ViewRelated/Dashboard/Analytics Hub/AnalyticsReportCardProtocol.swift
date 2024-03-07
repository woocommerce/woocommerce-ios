import Foundation
import class UIKit.UIColor

/// Protocol for `AnalyticsReportCard` View Models
/// Used to transmit analytics report data.
///
protocol AnalyticsReportCardProtocol {
    /// Report Card Title.
    ///
    var title: String { get }

    /// First Column Metric
    ///
    var leadingMetric: AnalyticsReportCardMetric { get set }

    /// Second Column Metric
    ///
    var trailingMetric: AnalyticsReportCardMetric { get set }

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool { get set }

    /// Indicates if there was an error loading the data for the card
    ///
    var showSyncError: Bool { get set }

    /// Message to display if there was an error loading the data for the card
    ///
    var syncErrorMessage: String { get }

    /// View model for the web analytics report link
    ///
    var reportViewModel: AnalyticsReportLinkViewModel? { get set }
}

extension AnalyticsReportCardProtocol {

    /// Make redacted state of the card, replacing values with hardcoded placeholders
    ///
    mutating func redact() {
        isRedacted = true
        showSyncError = false
    }

    /// First Column Title
    ///
    var leadingTitle: String {
        leadingMetric.title
    }

    /// First Column Value
    ///
    var leadingValue: String {
        isRedacted ? "$1000" : leadingMetric.value
    }

    /// First Column Delta Percentage
    ///
    var leadingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero) : leadingMetric.delta
    }

    /// First Column Chart Data
    ///
    var leadingChartData: [Double] {
        isRedacted ? [] : leadingMetric.chartData
    }

    /// Second Column Title
    ///
    var trailingTitle: String {
        trailingMetric.title
    }

    /// Second Column Value
    ///
    var trailingValue: String {
        isRedacted ? "$1000" : trailingMetric.value
    }

    /// Second Column Delta Percentage
    ///
    var trailingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero) : trailingMetric.delta
    }

    /// Second Column Chart Data
    ///
    var trailingChartData: [Double] {
        isRedacted ? [] : trailingMetric.chartData
    }
}

/// Represents a metric on an `AnalyticsReportCard`
///
struct AnalyticsReportCardMetric {
    /// Metric title
    let title: String

    /// Metric value
    let value: String

    /// Metric delta percentage
    let delta: DeltaPercentage?

    /// Metric chart data
    let chartData: [Double]
}

/// Convenience extension to create an `AnalyticsReportCard` from a view model.
///
extension AnalyticsReportCard {
    init(viewModel: AnalyticsReportCardProtocol) {
        self.title = viewModel.title
        self.leadingTitle = viewModel.leadingTitle
        self.leadingValue = viewModel.leadingValue
        self.leadingDelta = viewModel.leadingDelta?.string
        self.leadingDeltaColor = viewModel.leadingDelta?.direction.deltaBackgroundColor
        self.leadingDeltaTextColor = viewModel.leadingDelta?.direction.deltaTextColor
        self.leadingChartData = viewModel.leadingChartData
        self.leadingChartColor = viewModel.leadingDelta?.direction.chartColor
        self.trailingTitle = viewModel.trailingTitle
        self.trailingValue = viewModel.trailingValue
        self.trailingDelta = viewModel.trailingDelta?.string
        self.trailingDeltaColor = viewModel.trailingDelta?.direction.deltaBackgroundColor
        self.trailingDeltaTextColor = viewModel.trailingDelta?.direction.deltaTextColor
        self.trailingChartData = viewModel.trailingChartData
        self.trailingChartColor = viewModel.trailingDelta?.direction.chartColor
        self.isRedacted = viewModel.isRedacted
        self.showSyncError = viewModel.showSyncError
        self.syncErrorMessage = viewModel.syncErrorMessage
        self.reportViewModel = viewModel.reportViewModel
    }
}

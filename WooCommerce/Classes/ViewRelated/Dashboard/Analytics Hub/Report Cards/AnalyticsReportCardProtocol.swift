import Foundation
import class UIKit.UIColor

/// Protocol for `AnalyticsReportCard` View Models
/// Used to transmit analytics report data.
///
protocol AnalyticsReportCardProtocol {
    /// Report Card Title.
    ///
    var title: String { get }

    /// First Column Title
    ///
    var leadingTitle: String { get }

    /// First Column Value
    ///
    var leadingValue: String { get }

    /// First Column Delta Percentage
    ///
    var leadingDelta: DeltaPercentage? { get }

    /// First Column Chart Data
    ///
    var leadingChartData: [Double] { get }

    /// Second Column Title
    ///
    var trailingTitle: String { get }

    /// Second Column Value
    ///
    var trailingValue: String { get }

    /// Second Column Delta Percentage
    ///
    var trailingDelta: DeltaPercentage? { get }

    /// Second Column Chart Data
    ///
    var trailingChartData: [Double] { get }

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool { get set }

    /// Indicates if there was an error loading the data for the card
    ///
    var showSyncError: Bool { get }

    /// Message to display if there was an error loading the data for the card
    ///
    var syncErrorMessage: String { get }

    /// View model for the web analytics report link
    ///
    var reportViewModel: AnalyticsReportLinkViewModel? { get }
}

import Foundation

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date
}

protocol AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange { get }
    var previousTimeRange: AnalyticsHubTimeRange { get }
}

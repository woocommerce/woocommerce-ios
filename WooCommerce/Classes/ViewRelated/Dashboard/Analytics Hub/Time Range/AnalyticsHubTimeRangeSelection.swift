import Foundation

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date

    func generateDescription(referenceCalendar: Calendar) -> String {
        let startDateDescription = DateFormatter.Stats.analyticsHubDayMonthFormatter.string(from: start)

        let endDateDescription: String = {
            if start.isSameMonth(as: end, using: referenceCalendar) {
                return DateFormatter.Stats.analyticsHubDayYearFormatter.string(from: end)
            } else {
                return DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: end)
            }
        }()

        return "\(startDateDescription) - \(endDateDescription)"
    }
}

protocol AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange? { get }
    var previousTimeRange: AnalyticsHubTimeRange? { get }

    init(referenceDate: Date, currentCalendar: Calendar)
}

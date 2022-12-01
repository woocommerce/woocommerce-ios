import Foundation

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date

    func generateDescription(simplified: Bool, calendar: Calendar) -> String {
        if simplified {
            return DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: start)
        }

        let startDateDescription = DateFormatter.Stats.analyticsHubDayMonthFormatter.string(from: start)

        if start.isSameMonth(as: end, using: calendar) {
            return "\(startDateDescription) - \(DateFormatter.Stats.analyticsHubDayYearFormatter.string(from: end))"
        } else {
            return "\(startDateDescription) - \(DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: end))"
        }
    }
}

import Foundation

struct AnalyticsHubTimeRange {
    let start: Date
    let end: Date

    func formatToString(simplified: Bool, timezone: TimeZone, calendar: Calendar) -> String {
        if simplified {
            return DateFormatter.Stats.createAnalyticsHubDayMonthYearFormatter(timezone: timezone).string(from: start)
        }

        let startDateDescription = DateFormatter.Stats.createAnalyticsHubDayMonthFormatter(timezone: timezone).string(from: start)

        var endDateDescription: String
        if start.isSameMonth(as: end, using: calendar) {
            endDateDescription = DateFormatter.Stats.createAnalyticsHubDayYearFormatter(timezone: timezone).string(from: end)
        } else {
            endDateDescription = DateFormatter.Stats.createAnalyticsHubDayMonthYearFormatter(timezone: timezone).string(from: end)
        }
        return "\(startDateDescription) - \(endDateDescription)"
    }
}

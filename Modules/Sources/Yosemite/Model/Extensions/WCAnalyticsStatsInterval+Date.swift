import Foundation

extension WCAnalyticsStatsInterval {
    /// Returns the interval start date by parsing the `dateStart` string.
    public func dateStart(timeZone: TimeZone) -> Date? {
        createDateFormatter(timeZone: timeZone).date(from: dateStart)
    }

    /// Returns the interval end date by parsing the `dateEnd` string.
    public func dateEnd(timeZone: TimeZone) -> Date? {
        createDateFormatter(timeZone: timeZone).date(from: dateEnd)
    }
}

private extension WCAnalyticsStatsInterval {
    func createDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let dateFormatter = DateFormatter.Stats.dateTimeFormatter
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.timeZone = timeZone
        return dateFormatter
    }
}

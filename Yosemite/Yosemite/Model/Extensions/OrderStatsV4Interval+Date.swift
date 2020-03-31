import Foundation

extension OrderStatsV4Interval {
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter.Stats.dateTimeFormatter
        return dateFormatter
    }

    /// Returns the interval start date by parsing the `dateStart` string.
    public func dateStart() -> Date? {
        return dateFormatter.date(from: dateStart)
    }

    /// Returns the interval end date by parsing the `dateEnd` string.
    public func dateEnd() -> Date? {
        return dateFormatter.date(from: dateEnd)
    }
}

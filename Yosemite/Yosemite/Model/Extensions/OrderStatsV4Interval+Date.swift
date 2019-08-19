import Foundation

extension OrderStatsV4Interval {
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter.Stats.dateTimeFormatter
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        return dateFormatter
    }

    /// Returns the interval start date by parsing the `dateStart` string in GMT.
    public func dateStart() -> Date {
        guard let date = dateFormatter.date(from: dateStart) else {
            fatalError("Failed to parse GMT date: \(dateStart)")
        }
        return date
    }

    /// Returns the interval end date by parsing the `dateEnd` string in GMT.
    public func dateEnd() -> Date {
        guard let date = dateFormatter.date(from: dateEnd) else {
            fatalError("Failed to parse GMT date: \(dateEnd)")
        }
        return date
    }
}

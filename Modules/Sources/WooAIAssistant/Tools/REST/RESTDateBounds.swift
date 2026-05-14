import Foundation

enum RESTDateBounds {
    /// wc-analytics expects ISO-8601 with day boundaries; `after` is inclusive
    /// at midnight, `before` is inclusive at end-of-day, matching how the
    /// Woo dashboard scopes "today's revenue" against the same endpoint.
    static func bounds(start: String, end: String) -> (after: String, before: String)? {
        guard isValidYYYYMMDD(start), isValidYYYYMMDD(end) else { return nil }
        return ("\(start)T00:00:00", "\(end)T23:59:59")
    }

    /// Mirrors the Woo dashboard "previous period" anchoring: immediately preceding window of the same inclusive day count.
    static func previousPeriodBounds(after: String,
                                     before: String) -> (after: String, before: String)? {
        guard let afterDate = yyyyMMDDFormatter.date(from: after),
              let beforeDate = yyyyMMDDFormatter.date(from: before) else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        var utc = calendar
        utc.timeZone = TimeZone(identifier: "UTC") ?? .current
        guard let inclusiveDays = utc.dateComponents([.day], from: afterDate, to: beforeDate).day else {
            return nil
        }
        let totalDays = inclusiveDays + 1
        guard let previousBefore = utc.date(byAdding: .day, value: -1, to: afterDate),
              let previousAfter = utc.date(byAdding: .day, value: -(totalDays - 1), to: previousBefore) else {
            return nil
        }
        return (yyyyMMDDFormatter.string(from: previousAfter),
                yyyyMMDDFormatter.string(from: previousBefore))
    }

    private static let yyyyMMDDFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    private static func isValidYYYYMMDD(_ value: String) -> Bool {
        yyyyMMDDFormatter.date(from: value) != nil
    }
}

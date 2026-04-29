import Foundation

enum AnalyticsDateBounds {
    /// wc-analytics expects ISO-8601 with day boundaries; `after` is inclusive
    /// at midnight, `before` is inclusive at end-of-day, matching how the
    /// Woo dashboard scopes "today's revenue" against the same endpoint.
    static func bounds(start: String, end: String) -> (after: String, before: String)? {
        guard isValidYYYYMMDD(start), isValidYYYYMMDD(end) else { return nil }
        return ("\(start)T00:00:00", "\(end)T23:59:59")
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

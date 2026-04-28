import Foundation

enum AnalyticsDateBounds {
    /// wc-analytics expects ISO-8601 with day boundaries; `after` is inclusive
    /// at midnight, `before` is inclusive at end-of-day, matching how the
    /// Woo dashboard scopes "today's revenue" against the same endpoint.
    static func bounds(start: String, end: String) -> (after: String, before: String)? {
        guard isValidYYYYMMDD(start), isValidYYYYMMDD(end) else { return nil }
        return ("\(start)T00:00:00", "\(end)T23:59:59")
    }

    private static func isValidYYYYMMDD(_ value: String) -> Bool {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy(\.isNumber) }) else {
            return false
        }
        return true
    }
}

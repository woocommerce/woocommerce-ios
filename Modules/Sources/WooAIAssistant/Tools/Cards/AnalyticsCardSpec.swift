import Foundation

/// Analytics ref args encoded into a single id segment, kept identical to the
/// Android format so the catalog stays portable.
/// Format: `analytics_<kind>:after:<YYYY-MM-DD>:before:<YYYY-MM-DD>[:interval:<value>]:currency:<ISO|none>`.
struct AnalyticsCardSpec: Sendable, Equatable {
    static let currencyNoneSentinel = "none"

    let kind: AnalyticsKind
    let after: String
    let before: String
    let interval: String?
    let currency: String?

    var encoded: String {
        var segments = ["analytics_\(kind.rawValue)", "after", after, "before", before]
        if let interval, !interval.isEmpty {
            segments.append(contentsOf: ["interval", interval])
        }
        let currencyValue: String = {
            guard let currency, !currency.isEmpty else { return Self.currencyNoneSentinel }
            return currency
        }()
        segments.append(contentsOf: ["currency", currencyValue])
        return segments.joined(separator: ":")
    }

    static func decode(_ id: String) -> AnalyticsCardSpec? {
        let parts = id.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let kind = parts.first.flatMap(parseKindToken),
              let segments = paired(Array(parts.dropFirst())) else {
            return nil
        }
        guard let after = segments["after"],
              let before = segments["before"],
              isValidDate(after),
              isValidDate(before) else {
            return nil
        }
        let interval = segments["interval"]
        if let interval, !validIntervals.contains(interval) { return nil }
        let rawCurrency = segments["currency"]
        let currency: String?
        if let rawCurrency {
            if rawCurrency == currencyNoneSentinel {
                currency = nil
            } else if isValidCurrency(rawCurrency) {
                currency = rawCurrency
            } else {
                return nil
            }
        } else {
            currency = nil
        }
        let known: Set<String> = ["after", "before", "interval", "currency"]
        if segments.keys.contains(where: { !known.contains($0) }) { return nil }
        return AnalyticsCardSpec(kind: kind,
                                 after: after,
                                 before: before,
                                 interval: interval,
                                 currency: currency)
    }

    private static func parseKindToken(_ token: String) -> AnalyticsKind? {
        let prefix = "analytics_"
        guard token.hasPrefix(prefix) else { return nil }
        return AnalyticsKind(rawValue: String(token.dropFirst(prefix.count)))
    }

    private static func paired(_ tokens: [String]) -> [String: String]? {
        guard tokens.count.isMultiple(of: 2) else { return nil }
        var result: [String: String] = [:]
        for index in stride(from: 0, to: tokens.count, by: 2) {
            let key = tokens[index]
            let value = tokens[index + 1]
            if key.isEmpty || value.isEmpty { return nil }
            if result[key] != nil { return nil }
            result[key] = value
        }
        return result
    }

    private static let validIntervals: Set<String> = ["hour", "day", "week", "month", "year"]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    private static func isValidDate(_ value: String) -> Bool {
        dateFormatter.date(from: value) != nil
    }

    private static func isValidCurrency(_ value: String) -> Bool {
        guard value.count == 3 else { return false }
        return value.allSatisfy { $0.isLetter && $0.isUppercase }
    }
}

enum AnalyticsKind: String, Sendable, Equatable {
    case revenue
    case orders

    /// Synthetic tool name the orchestrator emits so `MessageCardHost.statsView`
    /// reaches the right metrics through its exact-match dispatch arm.
    var renderToolName: String {
        switch self {
        case .revenue: return AnalyticsRevenueTool.name
        case .orders: return AnalyticsOrdersTool.name
        }
    }

    var reportPath: String {
        switch self {
        case .revenue: return "wc-analytics/reports/revenue/stats"
        case .orders: return "wc-analytics/reports/orders/stats"
        }
    }
}

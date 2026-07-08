import Foundation

enum AnalyticsStatsSummary {
    /// Keys allowed in the model-visible projection. Mirrors Android's
    /// `ANALYTICS_STATS_SUMMARY_KEYS`; per-bucket data stays in the rendered
    /// card payload only so a year-by-day query doesn't ship 365 buckets to
    /// the model.
    static let modelVisibleKeys: [String] = [
        "after", "before", "interval", "currency", "totals",
        "previous_period_totals", "previous_period_partial", "previous_period_warning"
    ]

    struct ComparisonInputs {
        let interval: String
        let currency: String?
        let previousPeriodTotals: AnyCodableJSON?
        let previousPeriodPartial: Bool
        let previousPeriodWarning: String?

        init(interval: String,
             currency: String? = nil,
             previousPeriodTotals: AnyCodableJSON? = nil,
             previousPeriodPartial: Bool = false,
             previousPeriodWarning: String? = nil) {
            self.interval = interval
            self.currency = currency
            self.previousPeriodTotals = previousPeriodTotals
            self.previousPeriodPartial = previousPeriodPartial
            self.previousPeriodWarning = previousPeriodWarning
        }
    }

    static func make(from payload: AnyCodableJSON,
                     range: (after: String, before: String),
                     comparison: ComparisonInputs) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [
            "after": .string(range.after),
            "before": .string(range.before),
            "interval": .string(comparison.interval)
        ]
        if let currency = comparison.currency {
            fields["currency"] = .string(currency)
        }
        if let totals = RESTResponseParsing.objectField(payload, "totals") {
            fields["totals"] = totals
        }
        if let previous = comparison.previousPeriodTotals {
            fields["previous_period_totals"] = previous
        }
        if comparison.previousPeriodPartial {
            fields["previous_period_partial"] = .bool(true)
            if let warning = comparison.previousPeriodWarning {
                fields["previous_period_warning"] = .string(warning)
            }
        }
        if let intervals = RESTResponseParsing.arrayItems(RESTResponseParsing.objectField(payload, "intervals") ?? .null) {
            fields["interval_count"] = .int(Int64(intervals.count))
            fields["interval_subtotals"] = .array(intervals.compactMap(intervalSubtotal))
        }
        return .object(fields)
    }

    private static func intervalSubtotal(_ interval: AnyCodableJSON) -> AnyCodableJSON? {
        guard case .object(let dict) = interval else { return nil }
        var out: [String: AnyCodableJSON] = [:]
        if let label = dict["interval"] { out["interval"] = label }
        if let date = dict["date_start"] { out["date_start"] = date }
        if let subtotals = dict["subtotals"] { out["subtotals"] = subtotals }
        return out.isEmpty ? nil : .object(out)
    }
}

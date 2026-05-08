import Foundation

enum AnalyticsStatsSummary {
    /// Keys allowed in the model-visible projection. Mirrors Android's
    /// `ANALYTICS_STATS_SUMMARY_KEYS`; per-bucket data stays in the rendered
    /// card payload only so a year-by-day query doesn't ship 365 buckets to
    /// the model.
    static let modelVisibleKeys: [String] = ["after", "before", "totals"]

    /// Builds the full summary used by the analytics tools' tool result and
    /// by the card renderer. The `show_cards` resolver projects this down
    /// to `modelVisibleKeys` before the model sees it via `resolved_refs`.
    static func make(from payload: AnyCodableJSON, range: (after: String, before: String)) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [
            "after": .string(range.after),
            "before": .string(range.before)
        ]
        if let totals = RESTResponseParsing.objectField(payload, "totals") {
            fields["totals"] = totals
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

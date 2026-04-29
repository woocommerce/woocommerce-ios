import Foundation

enum AnalyticsStatsSummary {
    /// Analytics is text-only: the model needs the numeric totals to answer in
    /// prose. We keep `totals` verbatim and replace `intervals` with a
    /// per-bucket subtotals projection plus the bucket count, so a
    /// year-by-day call doesn't ship 365 row JSON blobs.
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

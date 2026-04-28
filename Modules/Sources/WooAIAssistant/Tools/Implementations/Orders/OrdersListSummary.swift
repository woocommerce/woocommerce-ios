import Foundation

enum OrdersListSummary {
    static func make(from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var statuses: Set<String> = []
        var totals: [Decimal] = []
        var currency: String?

        for row in rows {
            if let id = RESTResponseParsing.intField(row, "id") {
                ids.append(.int(id))
            }
            if let status = RESTResponseParsing.stringField(row, "status") {
                statuses.insert(status)
            }
            if let total = RESTResponseParsing.decimalField(row, "total") {
                totals.append(total)
            }
            if currency == nil, let value = RESTResponseParsing.stringField(row, "currency") {
                currency = value
            }
        }

        var fields: [String: AnyCodableJSON] = [
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "statuses_present": .array(statuses.sorted().map(AnyCodableJSON.string))
        ]
        if let totalRange = totalRange(totals: totals, currency: currency) {
            fields["total_range"] = totalRange
        }
        return .object(fields)
    }

    private static func totalRange(totals: [Decimal], currency: String?) -> AnyCodableJSON? {
        guard let min = totals.min(), let max = totals.max() else { return nil }
        var range: [String: AnyCodableJSON] = [
            "min": .string(format(min)),
            "max": .string(format(max))
        ]
        if let currency { range["currency"] = .string(currency) }
        return .object(range)
    }

    private static func format(_ value: Decimal) -> String {
        var copy = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &copy, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
}

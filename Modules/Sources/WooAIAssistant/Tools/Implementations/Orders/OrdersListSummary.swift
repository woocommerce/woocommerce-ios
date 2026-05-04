import Foundation

enum OrdersListSummary {
    static func make(from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var perRow: [AnyCodableJSON] = []
        var statusCounts: [String: Int] = [:]
        var totals: [Decimal] = []
        var currency: String?

        for row in rows {
            var rowFields: [String: AnyCodableJSON] = [:]
            if let id = RESTResponseParsing.intField(row, "id") {
                ids.append(.int(id))
                rowFields["id"] = .int(id)
            }
            if let status = RESTResponseParsing.stringField(row, "status") {
                statusCounts[status, default: 0] += 1
            }
            if let total = RESTResponseParsing.decimalField(row, "total") {
                totals.append(total)
            }
            if currency == nil, let value = RESTResponseParsing.stringField(row, "currency") {
                currency = value
            }
            if let customerID = RESTResponseParsing.intField(row, "customer_id") {
                rowFields["customer_id"] = .int(customerID)
            }
            if !rowFields.isEmpty {
                perRow.append(.object(rowFields))
            }
        }

        var fields: [String: AnyCodableJSON] = [
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "rows": .array(perRow),
            "status_counts": .object(statusCounts.mapValues { .int(Int64($0)) })
        ]
        if let totalRange = RESTResponseParsing.decimalRange(totals, currency: currency) {
            fields["total_range"] = totalRange
        }
        return .object(fields)
    }
}

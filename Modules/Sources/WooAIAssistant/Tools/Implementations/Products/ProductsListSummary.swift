import Foundation

enum ProductsListSummary {
    static func make(from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var stockStatusCounts: [String: Int] = [:]
        var prices: [Decimal] = []

        for row in rows {
            if let id = RESTResponseParsing.intField(row, "id") {
                ids.append(.int(id))
            }
            if let status = RESTResponseParsing.stringField(row, "stock_status") {
                stockStatusCounts[status, default: 0] += 1
            }
            if let price = RESTResponseParsing.decimalField(row, "price") {
                prices.append(price)
            }
        }

        var fields: [String: AnyCodableJSON] = [
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "stock_status_counts": .object(stockStatusCounts.mapValues { .int(Int64($0)) })
        ]
        if let priceRange = RESTResponseParsing.decimalRange(prices) {
            fields["price_range"] = priceRange
        }
        return .object(fields)
    }
}

import Foundation

enum ProductVariationsListSummary {
    static func make(productID: Int64, from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var variations: [AnyCodableJSON] = []
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
            variations.append(ProductVariationDetailSummary.make(from: row))
        }

        var fields: [String: AnyCodableJSON] = [
            "product_id": .int(productID),
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "variations": .array(variations),
            "stock_status_counts": .object(stockStatusCounts.mapValues { .int(Int64($0)) })
        ]
        if let priceRange = RESTResponseParsing.decimalRange(prices) {
            fields["price_range"] = priceRange
        }
        return .object(fields)
    }
}

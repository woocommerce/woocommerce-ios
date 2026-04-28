import Foundation

enum ProductVariationsListSummary {
    static func make(productID: Int64, from rows: [AnyCodableJSON]) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var stockStatuses: Set<String> = []
        var prices: [Decimal] = []

        for row in rows {
            if let id = RESTResponseParsing.intField(row, "id") {
                ids.append(.int(id))
            }
            if let status = RESTResponseParsing.stringField(row, "stock_status") {
                stockStatuses.insert(status)
            }
            if let price = RESTResponseParsing.decimalField(row, "price") {
                prices.append(price)
            }
        }

        var fields: [String: AnyCodableJSON] = [
            "product_id": .int(productID),
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "stock_statuses_present": .array(stockStatuses.sorted().map(AnyCodableJSON.string))
        ]
        if let priceRange = RESTResponseParsing.decimalRange(prices) {
            fields["price_range"] = priceRange
        }
        return .object(fields)
    }
}

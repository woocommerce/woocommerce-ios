import Foundation

enum AnalyticsProductsSummary {
    /// The report's `extended_info` is heavy (image HTML, permalink, category_ids,
    /// variations), so only these few string fields are lifted into each compact row.
    private static let extendedInfoStringKeys = ["name", "sku", "stock_status"]

    static func make(from rows: [AnyCodableJSON],
                     range: (after: String, before: String),
                     orderby: String) -> AnyCodableJSON {
        .object([
            "after": .string(range.after),
            "before": .string(range.before),
            "orderby": .string(orderby),
            "count": .int(Int64(rows.count)),
            "products": .array(rows.compactMap(productRow))
        ])
    }

    private static func productRow(_ row: AnyCodableJSON) -> AnyCodableJSON? {
        guard let productID = RESTResponseParsing.intField(row, "product_id") else { return nil }
        var out: [String: AnyCodableJSON] = ["product_id": .int(productID)]
        if let itemsSold = RESTResponseParsing.intField(row, "items_sold") {
            out["items_sold"] = .int(itemsSold)
        }
        if let netRevenue = RESTResponseParsing.decimalField(row, "net_revenue") {
            out["net_revenue"] = .string(RESTResponseParsing.formatDecimal(netRevenue))
        }
        if let ordersCount = RESTResponseParsing.intField(row, "orders_count") {
            out["orders_count"] = .int(ordersCount)
        }
        if let extended = RESTResponseParsing.objectField(row, "extended_info") {
            mergeExtendedInfo(extended, into: &out)
        }
        // Pre-bakes the products_update / show_cards target so the model can chain a row straight in.
        out["target"] = .object(["kind": .string("product"), "id": .int(productID)])
        return .object(out)
    }

    private static func mergeExtendedInfo(_ extended: AnyCodableJSON, into out: inout [String: AnyCodableJSON]) {
        if let price = RESTResponseParsing.decimalField(extended, "price") {
            out["price"] = .string(RESTResponseParsing.formatDecimal(price))
        }
        for key in extendedInfoStringKeys {
            if let value = RESTResponseParsing.stringField(extended, key), !value.isEmpty {
                out[key] = .string(value)
            }
        }
    }
}

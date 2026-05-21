import Foundation

enum ProductsListSummary {
    enum RowKind: String {
        case product
        case variation
    }

    static func make(from rows: [AnyCodableJSON],
                     canLoadMore: Bool,
                     kind: RowKind) -> AnyCodableJSON {
        make(tagged: rows.map { ($0, kind) }, canLoadMore: canLoadMore)
    }

    /// Use when the same response carries both product and variation rows so each row is
    /// projected with its own shape and `kind` tag.
    static func make(tagged rows: [(AnyCodableJSON, RowKind)],
                     canLoadMore: Bool) -> AnyCodableJSON {
        var ids: [AnyCodableJSON] = []
        var stockStatusCounts: [String: Int] = [:]
        var prices: [Decimal] = []
        var products: [AnyCodableJSON] = []

        for (row, kind) in rows {
            if let id = RESTResponseParsing.intField(row, "id") {
                ids.append(.int(id))
            }
            if let status = RESTResponseParsing.stringField(row, "stock_status") {
                stockStatusCounts[status, default: 0] += 1
            }
            if let price = RESTResponseParsing.decimalField(row, "price") {
                prices.append(price)
            }
            products.append(makeRow(from: row, kind: kind))
        }

        var fields: [String: AnyCodableJSON] = [
            "count": .int(Int64(rows.count)),
            "ids": .array(ids),
            "products": .array(products),
            "can_load_more": .bool(canLoadMore),
            "stock_status_counts": .object(stockStatusCounts.mapValues { .int(Int64($0)) })
        ]
        if let priceRange = RESTResponseParsing.decimalRange(prices) {
            fields["price_range"] = priceRange
        }
        return .object(fields)
    }

    private static func makeRow(from row: AnyCodableJSON, kind: RowKind) -> AnyCodableJSON {
        let projected: AnyCodableJSON
        switch kind {
        case .product:
            projected = ProductSummary.listRow(from: row)
        case .variation:
            projected = ProductVariationDetailSummary.make(from: row)
        }
        guard case .object(var fields) = projected else { return projected }
        fields["kind"] = .string(kind.rawValue)
        if let target = target(from: row, kind: kind) {
            fields["target"] = target
        }
        return .object(fields)
    }

    /// Pre-bakes the products_update target shape; copying `target` straight into a write call
    /// removes the need for the model to interpret id versus parent_id versus variation_id.
    private static func target(from row: AnyCodableJSON, kind: RowKind) -> AnyCodableJSON? {
        guard let id = RESTResponseParsing.intField(row, "id") else { return nil }
        switch kind {
        case .product:
            return .object([
                "kind": .string("product"),
                "id": .int(id)
            ])
        case .variation:
            guard let parentID = RESTResponseParsing.intField(row, "parent_id") else { return nil }
            return .object([
                "kind": .string("variation"),
                "id": .int(id),
                "parent_id": .int(parentID)
            ])
        }
    }
}

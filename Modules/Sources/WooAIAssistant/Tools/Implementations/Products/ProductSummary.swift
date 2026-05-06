import Foundation

enum ProductSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: [
            "id", "name", "sku", "price", "stock_status", "type", "status",
            "stock_quantity", "regular_price", "sale_price", "images"
        ])
        guard case .object(var fields) = projected else { return projected }
        if case .array(let items) = fields["images"] {
            fields["images"] = .array(Array(items.prefix(1)))
        }
        return .object(fields)
    }
}

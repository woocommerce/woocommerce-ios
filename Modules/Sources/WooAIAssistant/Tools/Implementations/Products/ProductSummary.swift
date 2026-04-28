import Foundation

enum ProductSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        RESTResponseParsing.project(entity, keys: [
            "id", "name", "sku", "price", "stock_status", "type", "status",
            "stock_quantity", "regular_price", "sale_price"
        ])
    }
}

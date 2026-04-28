import Foundation

enum ProductSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [:]
        guard case .object(let dict) = entity else { return .object(fields) }
        let keys = [
            "id", "name", "sku", "price", "stock_status", "type", "status",
            "stock_quantity", "regular_price", "sale_price"
        ]
        for key in keys {
            if let value = dict[key] { fields[key] = value }
        }
        return .object(fields)
    }
}

import Foundation

enum ProductSummary {
    static func make(from entity: AnyCodableJSON) -> AnyCodableJSON {
        var fields: [String: AnyCodableJSON] = [:]
        guard case .object(let dict) = entity else { return .object(fields) }
        for key in ["id", "name", "sku", "price", "stock_status", "type", "status"] {
            if let value = dict[key] { fields[key] = value }
        }
        return .object(fields)
    }
}

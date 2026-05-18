import Foundation

/// Decoded shape of a single entry in `products_update.updates`. Shared by the tool's
/// dispatcher and the confirmation preview so the two never drift on field names.
/// `id` is optional so partial/in-progress tool calls can still be previewed.
struct ProductsUpdateEntry: Decodable, Sendable {
    let id: Int?
    let regularPrice: String?
    let salePrice: String?
    let percentDiscount: Double?
    let stockQuantity: Int?
    let status: String?
    let name: String?
    let stockStatus: String?
    let sku: String?

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case percentDiscount = "percent_discount"
        case stockQuantity = "stock_quantity"
        case status
        case name
        case stockStatus = "stock_status"
        case sku
    }

    var hasAnyField: Bool {
        regularPrice != nil || salePrice != nil || percentDiscount != nil
            || stockQuantity != nil || status != nil
            || name != nil || stockStatus != nil || sku != nil
    }

    var changedKeys: [String] {
        var keys: [String] = []
        if regularPrice != nil { keys.append("regular_price") }
        if salePrice != nil { keys.append("sale_price") }
        if percentDiscount != nil { keys.append("percent_discount") }
        if stockQuantity != nil { keys.append("stock_quantity") }
        if status != nil { keys.append("status") }
        if name != nil { keys.append("name") }
        if stockStatus != nil { keys.append("stock_status") }
        if sku != nil { keys.append("sku") }
        return keys
    }
}

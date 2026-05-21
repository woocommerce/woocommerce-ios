import Foundation

/// Decoded shape of a single entry in `products_update.updates`. Shared by the tool's
/// dispatcher and the confirmation preview so the two never drift on field names.
/// `target` is optional so partial/in-progress tool calls can still be previewed.
struct ProductsUpdateEntry: Decodable, Sendable {
    let target: Target?
    let regularPrice: String?
    let salePrice: String?
    let stockQuantity: Int?
    let status: String?
    let name: String?
    let stockStatus: String?
    let sku: String?

    /// Routing object the model copies verbatim from read tools; mirrors the JSON shape on the wire.
    struct Target: Decodable, Sendable {
        let kind: String?
        let id: Int?
        let parentID: Int?

        enum CodingKeys: String, CodingKey {
            case kind
            case id
            case parentID = "parent_id"
        }
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case target
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case stockQuantity = "stock_quantity"
        case status
        case name
        case stockStatus = "stock_status"
        case sku
    }

    var hasAnyField: Bool {
        regularPrice != nil || salePrice != nil
            || stockQuantity != nil || status != nil
            || name != nil || stockStatus != nil || sku != nil
    }

    var changedKeys: [String] {
        var keys: [String] = []
        if regularPrice != nil { keys.append("regular_price") }
        if salePrice != nil { keys.append("sale_price") }
        if stockQuantity != nil { keys.append("stock_quantity") }
        if status != nil { keys.append("status") }
        if name != nil { keys.append("name") }
        if stockStatus != nil { keys.append("stock_status") }
        if sku != nil { keys.append("sku") }
        return keys
    }
}

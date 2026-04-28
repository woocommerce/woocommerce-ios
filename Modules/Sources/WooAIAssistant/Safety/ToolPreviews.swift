import Foundation

/// Human-readable one-liners shown on the confirmation card. Keeps the
/// confirmation UX honest: the merchant sees "Update product #7: price -> $24.99"
/// instead of `products_update {"id":7,"regular_price":"24.99"}`.
///
/// Each known tool decodes its own args struct and builds a sentence. Unknown
/// tools fall through to a compact generic preview so adding a new tool never
/// breaks the confirmation path - the preview just looks worse until a builder
/// lands here.
public enum ToolPreviews {

    /// Default preview builder plugged into `DefaultSafetyPolicy`. Routes by
    /// tool name; falls back to a truncated args string for anything it
    /// doesn't recognize.
    public static let defaultBuilder: @Sendable (String, String) -> String = { name, arguments in
        switch name {
        case OrdersUpdateTool.name:
            return ordersUpdate(arguments: arguments)
        case OrdersBulkUpdateTool.name:
            return ordersBulkUpdate(arguments: arguments)
        case ProductsUpdateTool.name:
            return productsUpdate(arguments: arguments)
        case ProductsBulkUpdateTool.name:
            return productsBulkUpdate(arguments: arguments)
        case ProductVariationsUpdateTool.name:
            return productVariationsUpdate(arguments: arguments)
        default:
            return genericPreview(name: name, arguments: arguments)
        }
    }

    // MARK: - Per-tool previews

    private static func ordersUpdate(arguments: String) -> String {
        struct A: Decodable {
            let id: Int?
            let status: String?
            let customer_note: String?
            let billing_email: String?
        }
        guard let a = decode(A.self, from: arguments), let id = a.id else {
            return "Update an order"
        }
        var changes: [String] = []
        if let status = a.status {
            let note = customerNotifyingStatuses.contains(status) ? " (emails the customer)" : ""
            changes.append("status -> \(status)\(note)")
        }
        if a.customer_note != nil { changes.append("customer note updated") }
        if let email = a.billing_email { changes.append("billing email -> \(email)") }
        if changes.isEmpty {
            return "Update order #\(id)"
        }
        if changes.count == 1, a.status != nil {
            return "Set order #\(id) to \(changes[0].replacingOccurrences(of: "status -> ", with: ""))"
        }
        return "Update order #\(id): \(changes.joined(separator: ", "))"
    }

    private static func ordersBulkUpdate(arguments: String) -> String {
        struct A: Decodable {
            let ids: [Int]?
            let patch: Patch?
            struct Patch: Decodable {
                let status: String?
                let customer_note: String?
                let billing_email: String?
            }
        }
        guard let a = decode(A.self, from: arguments),
              let ids = a.ids, let patch = a.patch else {
            return "Update many orders"
        }
        var changes: [String] = []
        if let status = patch.status { changes.append("status -> \(status)") }
        if patch.customer_note != nil { changes.append("customer note updated") }
        if let email = patch.billing_email { changes.append("billing email -> \(email)") }
        let summary = changes.isEmpty ? "edit fields" : changes.joined(separator: ", ")
        let noun = ids.count == 1 ? "order" : "orders"
        return "Update \(ids.count) \(noun): \(summary)"
    }

    private static func productsUpdate(arguments: String) -> String {
        struct A: Decodable {
            let id: Int?
            let name: String?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Int?
            let status: String?
        }
        guard let a = decode(A.self, from: arguments), let id = a.id else {
            return "Update a product"
        }
        var changes: [String] = []
        if let name = a.name { changes.append("name -> \(name)") }
        if let price = a.regular_price { changes.append("price -> $\(price)") }
        if let sale = a.sale_price { changes.append("sale -> \(sale.isEmpty ? "off" : "$\(sale)")") }
        if let stock = a.stock_quantity { changes.append("stock -> \(stock)") }
        if let status = a.status { changes.append("status -> \(status)") }
        let summary = changes.isEmpty ? "edit fields" : changes.joined(separator: ", ")
        return "Update product #\(id): \(summary)"
    }

    private static func productsBulkUpdate(arguments: String) -> String {
        struct A: Decodable {
            let ids: [Int]?
            let patch: Patch?
            struct Patch: Decodable {
                let name: String?
                let regular_price: String?
                let sale_price: String?
                let stock_quantity: Int?
                let status: String?
            }
        }
        guard let a = decode(A.self, from: arguments),
              let ids = a.ids, let patch = a.patch else {
            return "Update many products"
        }
        var changes: [String] = []
        if let name = patch.name { changes.append("name -> \(name)") }
        if let price = patch.regular_price { changes.append("price -> $\(price)") }
        if let sale = patch.sale_price { changes.append("sale -> \(sale.isEmpty ? "off" : "$\(sale)")") }
        if let stock = patch.stock_quantity { changes.append("stock -> \(stock)") }
        if let status = patch.status { changes.append("status -> \(status)") }
        let summary = changes.isEmpty ? "edit fields" : changes.joined(separator: ", ")
        let noun = ids.count == 1 ? "product" : "products"
        return "Update \(ids.count) \(noun): \(summary)"
    }

    private static func productVariationsUpdate(arguments: String) -> String {
        struct A: Decodable {
            let product_id: Int?
            let id: Int?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Int?
            let stock_status: String?
            let sku: String?
            let status: String?
        }
        guard let a = decode(A.self, from: arguments),
              let pid = a.product_id, let vid = a.id else {
            return "Update product variation"
        }
        var changes: [String] = []
        if let price = a.regular_price { changes.append("price -> $\(price)") }
        if let sale = a.sale_price { changes.append("sale -> \(sale.isEmpty ? "off" : "$\(sale)")") }
        if let stock = a.stock_quantity { changes.append("stock -> \(stock)") }
        if let stockStatus = a.stock_status { changes.append("stock status -> \(stockStatus)") }
        if let sku = a.sku { changes.append("sku -> \(sku)") }
        if let status = a.status { changes.append("status -> \(status)") }
        let summary = changes.isEmpty ? "edit fields" : changes.joined(separator: ", ")
        return "Update variation #\(vid) of product #\(pid): \(summary)"
    }

    // MARK: - Helpers

    /// Order statuses that trigger a customer email on transition. Used to
    /// enrich the preview so the merchant knows an email is coming.
    private static let customerNotifyingStatuses: Set<String> = [
        "processing", "completed", "cancelled", "refunded", "on-hold"
    ]

    private static func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Last-resort preview for tools without a dedicated builder. Truncates
    /// to keep the card readable.
    private static func genericPreview(name: String, arguments: String) -> String {
        let args = arguments.count > 80
            ? String(arguments.prefix(80)) + "..."
            : arguments
        return "\(name) \(args)"
    }
}

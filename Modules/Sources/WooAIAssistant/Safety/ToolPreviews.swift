import Foundation
import CocoaLumberjackSwift

public enum ToolPreviews {

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
        case ProductVariationsBulkUpdateTool.name:
            return productVariationsBulkUpdate(arguments: arguments)
        default:
            return genericPreview(name: name, arguments: arguments)
        }
    }

    private static func ordersUpdate(arguments: String) -> String {
        struct A: Decodable {
            let id: Int?
            let status: String?
            let customer_note: String?
            let billing_email: String?
        }
        guard let a = decode(A.self, from: arguments), let id = a.id else {
            return Localization.ordersUpdateFallback
        }

        // Status-only path: special "Set order #X to Y" wording.
        if let status = a.status, a.customer_note == nil, a.billing_email == nil {
            let suffix = customerNotifyingStatuses.contains(status) ? Localization.emailsCustomerSuffix : ""
            return String.localizedStringWithFormat(Localization.ordersUpdateStatusOnly, id, status) + suffix
        }

        var changes: [String] = []
        if let status = a.status {
            let suffix = customerNotifyingStatuses.contains(status) ? Localization.emailsCustomerSuffix : ""
            changes.append(String.localizedStringWithFormat(Localization.changeStatus, status) + suffix)
        }
        if a.customer_note != nil { changes.append(Localization.changeCustomerNote) }
        if let email = a.billing_email {
            changes.append(String.localizedStringWithFormat(Localization.changeBillingEmail, email))
        }

        if changes.isEmpty {
            return String.localizedStringWithFormat(Localization.ordersUpdateNoChanges, id)
        }
        return String.localizedStringWithFormat(Localization.ordersUpdateFull, id, changes.joined(separator: ", "))
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
            return Localization.ordersBulkUpdateFallback
        }
        var changes: [String] = []
        if let status = patch.status {
            let baseChange = String.localizedStringWithFormat(Localization.changeStatus, status)
            let suffix = customerNotifyingStatuses.contains(status) ? Localization.emailsCustomersSuffix : ""
            changes.append(baseChange + suffix)
        }
        if patch.customer_note != nil { changes.append(Localization.changeCustomerNote) }
        if let email = patch.billing_email {
            changes.append(String.localizedStringWithFormat(Localization.changeBillingEmail, email))
        }
        let summary = changes.isEmpty ? Localization.changeEditFields : changes.joined(separator: ", ")
        let format = ids.count == 1 ? Localization.ordersBulkUpdateSingular : Localization.ordersBulkUpdatePlural
        return String.localizedStringWithFormat(format, ids.count, summary)
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
            return Localization.productsUpdateFallback
        }
        let changes = productChanges(name: a.name,
                                     regularPrice: a.regular_price,
                                     salePrice: a.sale_price,
                                     stockQuantity: a.stock_quantity,
                                     status: a.status)
        let summary = changes.isEmpty ? Localization.changeEditFields : changes.joined(separator: ", ")
        return String.localizedStringWithFormat(Localization.productsUpdateFull, id, summary)
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
            return Localization.productsBulkUpdateFallback
        }
        let changes = productChanges(name: patch.name,
                                     regularPrice: patch.regular_price,
                                     salePrice: patch.sale_price,
                                     stockQuantity: patch.stock_quantity,
                                     status: patch.status)
        let summary = changes.isEmpty ? Localization.changeEditFields : changes.joined(separator: ", ")
        let format = ids.count == 1 ? Localization.productsBulkUpdateSingular : Localization.productsBulkUpdatePlural
        return String.localizedStringWithFormat(format, ids.count, summary)
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
            return Localization.productVariationsUpdateFallback
        }
        var changes: [String] = []
        if let price = a.regular_price {
            changes.append(String.localizedStringWithFormat(Localization.changeRegularPrice, price))
        }
        if let sale = a.sale_price {
            changes.append(sale.isEmpty ? Localization.changeSaleOff
                                        : String.localizedStringWithFormat(Localization.changeSalePrice, sale))
        }
        if let stock = a.stock_quantity {
            changes.append(String.localizedStringWithFormat(Localization.changeStockQuantity, stock))
        }
        if let stockStatus = a.stock_status {
            changes.append(String.localizedStringWithFormat(Localization.changeStockStatus, stockStatus))
        }
        if let sku = a.sku {
            changes.append(String.localizedStringWithFormat(Localization.changeSku, sku))
        }
        if let status = a.status {
            changes.append(String.localizedStringWithFormat(Localization.changeStatus, status))
        }
        let summary = changes.isEmpty ? Localization.changeEditFields : changes.joined(separator: ", ")
        return String.localizedStringWithFormat(Localization.productVariationsUpdateFull, vid, pid, summary)
    }

    private static func productVariationsBulkUpdate(arguments: String) -> String {
        struct A: Decodable {
            let product_id: Int?
            let variations: [V]?
            struct V: Decodable {
                let id: Int?
            }
        }
        guard let a = decode(A.self, from: arguments),
              let pid = a.product_id, let variations = a.variations else {
            return Localization.productVariationsBulkUpdateFallback
        }
        let count = variations.count
        let format = count == 1 ? Localization.productVariationsBulkUpdateSingular
                                : Localization.productVariationsBulkUpdatePlural
        return String.localizedStringWithFormat(format, count, pid)
    }

    private static func productChanges(name: String?,
                                       regularPrice: String?,
                                       salePrice: String?,
                                       stockQuantity: Int?,
                                       status: String?) -> [String] {
        var changes: [String] = []
        if let name {
            changes.append(String.localizedStringWithFormat(Localization.changeName, name))
        }
        if let price = regularPrice {
            changes.append(String.localizedStringWithFormat(Localization.changeRegularPrice, price))
        }
        if let sale = salePrice {
            changes.append(sale.isEmpty ? Localization.changeSaleOff
                                        : String.localizedStringWithFormat(Localization.changeSalePrice, sale))
        }
        if let stock = stockQuantity {
            changes.append(String.localizedStringWithFormat(Localization.changeStockQuantity, stock))
        }
        if let status {
            changes.append(String.localizedStringWithFormat(Localization.changeStatus, status))
        }
        return changes
    }

    /// Order statuses that trigger a customer email on transition.
    private static let customerNotifyingStatuses: Set<String> = [
        "processing", "completed", "cancelled", "refunded", "on-hold"
    ]

    private static func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DDLogError("ToolPreviews failed to decode \(type): \(error)")
            return nil
        }
    }

    private static func genericPreview(name: String, arguments: String) -> String {
        let args = arguments.count > 80
            ? String(arguments.prefix(80)) + "..."
            : arguments
        return "\(name) \(args)"
    }

    private enum Localization {
        static let ordersUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.orders_update.fallback",
            value: "Update an order",
            comment: "Confirmation card preview shown when the orders_update tool call cannot be parsed."
        )
        static let ordersUpdateNoChanges = NSLocalizedString(
            "ai.assistant.preview.orders_update.no_changes",
            value: "Update order #%1$d",
            comment: "Confirmation card preview when only the order id is known. %1$d is the order number."
        )
        static let ordersUpdateStatusOnly = NSLocalizedString(
            "ai.assistant.preview.orders_update.status_only",
            value: "Set order #%1$d to %2$@",
            comment: "Confirmation card preview when only the status changes on an order. %1$d is the order number, %2$@ is the new status."
        )
        static let ordersUpdateFull = NSLocalizedString(
            "ai.assistant.preview.orders_update.full",
            value: "Update order #%1$d: %2$@",
            comment: "Confirmation card preview for a multi-field order update. %1$d is the order number, %2$@ is a comma-separated change list."
        )

        static let ordersBulkUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.orders_bulk_update.fallback",
            value: "Update many orders",
            comment: "Confirmation card preview when the orders_bulk_update tool call cannot be parsed."
        )
        static let ordersBulkUpdateSingular = NSLocalizedString(
            "ai.assistant.preview.orders_bulk_update.singular",
            value: "Update %1$d order: %2$@",
            comment: "Singular bulk-orders confirmation preview. %1$d is the count (1), %2$@ is a comma-separated change list."
        )
        static let ordersBulkUpdatePlural = NSLocalizedString(
            "ai.assistant.preview.orders_bulk_update.plural",
            value: "Update %1$d orders: %2$@",
            comment: "Plural bulk-orders confirmation preview. %1$d is the count, %2$@ is a comma-separated change list."
        )

        static let productsUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.products_update.fallback",
            value: "Update a product",
            comment: "Confirmation card preview when the products_update tool call cannot be parsed."
        )
        static let productsUpdateFull = NSLocalizedString(
            "ai.assistant.preview.products_update.full",
            value: "Update product #%1$d: %2$@",
            comment: "Confirmation card preview for a product update. %1$d is the product id, %2$@ is a comma-separated change list."
        )

        static let productsBulkUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.products_bulk_update.fallback",
            value: "Update many products",
            comment: "Confirmation card preview when the products_bulk_update tool call cannot be parsed."
        )
        static let productsBulkUpdateSingular = NSLocalizedString(
            "ai.assistant.preview.products_bulk_update.singular",
            value: "Update %1$d product: %2$@",
            comment: "Singular bulk-products confirmation preview. %1$d is the count (1), %2$@ is a comma-separated change list."
        )
        static let productsBulkUpdatePlural = NSLocalizedString(
            "ai.assistant.preview.products_bulk_update.plural",
            value: "Update %1$d products: %2$@",
            comment: "Plural bulk-products confirmation preview. %1$d is the count, %2$@ is a comma-separated change list."
        )

        static let productVariationsUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.product_variations_update.fallback",
            value: "Update product variation",
            comment: "Confirmation card preview when the product_variations_update tool call cannot be parsed."
        )
        static let productVariationsUpdateFull = NSLocalizedString(
            "ai.assistant.preview.product_variations_update.full",
            value: "Update variation #%1$d of product #%2$d: %3$@",
            comment: "Variation update preview. %1$d is the variation id, %2$d the parent product id, %3$@ the change list."
        )

        static let productVariationsBulkUpdateFallback = NSLocalizedString(
            "ai.assistant.preview.product_variations_bulk_update.fallback",
            value: "Update many variations",
            comment: "Confirmation card preview when the product_variations_bulk_update tool call cannot be parsed."
        )
        static let productVariationsBulkUpdateSingular = NSLocalizedString(
            "ai.assistant.preview.product_variations_bulk_update.singular",
            value: "Update %1$d variation of product #%2$d",
            comment: "Singular variations bulk preview. %1$d is the count (1), %2$d is the parent product id."
        )
        static let productVariationsBulkUpdatePlural = NSLocalizedString(
            "ai.assistant.preview.product_variations_bulk_update.plural",
            value: "Update %1$d variations of product #%2$d",
            comment: "Plural variations bulk preview. %1$d is the count, %2$d is the parent product id."
        )

        static let emailsCustomerSuffix = NSLocalizedString(
            "ai.assistant.preview.suffix.emails_customer",
            value: " (emails the customer)",
            comment: "Suffix on a single-order status preview when the status triggers a customer email. Leading space included."
        )
        static let emailsCustomersSuffix = NSLocalizedString(
            "ai.assistant.preview.suffix.emails_customers",
            value: " (emails customers)",
            comment: "Suffix on a bulk-order status preview when the status triggers customer emails. Leading space included."
        )

        static let changeEditFields = NSLocalizedString(
            "ai.assistant.preview.change.edit_fields",
            value: "edit fields",
            comment: "Generic change description used when no specific field can be enumerated."
        )
        static let changeName = NSLocalizedString(
            "ai.assistant.preview.change.name",
            value: "name -> %1$@",
            comment: "Change description for a name field. %1$@ is the new name."
        )
        static let changeRegularPrice = NSLocalizedString(
            "ai.assistant.preview.change.regular_price.no_currency",
            value: "price -> %1$@",
            comment: "Regular price change. %1$@ is the raw amount; no currency symbol because store currency varies."
        )
        static let changeSalePrice = NSLocalizedString(
            "ai.assistant.preview.change.sale_price.no_currency",
            value: "sale -> %1$@",
            comment: "Sale price change. %1$@ is the raw amount; no currency symbol because store currency varies."
        )
        static let changeSaleOff = NSLocalizedString(
            "ai.assistant.preview.change.sale_off",
            value: "sale -> off",
            comment: "Change description when the sale price is being cleared (turned off)."
        )
        static let changeStockQuantity = NSLocalizedString(
            "ai.assistant.preview.change.stock_quantity",
            value: "stock -> %1$d",
            comment: "Change description for stock quantity. %1$d is the new quantity."
        )
        static let changeStockStatus = NSLocalizedString(
            "ai.assistant.preview.change.stock_status",
            value: "stock status -> %1$@",
            comment: "Change description for stock status (e.g. instock, outofstock). %1$@ is the new value."
        )
        static let changeSku = NSLocalizedString(
            "ai.assistant.preview.change.sku",
            value: "sku -> %1$@",
            comment: "Change description for SKU. %1$@ is the new SKU."
        )
        static let changeStatus = NSLocalizedString(
            "ai.assistant.preview.change.status",
            value: "status -> %1$@",
            comment: "Change description for a status field. %1$@ is the new status."
        )
        static let changeCustomerNote = NSLocalizedString(
            "ai.assistant.preview.change.customer_note",
            value: "customer note updated",
            comment: "Change description when an order's customer note is being modified (the note text itself is not shown)."
        )
        static let changeBillingEmail = NSLocalizedString(
            "ai.assistant.preview.change.billing_email",
            value: "billing email -> %1$@",
            comment: "Change description for billing email. %1$@ is the new email address."
        )
    }
}

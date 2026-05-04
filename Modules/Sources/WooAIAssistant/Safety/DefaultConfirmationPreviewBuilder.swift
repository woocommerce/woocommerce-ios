import Foundation
import CocoaLumberjackSwift

public protocol ConfirmationPreviewBuilding: Sendable {
    func build(toolName: String,
               arguments: String,
               snapshot: ConfirmationSnapshot?) -> ConfirmationPreview?
}

public struct DefaultConfirmationPreviewBuilder: ConfirmationPreviewBuilding {

    public init() {}

    public func build(toolName: String,
                      arguments: String,
                      snapshot: ConfirmationSnapshot?) -> ConfirmationPreview? {
        switch toolName {
        case OrdersUpdateTool.name:
            return ordersUpdate(arguments: arguments, snapshot: snapshot)
        case OrdersBulkUpdateTool.name:
            return ordersBulkUpdate(arguments: arguments)
        case ProductsUpdateTool.name:
            return productsUpdate(arguments: arguments, snapshot: snapshot)
        case ProductsBulkUpdateTool.name:
            return productsBulkUpdate(arguments: arguments)
        case ProductVariationsUpdateTool.name:
            return productVariationsUpdate(arguments: arguments, snapshot: snapshot)
        case ProductVariationsBulkUpdateTool.name:
            return productVariationsBulkUpdate(arguments: arguments)
        default:
            return nil
        }
    }

    // MARK: - Orders

    private func ordersUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
        struct Args: Decodable {
            let id: Int?
            let status: String?
            let customer_note: String?
            let billing_email: String?
        }
        guard let args = decode(Args.self, from: arguments), let id = args.id else {
            return ConfirmationPreview(summary: .localized(Strings.ordersUpdateFallback))
        }

        var fields: [ConfirmationPreviewField] = []
        if let status = args.status {
            fields.append(.init(name: "status",
                                label: .localized(Strings.fieldStatus),
                                value: statusValue(status, isBulk: false),
                                priorValue: priorValue(for: "status", in: snapshot, currentValue: status)))
        }
        if args.customer_note != nil {
            fields.append(.init(name: "customer_note",
                                label: .localized(Strings.fieldCustomerNote),
                                value: .localized(Strings.fieldValueUpdated)))
        }
        if let email = args.billing_email {
            fields.append(.init(name: "billing_email",
                                label: .localized(Strings.fieldBillingEmail),
                                value: .raw(email)))
        }

        return ConfirmationPreview(
            summary: .localized(Strings.ordersUpdateSummary,
                                args: [.raw(String(id)), changeSummary(for: fields, status: args.status, isBulk: false)]),
            fields: fields
        )
    }

    private func ordersBulkUpdate(arguments: String) -> ConfirmationPreview {
        struct Args: Decodable {
            let ids: [Int]?
            let patch: Patch?
            struct Patch: Decodable {
                let status: String?
                let customer_note: String?
                let billing_email: String?
            }
        }
        guard let args = decode(Args.self, from: arguments),
              let ids = args.ids, let patch = args.patch else {
            return ConfirmationPreview(summary: .localized(Strings.ordersBulkUpdateFallback))
        }

        var fields: [ConfirmationPreviewField] = []
        if let status = patch.status {
            fields.append(.init(name: "status",
                                label: .localized(Strings.fieldStatus),
                                value: statusValue(status, isBulk: true)))
        }
        if patch.customer_note != nil {
            fields.append(.init(name: "customer_note",
                                label: .localized(Strings.fieldCustomerNote),
                                value: .localized(Strings.fieldValueUpdated)))
        }
        if let email = patch.billing_email {
            fields.append(.init(name: "billing_email",
                                label: .localized(Strings.fieldBillingEmail),
                                value: .raw(email)))
        }

        let summary: ConfirmationPreviewText = .quantity(
            ids.count,
            singular: Strings.ordersBulkUpdateSummarySingular,
            plural: Strings.ordersBulkUpdateSummaryPlural,
            args: [.raw(String(ids.count)), changeSummary(for: fields, status: patch.status, isBulk: true)]
        )
        return ConfirmationPreview(summary: summary, fields: fields, isBulk: true)
    }

    // MARK: - Products

    private func productsUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
        struct Args: Decodable {
            let id: Int?
            let name: String?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Int?
            let status: String?
        }
        guard let args = decode(Args.self, from: arguments), let id = args.id else {
            return ConfirmationPreview(summary: .localized(Strings.productsUpdateFallback))
        }
        let fields = productFields(name: args.name,
                                   regularPrice: args.regular_price,
                                   salePrice: args.sale_price,
                                   stockQuantity: args.stock_quantity,
                                   stockStatus: nil,
                                   sku: nil,
                                   status: args.status,
                                   includeName: true,
                                   includeStockStatus: false,
                                   includeSku: false,
                                   snapshot: snapshot)
        return ConfirmationPreview(
            summary: .localized(Strings.productsUpdateSummary,
                                args: [.raw(String(id)), changeSummary(for: fields, status: args.status, isBulk: false)]),
            fields: fields
        )
    }

    private func productsBulkUpdate(arguments: String) -> ConfirmationPreview {
        struct Args: Decodable {
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
        guard let args = decode(Args.self, from: arguments),
              let ids = args.ids, let patch = args.patch else {
            return ConfirmationPreview(summary: .localized(Strings.productsBulkUpdateFallback))
        }
        let fields = productFields(name: patch.name,
                                   regularPrice: patch.regular_price,
                                   salePrice: patch.sale_price,
                                   stockQuantity: patch.stock_quantity,
                                   stockStatus: nil,
                                   sku: nil,
                                   status: patch.status,
                                   includeName: true,
                                   includeStockStatus: false,
                                   includeSku: false,
                                   snapshot: nil)
        let summary: ConfirmationPreviewText = .quantity(
            ids.count,
            singular: Strings.productsBulkUpdateSummarySingular,
            plural: Strings.productsBulkUpdateSummaryPlural,
            args: [.raw(String(ids.count)), changeSummary(for: fields, status: patch.status, isBulk: true)]
        )
        return ConfirmationPreview(summary: summary, fields: fields, isBulk: true)
    }

    private func productVariationsUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
        struct Args: Decodable {
            let product_id: Int?
            let id: Int?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Int?
            let stock_status: String?
            let sku: String?
            let status: String?
        }
        guard let args = decode(Args.self, from: arguments),
              let pid = args.product_id, let vid = args.id else {
            return ConfirmationPreview(summary: .localized(Strings.productVariationsUpdateFallback))
        }
        let fields = productFields(name: nil,
                                   regularPrice: args.regular_price,
                                   salePrice: args.sale_price,
                                   stockQuantity: args.stock_quantity,
                                   stockStatus: args.stock_status,
                                   sku: args.sku,
                                   status: args.status,
                                   includeName: false,
                                   includeStockStatus: true,
                                   includeSku: true,
                                   snapshot: snapshot)
        return ConfirmationPreview(
            summary: .localized(Strings.productVariationsUpdateSummary,
                                args: [.raw(String(vid)), .raw(String(pid)),
                                       changeSummary(for: fields, status: args.status, isBulk: false)]),
            fields: fields
        )
    }

    private func productVariationsBulkUpdate(arguments: String) -> ConfirmationPreview {
        struct Args: Decodable {
            let product_id: Int?
            let variations: [V]?
            struct V: Decodable { let id: Int? }
        }
        guard let args = decode(Args.self, from: arguments),
              let pid = args.product_id, let variations = args.variations else {
            return ConfirmationPreview(summary: .localized(Strings.productVariationsBulkUpdateFallback))
        }
        let count = variations.count
        let summary: ConfirmationPreviewText = .quantity(
            count,
            singular: Strings.productVariationsBulkUpdateSummarySingular,
            plural: Strings.productVariationsBulkUpdateSummaryPlural,
            args: [.raw(String(count)), .raw(String(pid))]
        )
        return ConfirmationPreview(summary: summary, fields: [], isBulk: true)
    }

    // MARK: - Product field helpers

    private func productFields(name: String?,
                               regularPrice: String?,
                               salePrice: String?,
                               stockQuantity: Int?,
                               stockStatus: String?,
                               sku: String?,
                               status: String?,
                               includeName: Bool,
                               includeStockStatus: Bool,
                               includeSku: Bool,
                               snapshot: ConfirmationSnapshot?) -> [ConfirmationPreviewField] {
        var fields: [ConfirmationPreviewField] = []
        if includeName, let name {
            fields.append(.init(name: "name",
                                label: .localized(Strings.fieldName),
                                value: .raw(name),
                                priorValue: priorValue(for: "name", in: snapshot, currentValue: name)))
        }
        if let price = regularPrice {
            fields.append(.init(name: "regular_price",
                                label: .localized(Strings.fieldRegularPrice),
                                value: .raw(price),
                                priorValue: priorValue(for: "regular_price", in: snapshot, currentValue: price)))
        }
        if let sale = salePrice {
            let value: ConfirmationPreviewText = sale.isEmpty
                ? .localized(Strings.fieldValueOff)
                : .raw(sale)
            fields.append(.init(name: "sale_price",
                                label: .localized(Strings.fieldSalePrice),
                                value: value,
                                priorValue: priorSalePrice(in: snapshot, currentValue: sale)))
        }
        if let quantity = stockQuantity {
            let formatted = String(quantity)
            fields.append(.init(name: "stock_quantity",
                                label: .localized(Strings.fieldStockQuantity),
                                value: .raw(formatted),
                                priorValue: priorValue(for: "stock_quantity",
                                                       in: snapshot,
                                                       currentValue: formatted)))
        }
        if includeStockStatus, let stockStatus {
            fields.append(.init(name: "stock_status",
                                label: .localized(Strings.fieldStockStatus),
                                value: humanizedStockStatus(stockStatus),
                                priorValue: priorStockStatus(in: snapshot, currentValueRaw: stockStatus)))
        }
        if let status {
            fields.append(.init(name: "status",
                                label: .localized(Strings.fieldStatus),
                                value: .raw(status),
                                priorValue: priorValue(for: "status", in: snapshot, currentValue: status)))
        }
        if includeSku, let sku {
            fields.append(.init(name: "sku",
                                label: .localized(Strings.fieldSku),
                                value: .raw(sku),
                                priorValue: priorValue(for: "sku", in: snapshot, currentValue: sku)))
        }
        return fields
    }

    private func humanizedStockStatus(_ raw: String) -> ConfirmationPreviewText {
        switch raw {
        case "instock": return .localized(Strings.stockStatusInStock)
        case "outofstock": return .localized(Strings.stockStatusOutOfStock)
        case "onbackorder": return .localized(Strings.stockStatusOnBackorder)
        default: return .raw(raw)
        }
    }

    private func priorValue(for name: String,
                            in snapshot: ConfirmationSnapshot?,
                            currentValue: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues[name] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValue { return nil }
        return prior
    }

    private func priorSalePrice(in snapshot: ConfirmationSnapshot?,
                                currentValue: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues["sale_price"] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValue { return nil }
        if case .raw(let priorRaw) = prior, priorRaw.isEmpty {
            return .localized(Strings.fieldValueOff)
        }
        return prior
    }

    private func priorStockStatus(in snapshot: ConfirmationSnapshot?,
                                  currentValueRaw: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues["stock_status"] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValueRaw { return nil }
        if case .raw(let priorRaw) = prior {
            return humanizedStockStatus(priorRaw)
        }
        return prior
    }

    private func changeSummary(for fields: [ConfirmationPreviewField],
                               status: String?,
                               isBulk: Bool) -> ConfirmationPreviewText {
        guard !fields.isEmpty else {
            return .localized(Strings.changeSummaryEmpty)
        }
        let parts: [ConfirmationPreviewText] = fields.map { field in
            changeSummaryPart(for: field, status: status, isBulk: isBulk)
        }
        return joined(parts)
    }

    private func changeSummaryPart(for field: ConfirmationPreviewField,
                                   status: String?,
                                   isBulk: Bool) -> ConfirmationPreviewText {
        switch field.name {
        case "regular_price":
            return .localized(Strings.changeSummaryRegularPrice, args: [field.value])
        case "sale_price":
            return .localized(Strings.changeSummarySalePrice, args: [field.value])
        case "stock_quantity":
            return .localized(Strings.changeSummaryStockQuantity, args: [field.value])
        case "stock_status":
            return .localized(Strings.changeSummaryStockStatus, args: [field.value])
        case "sku":
            return .localized(Strings.changeSummarySku, args: [field.value])
        case "name":
            return .localized(Strings.changeSummaryName, args: [field.value])
        case "customer_note":
            return .localized(Strings.changeSummaryCustomerNote)
        case "billing_email":
            return .localized(Strings.changeSummaryBillingEmail, args: [field.value])
        case "status":
            return .localized(Strings.changeSummaryStatus, args: [field.value])
        default:
            return .localized(Strings.changeSummaryGenericField,
                              args: [.raw(field.name), field.value])
        }
    }

    private func statusValue(_ status: String, isBulk: Bool) -> ConfirmationPreviewText {
        guard customerNotifyingStatuses.contains(status) else { return .raw(status) }
        let template = isBulk ? Strings.statusValueEmailsCustomers : Strings.statusValueEmailsCustomer
        return .localized(template, args: [.raw(status)])
    }

    private func joined(_ parts: [ConfirmationPreviewText]) -> ConfirmationPreviewText {
        guard let first = parts.first else {
            return .localized(Strings.changeSummaryEmpty)
        }
        return parts.dropFirst().reduce(first) { left, right in
            .localized(Strings.changeSummaryListSeparator, args: [left, right])
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DDLogError("DefaultConfirmationPreviewBuilder decode \(type) failed: \(error)")
            return nil
        }
    }

    private let customerNotifyingStatuses: Set<String> = [
        "processing", "completed", "cancelled", "refunded", "on-hold"
    ]
}

private enum Strings {
    static let ordersUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.orders_update.fallback",
        defaultValue: "Update an order"
    )
    static let ordersUpdateSummary = LocalizedStringResource(
        "ai.assistant.preview.orders_update.summary",
        defaultValue: "Update order #%@: %@"
    )
    static let ordersBulkUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.fallback",
        defaultValue: "Update many orders"
    )
    static let ordersBulkUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.summary.singular",
        defaultValue: "Update %@ order: %@"
    )
    static let ordersBulkUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.summary.plural",
        defaultValue: "Update %@ orders: %@"
    )
    static let productsUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.products_update.fallback",
        defaultValue: "Update a product"
    )
    static let productsUpdateSummary = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary",
        defaultValue: "Update product #%@: %@"
    )
    static let productsBulkUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.fallback",
        defaultValue: "Update many products"
    )
    static let productsBulkUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.summary.singular",
        defaultValue: "Update %@ product: %@"
    )
    static let productsBulkUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.summary.plural",
        defaultValue: "Update %@ products: %@"
    )
    static let productVariationsUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.product_variations_update.fallback",
        defaultValue: "Update product variation"
    )
    static let productVariationsUpdateSummary = LocalizedStringResource(
        "ai.assistant.preview.product_variations_update.summary",
        defaultValue: "Update variation #%@ of product #%@: %@"
    )
    static let productVariationsBulkUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.product_variations_bulk_update.fallback",
        defaultValue: "Update many variations"
    )
    static let productVariationsBulkUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.product_variations_bulk_update.summary.singular",
        defaultValue: "Update %@ variation of product #%@"
    )
    static let productVariationsBulkUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.product_variations_bulk_update.summary.plural",
        defaultValue: "Update %@ variations of product #%@"
    )

    static let fieldName = LocalizedStringResource(
        "ai.assistant.preview.field.name",
        defaultValue: "Name"
    )
    static let fieldStatus = LocalizedStringResource(
        "ai.assistant.preview.field.status",
        defaultValue: "Status"
    )
    static let fieldRegularPrice = LocalizedStringResource(
        "ai.assistant.preview.field.regular_price",
        defaultValue: "Price"
    )
    static let fieldSalePrice = LocalizedStringResource(
        "ai.assistant.preview.field.sale_price",
        defaultValue: "Sale"
    )
    static let fieldStockQuantity = LocalizedStringResource(
        "ai.assistant.preview.field.stock_quantity",
        defaultValue: "Stock"
    )
    static let fieldStockStatus = LocalizedStringResource(
        "ai.assistant.preview.field.stock_status",
        defaultValue: "Stock status"
    )
    static let fieldSku = LocalizedStringResource(
        "ai.assistant.preview.field.sku",
        defaultValue: "SKU"
    )
    static let fieldCustomerNote = LocalizedStringResource(
        "ai.assistant.preview.field.customer_note",
        defaultValue: "Customer note"
    )
    static let fieldBillingEmail = LocalizedStringResource(
        "ai.assistant.preview.field.billing_email",
        defaultValue: "Billing email"
    )
    static let fieldValueUpdated = LocalizedStringResource(
        "ai.assistant.preview.field.value.updated",
        defaultValue: "updated"
    )
    static let fieldValueOff = LocalizedStringResource(
        "ai.assistant.preview.field.value.off",
        defaultValue: "off"
    )

    static let stockStatusInStock = LocalizedStringResource(
        "ai.assistant.preview.stock_status.instock",
        defaultValue: "In stock"
    )
    static let stockStatusOutOfStock = LocalizedStringResource(
        "ai.assistant.preview.stock_status.outofstock",
        defaultValue: "Out of stock"
    )
    static let stockStatusOnBackorder = LocalizedStringResource(
        "ai.assistant.preview.stock_status.onbackorder",
        defaultValue: "On backorder"
    )

    static let changeSummaryEmpty = LocalizedStringResource(
        "ai.assistant.preview.change_summary.empty",
        defaultValue: "edit fields"
    )
    static let changeSummaryListSeparator = LocalizedStringResource(
        "ai.assistant.preview.change_summary.separator",
        defaultValue: "%@, %@"
    )
    static let changeSummaryName = LocalizedStringResource(
        "ai.assistant.preview.change_summary.name",
        defaultValue: "name -> %@"
    )
    static let changeSummaryRegularPrice = LocalizedStringResource(
        "ai.assistant.preview.change_summary.regular_price",
        defaultValue: "price -> %@"
    )
    static let changeSummarySalePrice = LocalizedStringResource(
        "ai.assistant.preview.change_summary.sale_price",
        defaultValue: "sale -> %@"
    )
    static let changeSummaryStockQuantity = LocalizedStringResource(
        "ai.assistant.preview.change_summary.stock_quantity",
        defaultValue: "stock -> %@"
    )
    static let changeSummaryStockStatus = LocalizedStringResource(
        "ai.assistant.preview.change_summary.stock_status",
        defaultValue: "stock status -> %@"
    )
    static let changeSummarySku = LocalizedStringResource(
        "ai.assistant.preview.change_summary.sku",
        defaultValue: "sku -> %@"
    )
    static let changeSummaryStatus = LocalizedStringResource(
        "ai.assistant.preview.change_summary.status",
        defaultValue: "status -> %@"
    )
    static let statusValueEmailsCustomer = LocalizedStringResource(
        "ai.assistant.preview.status_value.emails_customer",
        defaultValue: "%@ (emails the customer)"
    )
    static let statusValueEmailsCustomers = LocalizedStringResource(
        "ai.assistant.preview.status_value.emails_customers",
        defaultValue: "%@ (emails customers)"
    )
    static let changeSummaryCustomerNote = LocalizedStringResource(
        "ai.assistant.preview.change_summary.customer_note",
        defaultValue: "customer note updated"
    )
    static let changeSummaryBillingEmail = LocalizedStringResource(
        "ai.assistant.preview.change_summary.billing_email",
        defaultValue: "billing email -> %@"
    )
    static let changeSummaryGenericField = LocalizedStringResource(
        "ai.assistant.preview.change_summary.generic",
        defaultValue: "%@ -> %@"
    )
}

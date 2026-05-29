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
            return ordersBulkUpdate(arguments: arguments, snapshot: snapshot)
        case ProductsUpdateTool.name:
            return productsUpdate(arguments: arguments, snapshot: snapshot)
        case ProductsBulkUpdateTool.name:
            return productsBulkUpdate(arguments: arguments, snapshot: snapshot)
        case ProductVariationsUpdateTool.name:
            return productVariationsUpdate(arguments: arguments, snapshot: snapshot)
        case ProductVariationsBulkUpdateTool.name:
            return productVariationsBulkUpdate(arguments: arguments, snapshot: snapshot)
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

        let fields = orderFields(status: args.status,
                                 customerNote: args.customer_note,
                                 billingEmail: args.billing_email,
                                 snapshot: snapshot,
                                 isBulk: false)

        let summary: ConfirmationPreviewText
        if let name = snapshot?.displayName {
            summary = .localized(Strings.ordersUpdateSummaryNamed,
                                 args: [.raw(name), .raw(String(id))])
        } else {
            summary = .localized(Strings.ordersUpdateSummary, args: [.raw(String(id))])
        }
        return ConfirmationPreview(summary: summary, fields: fields)
    }

    private func ordersBulkUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
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

        let fields = orderFields(status: patch.status,
                                 customerNote: patch.customer_note,
                                 billingEmail: patch.billing_email,
                                 snapshot: nil,
                                 isBulk: true)

        let summary: ConfirmationPreviewText = .quantity(
            ids.count,
            singular: Strings.ordersBulkUpdateSummarySingular,
            plural: Strings.ordersBulkUpdateSummaryPlural,
            args: [.raw(String(ids.count))]
        )
        let bulkEntries = snapshot?.bulkEntries ?? ids.map { ConfirmationBulkEntry(id: $0) }
        return ConfirmationPreview(summary: summary,
                                   fields: fields,
                                   isBulk: true,
                                   bulkEntries: bulkEntries)
    }

    private func orderFields(status: String?,
                             customerNote: String?,
                             billingEmail: String?,
                             snapshot: ConfirmationSnapshot?,
                             isBulk: Bool) -> [ConfirmationPreviewField] {
        var fields: [ConfirmationPreviewField] = []
        if let status {
            fields.append(.init(name: "status",
                                label: .localized(Strings.fieldStatus),
                                value: orderStatusValue(status, isBulk: isBulk),
                                priorValue: isBulk ? nil : priorOrderStatus(in: snapshot,
                                                                            currentValueRaw: status)))
        }
        if let note = customerNote {
            fields.append(.init(name: "customer_note",
                                label: .localized(Strings.fieldCustomerNote),
                                value: customerNoteValue(note)))
        }
        if let email = billingEmail {
            fields.append(.init(name: "billing_email",
                                label: .localized(Strings.fieldBillingEmail),
                                value: .raw(email),
                                priorValue: isBulk ? nil : priorValue(for: "billing_email",
                                                                      in: snapshot,
                                                                      currentValue: email)))
        }
        return fields
    }

    private func customerNoteValue(_ note: String) -> ConfirmationPreviewText {
        if note.isEmpty { return .localized(Strings.fieldValueUpdated) }
        if note.count > Self.customerNotePreviewLimit {
            return .raw(String(note.prefix(Self.customerNotePreviewLimit)) + "...")
        }
        return .raw(note)
    }

    private static let customerNotePreviewLimit = 160

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
        let summary: ConfirmationPreviewText
        if let name = snapshot?.displayName {
            summary = .localized(Strings.productsUpdateSummaryNamed,
                                 args: [.raw(name), .raw(String(id))])
        } else {
            summary = .localized(Strings.productsUpdateSummary, args: [.raw(String(id))])
        }
        return ConfirmationPreview(summary: summary, fields: fields)
    }

    private func productsBulkUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
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
            args: [.raw(String(ids.count))]
        )
        let bulkEntries = snapshot?.bulkEntries ?? ids.map { ConfirmationBulkEntry(id: $0) }
        return ConfirmationPreview(summary: summary,
                                   fields: fields,
                                   isBulk: true,
                                   bulkEntries: bulkEntries)
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
                                args: [.raw(String(vid)), .raw(String(pid))]),
            fields: fields
        )
    }

    private func productVariationsBulkUpdate(arguments: String, snapshot: ConfirmationSnapshot?) -> ConfirmationPreview {
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
        let bulkEntries = snapshot?.bulkEntries
            ?? variations.compactMap(\.id).map { ConfirmationBulkEntry(id: $0) }
        return ConfirmationPreview(summary: summary,
                                   fields: [],
                                   isBulk: true,
                                   bulkEntries: bulkEntries)
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
                                value: .raw(Self.humanizedProductStatus(status)),
                                priorValue: priorProductStatus(in: snapshot, currentValueRaw: status)))
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

    private func orderStatusValue(_ status: String, isBulk: Bool) -> ConfirmationPreviewText {
        let humanized = Self.humanizedOrderStatus(status)
        guard customerNotifyingStatuses.contains(status) else { return .raw(humanized) }
        let template = isBulk ? Strings.statusValueEmailsCustomers : Strings.statusValueEmailsCustomer
        return .localized(template, args: [.raw(humanized)])
    }

    private func priorOrderStatus(in snapshot: ConfirmationSnapshot?,
                                  currentValueRaw: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues["status"] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValueRaw { return nil }
        if case .raw(let priorRaw) = prior {
            return .raw(Self.humanizedOrderStatus(priorRaw))
        }
        return prior
    }

    private func priorProductStatus(in snapshot: ConfirmationSnapshot?,
                                    currentValueRaw: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues["status"] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValueRaw { return nil }
        if case .raw(let priorRaw) = prior {
            return .raw(Self.humanizedProductStatus(priorRaw))
        }
        return prior
    }

    private static func humanizedOrderStatus(_ raw: String) -> String {
        switch raw {
        case "on-hold": return "On hold"
        case "checkout-draft": return "Checkout draft"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }

    private static func humanizedProductStatus(_ raw: String) -> String {
        raw.prefix(1).uppercased() + raw.dropFirst()
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
        "ai.assistant.preview.orders_update.summary.headline",
        defaultValue: "Update order #%@"
    )
    static let ordersUpdateSummaryNamed = LocalizedStringResource(
        "ai.assistant.preview.orders_update.summary.headline.named",
        defaultValue: "Update order from %@ (#%@)"
    )
    static let ordersBulkUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.fallback",
        defaultValue: "Update many orders"
    )
    static let ordersBulkUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.summary.headline.singular",
        defaultValue: "Update %@ order"
    )
    static let ordersBulkUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.orders_bulk_update.summary.headline.plural",
        defaultValue: "Update %@ orders"
    )
    static let productsUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.products_update.fallback",
        defaultValue: "Update a product"
    )
    static let productsUpdateSummary = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.headline",
        defaultValue: "Update product #%@"
    )
    static let productsUpdateSummaryNamed = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.headline.named",
        defaultValue: "Update %@ (#%@)"
    )
    static let productsBulkUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.fallback",
        defaultValue: "Update many products"
    )
    static let productsBulkUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.summary.headline.singular",
        defaultValue: "Update %@ product"
    )
    static let productsBulkUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.products_bulk_update.summary.headline.plural",
        defaultValue: "Update %@ products"
    )
    static let productVariationsUpdateFallback = LocalizedStringResource(
        "ai.assistant.preview.product_variations_update.fallback",
        defaultValue: "Update product variation"
    )
    static let productVariationsUpdateSummary = LocalizedStringResource(
        "ai.assistant.preview.product_variations_update.summary.headline",
        defaultValue: "Update variation #%@ of product #%@"
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
        "ai.assistant.preview.field.value.updated_marker",
        defaultValue: "Updated"
    )
    static let fieldValueOff = LocalizedStringResource(
        "ai.assistant.preview.field.value.off_marker",
        defaultValue: "Off"
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

    static let statusValueEmailsCustomer = LocalizedStringResource(
        "ai.assistant.preview.status_value.emails_customer",
        defaultValue: "%@ (emails the customer)"
    )
    static let statusValueEmailsCustomers = LocalizedStringResource(
        "ai.assistant.preview.status_value.emails_customers",
        defaultValue: "%@ (emails customers)"
    )
}

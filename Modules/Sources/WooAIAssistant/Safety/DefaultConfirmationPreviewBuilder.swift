import Foundation
import CocoaLumberjackSwift
import enum NetworkingCore.OrderStatusEnum
import enum Networking.ProductStatus
import enum Networking.ProductStockStatus

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
        guard let args = decode(ProductsUpdateArgs.self, from: arguments),
              let updates = args.updates, !updates.isEmpty else {
            return ConfirmationPreview(summary: .localized(Strings.productsUpdateFallback))
        }
        let breakdown = Self.classify(updates: updates)
        guard breakdown.totalEntries > 0 else {
            return ConfirmationPreview(summary: .localized(Strings.productsUpdateFallback))
        }
        let summary = Self.productsUpdateSummary(breakdown: breakdown)
        var combinedKeys: [String] = []
        var seenKeys: Set<String> = []
        for entry in updates {
            for key in entry.changedKeys where !seenKeys.contains(key) {
                seenKeys.insert(key)
                combinedKeys.append(key)
            }
        }
        let isBulk = breakdown.totalEntries > 1
        let fields = combinedKeys.map { key in
            Self.productField(for: key, across: updates, snapshot: snapshot, isBulk: isBulk)
        }
        let bulkEntries = snapshot?.bulkEntries ?? breakdown.targetIDs.map { ConfirmationBulkEntry(id: $0) }
        return ConfirmationPreview(summary: summary,
                                   fields: fields,
                                   isBulk: isBulk,
                                   bulkEntries: bulkEntries)
    }

    private struct ProductsUpdateBreakdown {
        var simpleProductCount: Int = 0
        var variationCount: Int = 0
        var targetIDs: [Int] = []
        var totalEntries: Int { simpleProductCount + variationCount }
    }

    private static func classify(updates: [ProductsUpdateEntry]) -> ProductsUpdateBreakdown {
        var breakdown = ProductsUpdateBreakdown()
        for entry in updates {
            guard let target = entry.target, let id = target.id else { continue }
            breakdown.targetIDs.append(id)
            if target.kind == "variation" {
                breakdown.variationCount += 1
            } else {
                breakdown.simpleProductCount += 1
            }
        }
        return breakdown
    }

    private static func productsUpdateSummary(breakdown: ProductsUpdateBreakdown) -> ConfirmationPreviewText {
        let products = breakdown.simpleProductCount
        let variations = breakdown.variationCount
        if variations == 0 {
            return .quantity(products,
                             singular: Strings.productsUpdateSummarySingular,
                             plural: Strings.productsUpdateSummaryPlural,
                             args: [.raw(String(products))])
        }
        if products == 0 {
            return .quantity(variations,
                             singular: Strings.productsUpdateSummaryVariationSingular,
                             plural: Strings.productsUpdateSummaryVariationPlural,
                             args: [.raw(String(variations))])
        }
        // Pluralize each clause independently so "1 product and 1 variation" reads naturally.
        let productClause: ConfirmationPreviewText = .quantity(
            products,
            singular: Strings.productsUpdateClauseProductSingular,
            plural: Strings.productsUpdateClauseProductPlural,
            args: [.raw(String(products))]
        )
        let variationClause: ConfirmationPreviewText = .quantity(
            variations,
            singular: Strings.productsUpdateClauseVariationSingular,
            plural: Strings.productsUpdateClauseVariationPlural,
            args: [.raw(String(variations))]
        )
        return .localized(Strings.productsUpdateSummaryMixed,
                          args: [productClause, variationClause])
    }

    private struct ProductsUpdateArgs: Decodable {
        let updates: [ProductsUpdateEntry]?
    }

    private static func productFieldLabel(for key: String) -> ConfirmationPreviewText {
        switch key {
        case "regular_price": return .localized(Strings.fieldRegularPrice)
        case "sale_price": return .localized(Strings.fieldSalePrice)
        case "stock_quantity": return .localized(Strings.fieldStockQuantity)
        case "status": return .localized(Strings.fieldStatus)
        case "name": return .localized(Strings.fieldName)
        case "stock_status": return .localized(Strings.fieldStockStatus)
        case "sku": return .localized(Strings.fieldSKU)
        default: return .raw(key)
        }
    }

    private static func productField(for key: String,
                                     across updates: [ProductsUpdateEntry],
                                     snapshot: ConfirmationSnapshot?,
                                     isBulk: Bool) -> ConfirmationPreviewField {
        let label = productFieldLabel(for: key)
        let valuesWithEntries = updates.compactMap { entry -> ConfirmationPreviewText? in
            productFieldValue(for: key, entry: entry)
        }
        // Distinct on the flattened text so equivalent renderings (e.g. both "Cleared") collapse.
        let distinct = Set(valuesWithEntries.map { $0.flattened() })
        if let only = valuesWithEntries.first, distinct.count == 1, valuesWithEntries.count == updates.count {
            let prior = isBulk ? nil : productPriorValue(for: key, in: snapshot, newValue: only)
            return ConfirmationPreviewField(name: key, label: label, value: only, priorValue: prior)
        }
        // Divergent or partial coverage: a single placeholder is the most the base card can render.
        return ConfirmationPreviewField(name: key, label: label, value: .localized(Strings.fieldValueUpdated))
    }

    private static func productPriorValue(for key: String,
                                          in snapshot: ConfirmationSnapshot?,
                                          newValue: ConfirmationPreviewText) -> ConfirmationPreviewText? {
        guard let prior = snapshot?.currentValues[key] else { return nil }
        // Same rendered text means there is no diff to show.
        guard prior.flattened() != newValue.flattened() else { return nil }
        return prior
    }

    /// Returns a rendered value when `entry` has set `key`, or nil so the caller can tell
    /// "entry did not change this key" apart from "entry changed it to an empty string".
    private static func productFieldValue(for key: String,
                                          entry: ProductsUpdateEntry) -> ConfirmationPreviewText? {
        switch key {
        case "regular_price":
            guard let value = entry.regularPrice else { return nil }
            if value.isEmpty { return .localized(Strings.fieldValueUpdated) }
            return .raw(value)
        case "sale_price":
            guard let value = entry.salePrice else { return nil }
            if value.isEmpty { return .localized(Strings.fieldValueCleared) }
            return .raw(value)
        case "stock_quantity":
            guard let value = entry.stockQuantity else { return nil }
            return .raw(String(value))
        case "status":
            guard let value = entry.status else { return nil }
            return .raw(ProductStatus(rawValue: value).description)
        case "name":
            guard let value = entry.name else { return nil }
            if value.isEmpty { return .localized(Strings.fieldValueUpdated) }
            return .raw(value)
        case "stock_status":
            guard let value = entry.stockStatus else { return nil }
            return .raw(ProductStockStatus(rawValue: value).description)
        case "sku":
            guard let value = entry.sku else { return nil }
            return .raw(value)
        default:
            return nil
        }
    }

    // MARK: - Order field helpers

    private func priorValue(for name: String,
                            in snapshot: ConfirmationSnapshot?,
                            currentValue: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues[name] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValue { return nil }
        return prior
    }

    private func orderStatusValue(_ status: String, isBulk: Bool) -> ConfirmationPreviewText {
        let humanized = OrderStatusEnum(rawValue: status).localizedName
        guard customerNotifyingStatuses.contains(status) else { return .raw(humanized) }
        let template = isBulk ? Strings.statusValueEmailsCustomers : Strings.statusValueEmailsCustomer
        return .localized(template, args: [.raw(humanized)])
    }

    private func priorOrderStatus(in snapshot: ConfirmationSnapshot?,
                                  currentValueRaw: String) -> ConfirmationPreviewText? {
        guard let snapshot, let prior = snapshot.currentValues["status"] else { return nil }
        if case .raw(let priorRaw) = prior, priorRaw == currentValueRaw { return nil }
        if case .raw(let priorRaw) = prior {
            return .raw(OrderStatusEnum(rawValue: priorRaw).localizedName)
        }
        return prior
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
        defaultValue: "Update products"
    )
    static let productsUpdateSummarySingular = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.headline.singular",
        defaultValue: "Update %@ product"
    )
    static let productsUpdateSummaryPlural = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.headline.plural",
        defaultValue: "Update %@ products"
    )
    static let productsUpdateSummaryVariationSingular = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.variations.singular",
        defaultValue: "Update %@ variation"
    )
    static let productsUpdateSummaryVariationPlural = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.variations.plural",
        defaultValue: "Update %@ variations"
    )
    static let productsUpdateSummaryMixed = LocalizedStringResource(
        "ai.assistant.preview.products_update.summary.headline.mixed.v2",
        defaultValue: "Update %1$@ and %2$@"
    )
    static let productsUpdateClauseProductSingular = LocalizedStringResource(
        "ai.assistant.preview.products_update.clause.product.singular",
        defaultValue: "%@ product"
    )
    static let productsUpdateClauseProductPlural = LocalizedStringResource(
        "ai.assistant.preview.products_update.clause.product.plural",
        defaultValue: "%@ products"
    )
    static let productsUpdateClauseVariationSingular = LocalizedStringResource(
        "ai.assistant.preview.products_update.clause.variation.singular",
        defaultValue: "%@ variation"
    )
    static let productsUpdateClauseVariationPlural = LocalizedStringResource(
        "ai.assistant.preview.products_update.clause.variation.plural",
        defaultValue: "%@ variations"
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
    static let fieldName = LocalizedStringResource(
        "ai.assistant.preview.field.name",
        defaultValue: "Name"
    )
    static let fieldStockStatus = LocalizedStringResource(
        "ai.assistant.preview.field.stock_status",
        defaultValue: "Stock status"
    )
    static let fieldSKU = LocalizedStringResource(
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
    static let fieldValueCleared = LocalizedStringResource(
        "ai.assistant.preview.field.value.cleared_marker",
        defaultValue: "Cleared"
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

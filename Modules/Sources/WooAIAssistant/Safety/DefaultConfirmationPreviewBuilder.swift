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
        let ids = updates.compactMap(\.id)
        let count = ids.count
        let summary: ConfirmationPreviewText = .quantity(
            count,
            singular: Strings.productsUpdateSummarySingular,
            plural: Strings.productsUpdateSummaryPlural,
            args: [.raw(String(count))]
        )
        var combinedKeys: [String] = []
        var seenKeys: Set<String> = []
        for entry in updates {
            for key in entry.changedKeys where !seenKeys.contains(key) {
                seenKeys.insert(key)
                combinedKeys.append(key)
            }
        }
        let isBulk = count > 1
        let fields = combinedKeys.map { key in
            Self.productField(for: key, across: updates, snapshot: snapshot, isBulk: isBulk)
        }
        let bulkEntries = snapshot?.bulkEntries ?? ids.map { ConfirmationBulkEntry(id: $0) }
        return ConfirmationPreview(summary: summary,
                                   fields: fields,
                                   isBulk: isBulk,
                                   bulkEntries: bulkEntries)
    }

    private struct ProductsUpdateArgs: Decodable {
        let updates: [ProductsUpdateEntry]?
    }

    private static func productFieldLabel(for key: String) -> ConfirmationPreviewText {
        switch key {
        case "regular_price": return .localized(Strings.fieldRegularPrice)
        case "sale_price": return .localized(Strings.fieldSalePrice)
        case "percent_discount": return .localized(Strings.fieldPercentDiscount)
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
        // Partial coverage (some entries set the key, others omit it) is treated as "varies" so the
        // safety preview never implies a uniform change that would not be applied to every entity.
        if valuesWithEntries.count < updates.count {
            return ConfirmationPreviewField(name: key, label: label, value: .localized(Strings.variesPerItem))
        }
        // Distinct on the flattened text so equivalent renderings (e.g. both "Cleared") collapse.
        let distinct = Set(valuesWithEntries.map { $0.flattened() })
        if let only = valuesWithEntries.first, distinct.count == 1 {
            let prior = isBulk ? nil : productPriorValue(for: key, in: snapshot, newValue: only)
            return ConfirmationPreviewField(name: key, label: label, value: only, priorValue: prior)
        }
        if distinct.isEmpty {
            return ConfirmationPreviewField(name: key, label: label, value: .localized(Strings.fieldValueUpdated))
        }
        return ConfirmationPreviewField(name: key, label: label, value: .localized(Strings.variesPerItem))
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
        case "percent_discount":
            guard let value = entry.percentDiscount else { return nil }
            return .localized(Strings.percentDiscountFormat, args: [.raw(formatPercent(value))])
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

    private static func formatPercent(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%g", value)
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
    static let fieldPercentDiscount = LocalizedStringResource(
        "ai.assistant.preview.field.percent_discount",
        defaultValue: "Discount"
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
    static let variesPerItem = LocalizedStringResource(
        "ai.assistant.preview.products_update.field.varies",
        defaultValue: "varies per item"
    )
    static let percentDiscountFormat = LocalizedStringResource(
        "ai.assistant.preview.field.percent_discount.value",
        defaultValue: "%@%% off"
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

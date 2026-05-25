import Foundation
import CocoaLumberjackSwift

public struct DefaultConfirmationSnapshotResolver: ConfirmationSnapshotResolving {

    private let client: WCRESTClient

    public init(client: WCRESTClient) {
        self.client = client
    }

    public func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot? {
        switch toolName {
        case OrdersUpdateTool.name:
            return await resolveOrder(arguments: arguments)
        case ProductsUpdateTool.name:
            return await resolveProduct(arguments: arguments)
        case ProductVariationsUpdateTool.name:
            return await resolveVariation(arguments: arguments)
        case OrdersBulkUpdateTool.name:
            return await resolveOrdersBulk(arguments: arguments)
        case ProductsBulkUpdateTool.name:
            return await resolveProductsBulk(arguments: arguments)
        case ProductVariationsBulkUpdateTool.name:
            return await resolveProductVariationsBulk(arguments: arguments)
        default:
            return nil
        }
    }

    private func resolveOrder(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let id: Int? }
        guard let parsed = decode(Args.self, from: arguments), let id = parsed.id else {
            return nil
        }
        struct OrderResponse: Decodable {
            let status: String?
            let billing: Billing?
            struct Billing: Decodable {
                let email: String?
                let first_name: String?
                let last_name: String?
            }
        }
        guard let order = await fetch(OrderResponse.self, path: "wc/v3/orders/\(id)") else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let status = order.status {
            values["status"] = .raw(Self.normalizeOrderStatus(status))
        }
        if let email = order.billing?.email, !email.isEmpty {
            values["billing_email"] = .raw(email)
        }
        let displayName = Self.composedCustomerName(first: order.billing?.first_name,
                                                    last: order.billing?.last_name)
        guard !values.isEmpty || displayName != nil else { return nil }
        return ConfirmationSnapshot(currentValues: values, displayName: displayName)
    }

    private func resolveProduct(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let id: Int? }
        guard let parsed = decode(Args.self, from: arguments), let id = parsed.id else {
            return nil
        }
        struct ProductResponse: Decodable {
            let name: String?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Double?
            let status: String?
        }
        guard let product = await fetch(ProductResponse.self, path: "wc/v3/products/\(id)") else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let name = product.name { values["name"] = .raw(name) }
        if let price = product.regular_price { values["regular_price"] = .raw(price) }
        if let sale = product.sale_price { values["sale_price"] = .raw(sale) }
        if let quantity = product.stock_quantity {
            values["stock_quantity"] = .raw(Self.formatStockQuantity(quantity))
        }
        if let status = product.status { values["status"] = .raw(status) }
        let displayName = product.name?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmptyOrNil
        guard !values.isEmpty || displayName != nil else { return nil }
        return ConfirmationSnapshot(currentValues: values, displayName: displayName)
    }

    private func resolveVariation(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable {
            let product_id: Int?
            let id: Int?
        }
        guard let parsed = decode(Args.self, from: arguments),
              let productID = parsed.product_id, let variationID = parsed.id else {
            return nil
        }
        struct VariationResponse: Decodable {
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Double?
            let stock_status: String?
            let sku: String?
            let status: String?
        }
        let path = "wc/v3/products/\(productID)/variations/\(variationID)"
        guard let variation = await fetch(VariationResponse.self, path: path) else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let price = variation.regular_price { values["regular_price"] = .raw(price) }
        if let sale = variation.sale_price { values["sale_price"] = .raw(sale) }
        if let quantity = variation.stock_quantity {
            values["stock_quantity"] = .raw(Self.formatStockQuantity(quantity))
        }
        if let stockStatus = variation.stock_status { values["stock_status"] = .raw(stockStatus) }
        if let sku = variation.sku { values["sku"] = .raw(sku) }
        if let status = variation.status { values["status"] = .raw(status) }
        return values.isEmpty ? nil : ConfirmationSnapshot(currentValues: values)
    }

    private func resolveOrdersBulk(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let ids: [Int]? }
        guard let parsed = decode(Args.self, from: arguments),
              let ids = parsed.ids, !ids.isEmpty else { return nil }
        struct OrderResponse: Decodable {
            let id: Int?
            let billing: Billing?
            struct Billing: Decodable {
                let first_name: String?
                let last_name: String?
            }
        }
        let entries = await fetchBulkEntries(ids: ids,
                                             path: "wc/v3/orders",
                                             type: [OrderResponse].self) { response in
            ConfirmationBulkEntry(id: response.id ?? 0,
                                  displayName: Self.composedCustomerName(first: response.billing?.first_name,
                                                                         last: response.billing?.last_name))
        }
        return ConfirmationSnapshot(currentValues: [:], bulkEntries: entries)
    }

    private func resolveProductsBulk(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let ids: [Int]? }
        guard let parsed = decode(Args.self, from: arguments),
              let ids = parsed.ids, !ids.isEmpty else { return nil }
        struct ProductResponse: Decodable {
            let id: Int?
            let name: String?
        }
        let entries = await fetchBulkEntries(ids: ids,
                                             path: "wc/v3/products",
                                             type: [ProductResponse].self) { response in
            ConfirmationBulkEntry(id: response.id ?? 0, displayName: response.name)
        }
        return ConfirmationSnapshot(currentValues: [:], bulkEntries: entries)
    }

    private func resolveProductVariationsBulk(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable {
            let product_id: Int?
            let variations: [V]?
            struct V: Decodable { let id: Int? }
        }
        guard let parsed = decode(Args.self, from: arguments),
              let productID = parsed.product_id,
              let variations = parsed.variations else { return nil }
        let ids = variations.compactMap(\.id)
        guard !ids.isEmpty else { return nil }
        struct VariationResponse: Decodable {
            let id: Int?
            let sku: String?
            let attributes: [Attribute]?
            struct Attribute: Decodable {
                let option: String?
            }
        }
        let entries = await fetchBulkEntries(ids: ids,
                                             path: "wc/v3/products/\(productID)/variations",
                                             type: [VariationResponse].self) { response in
            // Compose attribute options ("Red, Small") for a meaningful row label.
            // Variations rarely have SKUs and never have a top-level name, so the
            // attribute combo is the most useful identifier we can show.
            let attributeLabel = response.attributes?
                .compactMap { $0.option?.trimmingCharacters(in: .whitespaces).nonEmptyOrNil }
                .joined(separator: ", ")
                .nonEmptyOrNil
            return ConfirmationBulkEntry(id: response.id ?? 0,
                                         displayName: attributeLabel ?? response.sku?.nonEmptyOrNil)
        }
        return ConfirmationSnapshot(currentValues: [:], bulkEntries: entries)
    }

    private func fetchBulkEntries<Response: Decodable>(
        ids: [Int],
        path: String,
        type: [Response].Type,
        map: (Response) -> ConfirmationBulkEntry
    ) async -> [ConfirmationBulkEntry] {
        let include = ids.map(String.init).joined(separator: ",")
        let query = ["include": include, "per_page": String(ids.count)]
        let response = await client.request(method: "GET", path: path, query: query, body: nil)
        guard (200..<300).contains(response.statusCode) else {
            DDLogError("DefaultConfirmationSnapshotResolver bulk fetch \(path) returned HTTP \(response.statusCode)")
            return ids.map { ConfirmationBulkEntry(id: $0) }
        }
        guard let decoded = try? JSONDecoder().decode(type, from: response.data) else {
            return ids.map { ConfirmationBulkEntry(id: $0) }
        }
        let resolved = decoded.map(map)
        let resolvedByID = Dictionary(uniqueKeysWithValues: resolved.map { ($0.id, $0) })
        // Preserve the requested id order; substitute id-only entries for any the API skipped.
        return ids.map { id in resolvedByID[id] ?? ConfirmationBulkEntry(id: id) }
    }

    private func fetch<T: Decodable>(_ type: T.Type, path: String) async -> T? {
        let response = await client.request(method: "GET", path: path, query: nil, body: nil)
        guard (200..<300).contains(response.statusCode) else {
            DDLogError("DefaultConfirmationSnapshotResolver fetch \(path) returned HTTP \(response.statusCode)")
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: response.data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver decode \(type) failed: \(error)")
            return nil
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver args decode \(type) failed: \(error)")
            return nil
        }
    }

    static func normalizeOrderStatus(_ raw: String) -> String {
        raw.hasPrefix("wc-") ? String(raw.dropFirst(3)) : raw
    }

    static func formatStockQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(Int(value))
        }
        return String(value)
    }

    static func composedCustomerName(first: String?, last: String?) -> String? {
        let parts = [first, last]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}

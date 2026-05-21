import Foundation
import CocoaLumberjackSwift
import enum Networking.ProductStatus
import enum Networking.ProductStockStatus

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
            return await resolveProductsUpdate(arguments: arguments)
        case OrdersBulkUpdateTool.name:
            return await resolveOrdersBulk(arguments: arguments)
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

    fileprivate struct ProductsUpdateTarget: Decodable, Sendable {
        let kind: String?
        let id: Int?
        let parentID: Int?

        enum CodingKeys: String, CodingKey {
            case kind
            case id
            case parentID = "parent_id"
        }
    }

    private func resolveProductsUpdate(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable {
            let updates: [Entry]?
            struct Entry: Decodable {
                let target: ProductsUpdateTarget?
            }
        }
        guard let parsed = decode(Args.self, from: arguments),
              let updates = parsed.updates else { return nil }
        let targets = updates.compactMap { $0.target }
        // Parent ids we need product names for: top-level products + variation parents.
        let parentIDs = Self.parentIDsToFetch(targets: targets)
        guard !parentIDs.isEmpty else { return nil }
        let responses = await fetchBulkResponses(ids: parentIDs,
                                                 path: "wc/v3/products",
                                                 type: [ProductSnapshotResponse].self)
        let resolvedByID = Dictionary(uniqueKeysWithValues:
            (responses ?? []).compactMap { response -> (Int, ProductSnapshotResponse)? in
                guard let id = response.id else { return nil }
                return (id, response)
            }
        )
        let entries = Self.buildBulkEntries(targets: targets, parentByID: resolvedByID)
        // Single-target previews still surface prior field values for the diff body.
        if targets.count == 1, let target = targets.first,
           target.kind == "product",
           let id = target.id, let response = resolvedByID[id] {
            let values = Self.productCurrentValues(from: response)
            let displayName = response.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
            return ConfirmationSnapshot(currentValues: values,
                                        displayName: displayName,
                                        bulkEntries: entries)
        }
        return ConfirmationSnapshot(currentValues: [:], bulkEntries: entries)
    }

    private static func parentIDsToFetch(targets: [ProductsUpdateTarget]) -> [Int] {
        var seen: Set<Int> = []
        var ordered: [Int] = []
        for target in targets {
            let candidate: Int?
            if target.kind == "variation" {
                candidate = target.parentID
            } else {
                candidate = target.id
            }
            guard let id = candidate, seen.insert(id).inserted else { continue }
            ordered.append(id)
        }
        return ordered
    }

    private static func buildBulkEntries(targets: [ProductsUpdateTarget],
                                         parentByID: [Int: ProductSnapshotResponse]) -> [ConfirmationBulkEntry] {
        targets.compactMap { target -> ConfirmationBulkEntry? in
            switch target.kind {
            case "variation":
                guard let id = target.id else { return nil }
                let parentName = target.parentID.flatMap { parentByID[$0]?.name }
                return ConfirmationBulkEntry(id: id, displayName: parentName)
            default:
                guard let id = target.id else { return nil }
                return ConfirmationBulkEntry(id: id, displayName: parentByID[id]?.name)
            }
        }
    }

    private static func productCurrentValues(from response: ProductSnapshotResponse) -> [String: ConfirmationPreviewText] {
        var values: [String: ConfirmationPreviewText] = [:]
        if let name = response.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil {
            values["name"] = .raw(name)
        }
        if let price = response.regular_price?.nonEmptyOrNil { values["regular_price"] = .raw(price) }
        if let sale = response.sale_price?.nonEmptyOrNil { values["sale_price"] = .raw(sale) }
        if let quantity = response.stock_quantity {
            values["stock_quantity"] = .raw(Self.formatStockQuantity(quantity))
        }
        if let status = response.status?.nonEmptyOrNil {
            values["status"] = .raw(ProductStatus(rawValue: status).description)
        }
        if let stockStatus = response.stock_status?.nonEmptyOrNil {
            values["stock_status"] = .raw(ProductStockStatus(rawValue: stockStatus).description)
        }
        if let sku = response.sku?.nonEmptyOrNil { values["sku"] = .raw(sku) }
        return values
    }

    static func formatStockQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(Int(value))
        }
        return String(value)
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

    private func fetchBulkEntries<Response: Decodable>(
        ids: [Int],
        path: String,
        type: [Response].Type,
        map: (Response) -> ConfirmationBulkEntry
    ) async -> [ConfirmationBulkEntry] {
        let decoded = await fetchBulkResponses(ids: ids, path: path, type: type)
        guard let decoded else {
            return ids.map { ConfirmationBulkEntry(id: $0) }
        }
        let resolved = decoded.map(map)
        let resolvedByID = Dictionary(uniqueKeysWithValues: resolved.map { ($0.id, $0) })
        // Preserve the requested id order; substitute id-only entries for any the API skipped.
        return ids.map { id in resolvedByID[id] ?? ConfirmationBulkEntry(id: id) }
    }

    private func fetchBulkResponses<Response: Decodable>(
        ids: [Int],
        path: String,
        type: [Response].Type
    ) async -> [Response]? {
        let include = ids.map(String.init).joined(separator: ",")
        let query = ["include": include, "per_page": String(ids.count)]
        let response = await client.request(method: "GET", path: path, query: query, body: nil)
        guard (200..<300).contains(response.statusCode) else {
            DDLogError("DefaultConfirmationSnapshotResolver bulk fetch \(path) returned HTTP \(response.statusCode)")
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: response.data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver bulk decode \(type) failed: \(error)")
            return nil
        }
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

    static func composedCustomerName(first: String?, last: String?) -> String? {
        let parts = [first, last]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// snake_case mirrors the WC REST shape so JSONDecoder needs no CodingKeys map.
fileprivate struct ProductSnapshotResponse: Decodable {
    let id: Int?
    let name: String?
    let regular_price: String?
    let sale_price: String?
    let stock_quantity: Double?
    let status: String?
    let stock_status: String?
    let sku: String?
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}

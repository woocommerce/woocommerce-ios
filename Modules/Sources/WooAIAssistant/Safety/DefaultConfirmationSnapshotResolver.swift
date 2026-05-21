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
        let scope: String?

        enum CodingKeys: String, CodingKey {
            case kind
            case id
            case parentID = "parent_id"
            case scope
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
        // Parent ids we need product names for: top-level + fanout parents + variation parents.
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
        // Skip the missing check when the parents endpoint hit a non-2xx so transport hiccups
        // degrade to the existing fallback rather than refusing a valid request.
        if responses != nil,
           let refusal = Self.missingProductsRefusal(targets: targets, resolvedByID: resolvedByID) {
            return ConfirmationSnapshot(currentValues: [:], refusalReason: refusal)
        }
        let fanoutVariations = await fetchFanoutVariations(targets: targets, parentByID: resolvedByID)
        let specificVariations = await fetchSpecificVariations(targets: targets, parentByID: resolvedByID)
        if let refusal = Self.missingVariationsRefusal(targets: targets,
                                                       parentByID: resolvedByID,
                                                       specificVariations: specificVariations) {
            return ConfirmationSnapshot(currentValues: [:], refusalReason: refusal)
        }
        let entries = Self.buildBulkEntries(targets: targets,
                                            parentByID: resolvedByID,
                                            fanoutVariations: fanoutVariations,
                                            specificVariations: specificVariations.byID)
        let parentVariationCounts = fanoutVariations.mapValues { $0.count }
        // Single-target previews still surface prior field values for the diff body.
        if targets.count == 1, let target = targets.first,
           target.kind == "product", target.scope == nil,
           let id = target.id, let response = resolvedByID[id] {
            let values = Self.productCurrentValues(from: response)
            let displayName = response.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
            return ConfirmationSnapshot(currentValues: values,
                                        displayName: displayName,
                                        bulkEntries: entries,
                                        parentVariationCounts: parentVariationCounts)
        }
        return ConfirmationSnapshot(currentValues: [:],
                                    bulkEntries: entries,
                                    parentVariationCounts: parentVariationCounts)
    }

    /// Refusal text covering top-level products + variation parents that the WC API did not return.
    /// Returns nil when every targeted product (or parent of a variation) is present in `resolvedByID`.
    fileprivate static func missingProductsRefusal(targets: [ProductsUpdateTarget],
                                                   resolvedByID: [Int: ProductSnapshotResponse]) -> String? {
        var missingProducts: [Int] = []
        var missingParents: [(variationID: Int, parentID: Int)] = []
        var seenProducts: Set<Int> = []
        var seenParents: Set<Int> = []
        for target in targets {
            if target.kind == "variation" {
                guard let parentID = target.parentID else { continue }
                if resolvedByID[parentID] == nil, seenParents.insert(parentID).inserted, let id = target.id {
                    missingParents.append((id, parentID))
                }
            } else {
                guard let id = target.id else { continue }
                if resolvedByID[id] == nil, seenProducts.insert(id).inserted {
                    missingProducts.append(id)
                }
            }
        }
        guard !missingProducts.isEmpty || !missingParents.isEmpty else { return nil }
        return refusalText(missingProducts: missingProducts, missingParents: missingParents)
    }

    /// Refusal text when a variation target's parent exists but the variation id isn't in the per-parent
    /// fetch result. Skips parents whose variation endpoint failed so a transport hiccup never refuses.
    fileprivate static func missingVariationsRefusal(targets: [ProductsUpdateTarget],
                                                     parentByID: [Int: ProductSnapshotResponse],
                                                     specificVariations: SpecificVariationFetch) -> String? {
        var missingPairs: [(variationID: Int, parentID: Int)] = []
        var seen: Set<Int> = []
        for target in targets {
            guard target.kind == "variation",
                  let id = target.id,
                  let parentID = target.parentID,
                  parentByID[parentID] != nil,
                  specificVariations.fetchedParents.contains(parentID) else { continue }
            guard specificVariations.byID[id] == nil, seen.insert(id).inserted else { continue }
            missingPairs.append((id, parentID))
        }
        guard !missingPairs.isEmpty else { return nil }
        return variationOnlyRefusalText(missingPairs: missingPairs)
    }

    private static func refusalText(missingProducts: [Int],
                                    missingParents: [(variationID: Int, parentID: Int)]) -> String {
        if missingParents.isEmpty {
            if missingProducts.count == 1 {
                return "I couldn't find product \(missingProducts[0]) in your store. Please verify the ID."
            }
            let joined = missingProducts.map(String.init).joined(separator: ", ")
            return "I couldn't find products \(joined) in your store. Please verify the IDs."
        }
        if missingProducts.isEmpty, missingParents.count == 1 {
            let pair = missingParents[0]
            return "I couldn't find product \(pair.parentID) " +
                   "(parent of variation \(pair.variationID)) in your store. Please verify the ID."
        }
        var parts: [String] = []
        if !missingProducts.isEmpty {
            let label = missingProducts.count == 1 ? "product" : "products"
            parts.append("\(label) \(missingProducts.map(String.init).joined(separator: ", "))")
        }
        if !missingParents.isEmpty {
            let parentIDs = missingParents.map { String($0.parentID) }
            let label = parentIDs.count == 1 ? "parent" : "parents"
            parts.append("\(label) \(parentIDs.joined(separator: ", "))")
        }
        return "I couldn't find \(parts.joined(separator: " or ")) in your store. Please verify the IDs."
    }

    private static func variationOnlyRefusalText(missingPairs: [(variationID: Int, parentID: Int)]) -> String {
        if missingPairs.count == 1 {
            let pair = missingPairs[0]
            return "Product \(pair.parentID) doesn't have a variation with ID \(pair.variationID)."
        }
        let pairsByParent = Dictionary(grouping: missingPairs, by: { $0.parentID })
        let phrases = pairsByParent
            .sorted(by: { $0.key < $1.key })
            .map { parentID, pairs -> String in
                let ids = pairs.map { String($0.variationID) }.joined(separator: ", ")
                return "\(ids) under product \(parentID)"
            }
        return "I couldn't find variations \(phrases.joined(separator: "; ")). Please verify the IDs."
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
                                         parentByID: [Int: ProductSnapshotResponse],
                                         fanoutVariations: [Int: [VariationSnapshotResponse]],
                                         specificVariations: [Int: VariationSnapshotResponse]) -> [ConfirmationBulkEntry] {
        targets.compactMap { target -> ConfirmationBulkEntry? in
            switch (target.kind, target.scope) {
            case ("variation", _):
                guard let id = target.id else { return nil }
                let parentName = target.parentID.flatMap { parentByID[$0]?.name }
                let label = specificVariations[id].flatMap { variationLabel(for: $0, parentName: parentName) }
                return ConfirmationBulkEntry(id: id, displayName: label)
            case ("product", "all_variations"?):
                guard let id = target.id else { return nil }
                let parentName = parentByID[id]?.name
                let rows = fanoutVariations[id] ?? []
                let subs = rows.compactMap { row -> ConfirmationBulkEntry? in
                    guard let rowID = row.id else { return nil }
                    return ConfirmationBulkEntry(id: rowID,
                                                 displayName: variationLabel(for: row, parentName: parentName))
                }
                return ConfirmationBulkEntry(id: id, displayName: parentName, subEntries: subs)
            default:
                guard let id = target.id else { return nil }
                return ConfirmationBulkEntry(id: id, displayName: parentByID[id]?.name)
            }
        }
    }

    private func fetchFanoutVariations(targets: [ProductsUpdateTarget],
                                       parentByID: [Int: ProductSnapshotResponse])
    async -> [Int: [VariationSnapshotResponse]] {
        let fanoutIDs = targets.compactMap { target -> Int? in
            guard target.scope == "all_variations", target.kind == "product", let id = target.id else { return nil }
            return id
        }
        guard !fanoutIDs.isEmpty else { return [:] }
        var result: [Int: [VariationSnapshotResponse]] = [:]
        // Sequential keeps request volume bounded; fanout consent is rare per turn.
        // Omit failed parents so callers degrade to the unknown-count summary.
        for parentID in fanoutIDs {
            guard let rows = await fetchVariations(parentID: parentID, include: nil) else { continue }
            result[parentID] = rows
        }
        return result
    }

    private func fetchSpecificVariations(targets: [ProductsUpdateTarget],
                                         parentByID: [Int: ProductSnapshotResponse])
    async -> SpecificVariationFetch {
        var byParent: [Int: [Int]] = [:]
        for target in targets {
            guard target.kind == "variation", let id = target.id, let parentID = target.parentID else { continue }
            byParent[parentID, default: []].append(id)
        }
        guard !byParent.isEmpty else { return SpecificVariationFetch(byID: [:], fetchedParents: []) }
        var byID: [Int: VariationSnapshotResponse] = [:]
        var fetchedParents: Set<Int> = []
        for (parentID, variationIDs) in byParent {
            guard let rows = await fetchVariations(parentID: parentID, include: variationIDs) else { continue }
            fetchedParents.insert(parentID)
            for row in rows {
                guard let rowID = row.id else { continue }
                byID[rowID] = row
            }
        }
        return SpecificVariationFetch(byID: byID, fetchedParents: fetchedParents)
    }

    fileprivate struct SpecificVariationFetch {
        let byID: [Int: VariationSnapshotResponse]
        /// Parents whose variation fetch returned a 2xx. Missing-variation refusal only fires under
        /// these so a transport hiccup never refuses a valid call.
        let fetchedParents: Set<Int>
    }

    private func fetchVariations(parentID: Int, include: [Int]?) async -> [VariationSnapshotResponse]? {
        var query: [String: String] = [
            "per_page": String(100),
            "_fields": "id,name,attributes"
        ]
        if let include, !include.isEmpty {
            query["include"] = include.map(String.init).joined(separator: ",")
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(parentID)/variations",
                                            query: query,
                                            body: nil)
        guard (200..<300).contains(response.statusCode) else {
            DDLogError("DefaultConfirmationSnapshotResolver variations for \(parentID) returned HTTP \(response.statusCode)")
            return nil
        }
        do {
            return try JSONDecoder().decode([VariationSnapshotResponse].self, from: response.data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver variations decode failed for \(parentID): \(error)")
            return nil
        }
    }

    fileprivate static func variationLabel(for row: VariationSnapshotResponse, parentName: String?) -> String? {
        let trimmedParent = parentName?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
        let optionParts = (row.attributes ?? []).compactMap { attribute -> String? in
            attribute.option?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil
        }
        // Always carry the parent name so the merchant can tell a variation row from a simple product.
        // Prefer attributes over the stored `name`; WC fills `name` inconsistently (bare attrs on some
        // stores, already parent-prefixed on others), and double-prefixing reads worse than either.
        if !optionParts.isEmpty {
            let suffix = optionParts.joined(separator: ", ")
            return trimmedParent.map { "\($0) - \(suffix)" } ?? suffix
        }
        guard let name = row.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmptyOrNil else {
            return trimmedParent
        }
        guard let trimmedParent, !name.hasPrefix(trimmedParent) else { return name }
        return "\(trimmedParent) - \(name)"
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

fileprivate struct VariationSnapshotResponse: Decodable {
    let id: Int?
    let name: String?
    let attributes: [VariationAttributeSnapshot]?
}

fileprivate struct VariationAttributeSnapshot: Decodable {
    let id: Int?
    let name: String?
    let option: String?
}

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}

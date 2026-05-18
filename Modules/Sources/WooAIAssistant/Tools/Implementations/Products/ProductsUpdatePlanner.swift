import Foundation

struct ProductsUpdatePlanner {

    let client: WCRESTClient

    func plan(entries: [ProductsUpdateTool.Entry],
              captured: [Int: AnyCodableJSON]) async -> [EntryPlan] {
        let client = client
        return await BoundedTaskGroup.runOrdered(entries, limit: ProductsUpdateTool.concurrencyCap) { entry in
            await Self.planEntry(entry: entry, captured: captured[entry.id], client: client)
        }
    }

    private static func planEntry(entry: ProductsUpdateTool.Entry,
                                  captured: AnyCodableJSON?,
                                  client: WCRESTClient) async -> EntryPlan {
        let entity: AnyCodableJSON
        if let captured {
            entity = captured
        } else {
            let probe = await client.request(method: "GET",
                                             path: "wc/v3/products/\(entry.id)",
                                             query: nil,
                                             body: nil)
            guard HTTPStatusClassification.isSuccess(probe.statusCode) else {
                return EntryPlan(entryID: entry.id,
                                 preDispatchFailures: [(entry.id, discoveryReason(probe.statusCode))])
            }
            guard let decoded = RESTResponseParsing.decodeJSON(probe.data) else {
                return EntryPlan(entryID: entry.id,
                                 preDispatchFailures: [(entry.id, "Product not found")])
            }
            entity = decoded
        }
        let type = RESTResponseParsing.stringField(entity, "type") ?? ""
        switch type {
        case "variable":
            return await planVariableParent(entry: entry, client: client)
        case "variation":
            let parentID = Int(RESTResponseParsing.intField(entity, "parent_id") ?? 0)
            return planVariation(entry: entry, parentID: parentID, captured: entity)
        default:
            return planProduct(entry: entry, captured: entity)
        }
    }

    private static func discoveryReason(_ statusCode: Int) -> String {
        statusCode == 404 ? "Product not found" : "Discovery request failed (HTTP \(statusCode))"
    }

    private static func planProduct(entry: ProductsUpdateTool.Entry,
                                    captured: AnyCodableJSON) -> EntryPlan {
        var patch: [String: AnyCodableJSON] = [:]
        applyExplicitPriceFields(entry: entry, into: &patch)
        if let failure = applyPercentDiscount(entry: entry, source: captured, into: &patch) {
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, failure)])
        }
        applyCommonFields(entry: entry, into: &patch)
        if let value = entry.name { patch["name"] = .string(value) }
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        if let value = entry.sku { patch["sku"] = .string(value) }

        guard !patch.isEmpty else {
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
        }
        let write = PlannedWrite(entryID: entry.id,
                                 targetID: entry.id,
                                 expandedParent: nil,
                                 patch: patch)
        return EntryPlan(entryID: entry.id, writes: [write])
    }

    private static func planVariation(entry: ProductsUpdateTool.Entry,
                                      parentID: Int,
                                      captured: AnyCodableJSON) -> EntryPlan {
        guard parentID > 0 else {
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, "variation has no parent_id")])
        }
        if entry.name != nil {
            let reason = "Variations do not have settable names; their display name is derived from "
                + "parent and attributes."
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, reason)])
        }
        var patch: [String: AnyCodableJSON] = [:]
        applyExplicitPriceFields(entry: entry, into: &patch)
        if let failure = applyPercentDiscount(entry: entry, source: captured, into: &patch) {
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, failure)])
        }
        applyCommonFields(entry: entry, into: &patch)
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        if let value = entry.sku { patch["sku"] = .string(value) }

        guard !patch.isEmpty else {
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
        }
        let write = PlannedWrite(entryID: entry.id,
                                 targetID: entry.id,
                                 expandedParent: parentID,
                                 patch: patch)
        return EntryPlan(entryID: entry.id, writes: [write])
    }

    private static func planVariableParent(entry: ProductsUpdateTool.Entry,
                                           client: WCRESTClient) async -> EntryPlan {
        if entry.stockQuantity != nil {
            let reason = "Cannot set stock_quantity on a variable parent; drill into specific variations and update each."
            return EntryPlan(entryID: entry.id,
                             preDispatchFailures: [(entry.id, reason)])
        }
        // Parent-only fields and variation-fanout fields can coexist on one entry, so both run.
        var parentPatch: [String: AnyCodableJSON] = [:]
        if let value = entry.status { parentPatch["status"] = .string(value) }
        if let value = entry.name { parentPatch["name"] = .string(value) }
        if let value = entry.sku { parentPatch["sku"] = .string(value) }

        let hasExpansionFields = entry.regularPrice != nil || entry.salePrice != nil
            || entry.percentDiscount != nil || entry.stockStatus != nil
        guard hasExpansionFields else {
            guard !parentPatch.isEmpty else {
                return EntryPlan(entryID: entry.id,
                                 preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
            }
            let write = PlannedWrite(entryID: entry.id,
                                     targetID: entry.id,
                                     expandedParent: nil,
                                     patch: parentPatch)
            return EntryPlan(entryID: entry.id, writes: [write])
        }

        let expansion = await planVariableParentExpansion(entry: entry, parentID: entry.id, client: client)
        guard !parentPatch.isEmpty else { return expansion }
        // If the per-variation expansion refused entirely, applying parent-only fields would be a
        // surprise partial write that contradicts the tool description's "refused entirely" promise.
        let expansionRefused = expansion.writes.isEmpty && !expansion.preDispatchFailures.isEmpty
        if expansionRefused {
            let combinedReason = "Cannot apply parent-only fields (e.g. name/status/sku) and per-variation "
                + "fields (e.g. price/stock_status) in the same update for product #\(entry.id) because the "
                + "per-variation expansion was refused. Issue two separate updates: one for the parent-only "
                + "fields, and one targeting specific variation ids for the per-variation fields."
            return EntryPlan(entryID: entry.id,
                             expandedParent: expansion.expandedParent,
                             preDispatchFailures: [(entry.id, combinedReason)])
        }
        let parentWrite = PlannedWrite(entryID: entry.id,
                                       targetID: entry.id,
                                       expandedParent: nil,
                                       patch: parentPatch)
        return EntryPlan(entryID: entry.id,
                         expandedParent: expansion.expandedParent,
                         preDispatchFailures: expansion.preDispatchFailures,
                         writes: [parentWrite] + expansion.writes)
    }

    private static func planVariableParentExpansion(entry: ProductsUpdateTool.Entry,
                                                    parentID: Int,
                                                    client: WCRESTClient) async -> EntryPlan {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(parentID)/variations",
                                            query: ["per_page": String(ProductsUpdateTool.variationsPerPage)],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode),
              let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return EntryPlan(entryID: entry.id,
                             expandedParent: parentID,
                             preDispatchFailures: [(entry.id, "Could not enumerate variations for parent \(parentID)")])
        }
        // Refuse partial application: writing only the first page would leave variations inconsistent.
        if totalPagesValue(headers: response.headers) > 1 {
            let reason = "Cannot update variable product #\(entry.id): it has more than "
                + "\(ProductsUpdateTool.variationsPerPage) variations and updating only the first "
                + "\(ProductsUpdateTool.variationsPerPage) would leave the rest in an inconsistent state. "
                + "Issue updates for specific variation ids instead."
            return EntryPlan(entryID: entry.id,
                             expandedParent: parentID,
                             preDispatchFailures: [(entry.id, reason)])
        }
        var writes: [PlannedWrite] = []
        var failures: [(Int, String)] = []
        for row in rows {
            switch plannedVariationWrite(entry: entry, row: row, parentID: parentID) {
            case .success(let write): writes.append(write)
            case .failure(let failure): failures.append(failure)
            case .none: continue
            }
        }
        return EntryPlan(entryID: entry.id,
                         expandedParent: parentID,
                         preDispatchFailures: failures,
                         writes: writes)
    }

    /// `.none` means the row had no `id` to target; the loop skips it silently as before.
    private enum VariationOutcome {
        case success(PlannedWrite)
        case failure((Int, String))
        case none
    }

    private static func plannedVariationWrite(entry: ProductsUpdateTool.Entry,
                                              row: AnyCodableJSON,
                                              parentID: Int) -> VariationOutcome {
        guard let identifier = RESTResponseParsing.intField(row, "id") else { return .none }
        let variationID = Int(identifier)
        var patch: [String: AnyCodableJSON] = [:]
        if let value = entry.regularPrice { patch["regular_price"] = .string(value) }
        if let value = entry.salePrice { patch["sale_price"] = .string(value) }
        if let percent = entry.percentDiscount {
            guard let regular = RESTResponseParsing.decimalField(row, "regular_price"),
                  let salePrice = computeSalePrice(regular: regular, percent: percent) else {
                return .failure((variationID, "Cannot compute percent discount: regular_price is empty"))
            }
            patch["sale_price"] = .string(salePrice)
        }
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        guard !patch.isEmpty else {
            return .failure((variationID, "no editable field resolved"))
        }
        return .success(PlannedWrite(entryID: entry.id,
                                     targetID: variationID,
                                     expandedParent: parentID,
                                     patch: patch))
    }

    private static func totalPagesValue(headers: [String: String]) -> Int {
        for (key, value) in headers where key.caseInsensitiveCompare("X-WP-TotalPages") == .orderedSame {
            return Int(value) ?? 0
        }
        return 0
    }

    private static func applyExplicitPriceFields(entry: ProductsUpdateTool.Entry,
                                                 into patch: inout [String: AnyCodableJSON]) {
        if let value = entry.regularPrice { patch["regular_price"] = .string(value) }
        if let value = entry.salePrice { patch["sale_price"] = .string(value) }
    }

    private static func applyCommonFields(entry: ProductsUpdateTool.Entry,
                                          into patch: inout [String: AnyCodableJSON]) {
        if let value = entry.stockQuantity {
            patch["stock_quantity"] = .int(Int64(value))
            patch["manage_stock"] = .bool(true)
        }
        if let value = entry.status { patch["status"] = .string(value) }
    }

    private static func applyPercentDiscount(entry: ProductsUpdateTool.Entry,
                                             source: AnyCodableJSON,
                                             into patch: inout [String: AnyCodableJSON]) -> String? {
        guard let percent = entry.percentDiscount else { return nil }
        guard let regular = RESTResponseParsing.decimalField(source, "regular_price"),
              let salePrice = computeSalePrice(regular: regular, percent: percent) else {
            return "Cannot compute percent discount: regular_price is empty"
        }
        patch["sale_price"] = .string(salePrice)
        return nil
    }

    static func computeSalePrice(regular: Decimal, percent: Double) -> String? {
        guard regular > 0 else { return nil }
        let factorString = String(format: "%.6f", (100.0 - percent) / 100.0)
        guard let factor = Decimal(string: factorString) else { return nil }
        let computed = regular * factor
        return RESTResponseParsing.formatDecimal(computed)
    }
}

import Foundation

struct ProductsUpdatePlanner {

    let client: WCRESTClient

    func plan(entries: [ProductsUpdateTool.Entry],
              discovery: DiscoveryResult) async -> [EntryPlan] {
        await BoundedTaskGroup.runOrdered(entries, limit: ProductsUpdateTool.concurrencyCap) { entry in
            await self.planEntry(entry: entry, discovery: discovery)
        }
    }

    private func planEntry(entry: ProductsUpdateTool.Entry,
                           discovery: DiscoveryResult) async -> EntryPlan {
        switch entry.target.kind {
        case .variation:
            // Skip discovery for explicit variation targets; routing is unambiguous from the target.
            guard let parentID = entry.target.parentID else {
                return EntryPlan(preDispatchFailures: [(entry.id, "variation target missing parent_id")])
            }
            return planVariation(entry: entry,
                                 parentID: parentID,
                                 variationID: entry.target.id)
        case .product:
            return await planProductTarget(entry: entry, discovery: discovery)
        }
    }

    private func planProductTarget(entry: ProductsUpdateTool.Entry,
                                   discovery: DiscoveryResult) async -> EntryPlan {
        let entity: AnyCodableJSON
        if let captured = discovery.captured[entry.target.id] {
            entity = captured
        } else if let status = discovery.unreachable[entry.target.id] {
            // The chunk that should have carried this id failed; refuse rather than per-id probe.
            let reason = "Couldn't look up product #\(entry.id) (store returned HTTP \(status) "
                + "during lookup). Try again in a moment."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        } else {
            let probe = await client.request(method: "GET",
                                             path: "wc/v3/products/\(entry.id)",
                                             query: nil,
                                             body: nil)
            guard HTTPStatusClassification.isSuccess(probe.statusCode) else {
                return EntryPlan(preDispatchFailures: [(entry.id, discoveryReason(probe.statusCode))])
            }
            guard let decoded = RESTResponseParsing.decodeJSON(probe.data) else {
                return EntryPlan(preDispatchFailures: [(entry.id, "Product not found")])
            }
            entity = decoded
        }
        let type = RESTResponseParsing.stringField(entity, "type") ?? ""
        switch type {
        case "variable":
            return planVariableParent(entry: entry)
        case "variation":
            let reason = "Product #\(entry.id) is a variation. Use target.kind=\"variation\" with "
                + "parent_id and the variation id, not target.kind=\"product\"."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        default:
            return planProduct(entry: entry)
        }
    }

    private func discoveryReason(_ statusCode: Int) -> String {
        statusCode == 404 ? "Product not found" : "Discovery request failed (HTTP \(statusCode))"
    }

    private func planProduct(entry: ProductsUpdateTool.Entry) -> EntryPlan {
        var patch: [String: AnyCodableJSON] = [:]
        applyExplicitPriceFields(entry: entry, into: &patch)
        applyCommonFields(entry: entry, into: &patch)
        if let value = entry.name { patch["name"] = .string(value) }
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        if let value = entry.sku { patch["sku"] = .string(value) }

        guard !patch.isEmpty else {
            return EntryPlan(preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
        }
        let write = PlannedWrite(targetID: entry.id,
                                 expandedParent: nil,
                                 patch: patch)
        return EntryPlan(writes: [write])
    }

    /// Variable parents accept name/status/sku on the parent row itself; price and stock must
    /// target individual variations (fanout is deferred). An entry can produce a parent write
    /// for the parent-level fields AND a refusal note for the price/stock fields at once.
    private func planVariableParent(entry: ProductsUpdateTool.Entry) -> EntryPlan {
        var patch: [String: AnyCodableJSON] = [:]
        if let value = entry.name { patch["name"] = .string(value) }
        if let value = entry.status { patch["status"] = .string(value) }
        if let value = entry.sku { patch["sku"] = .string(value) }

        var failures: [(Int, String)] = []
        if entry.regularPrice != nil || entry.salePrice != nil
            || entry.stockStatus != nil || entry.stockQuantity != nil {
            let reason = "Product #\(entry.id) is a variable product. Price and stock changes must "
                + "target individual variations (target.kind=\"variation\" with parent_id). Its name, "
                + "status, and sku can be set on the parent."
            failures.append((entry.id, reason))
        }

        guard !patch.isEmpty else {
            if failures.isEmpty {
                return EntryPlan(preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
            }
            return EntryPlan(preDispatchFailures: failures)
        }
        let write = PlannedWrite(targetID: entry.id, expandedParent: nil, patch: patch)
        return EntryPlan(preDispatchFailures: failures, writes: [write])
    }

    private func planVariation(entry: ProductsUpdateTool.Entry,
                               parentID: Int,
                               variationID: Int) -> EntryPlan {
        guard parentID > 0 else {
            return EntryPlan(preDispatchFailures: [(entry.id, "variation has no parent_id")])
        }
        if entry.name != nil {
            let reason = "Variations do not have settable names; their display name is derived from "
                + "parent and attributes."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        }
        var patch: [String: AnyCodableJSON] = [:]
        applyExplicitPriceFields(entry: entry, into: &patch)
        applyCommonFields(entry: entry, into: &patch)
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        if let value = entry.sku { patch["sku"] = .string(value) }

        guard !patch.isEmpty else {
            return EntryPlan(preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
        }
        let write = PlannedWrite(targetID: variationID,
                                 expandedParent: parentID,
                                 patch: patch)
        return EntryPlan(writes: [write])
    }

    private func applyExplicitPriceFields(entry: ProductsUpdateTool.Entry,
                                          into patch: inout [String: AnyCodableJSON]) {
        if let value = entry.regularPrice { patch["regular_price"] = .string(value) }
        if let value = entry.salePrice { patch["sale_price"] = .string(value) }
    }

    private func applyCommonFields(entry: ProductsUpdateTool.Entry,
                                   into patch: inout [String: AnyCodableJSON]) {
        if let value = entry.stockQuantity {
            patch["stock_quantity"] = .int(Int64(value))
            patch["manage_stock"] = .bool(true)
        }
        if let value = entry.status { patch["status"] = .string(value) }
    }
}

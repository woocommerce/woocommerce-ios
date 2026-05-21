import Foundation

struct ProductsUpdatePlanner {

    let client: WCRESTClient

    func plan(entries: [ProductsUpdateTool.Entry],
              captured: [Int: AnyCodableJSON]) async -> [EntryPlan] {
        await BoundedTaskGroup.runOrdered(entries, limit: ProductsUpdateTool.concurrencyCap) { entry in
            await self.planEntry(entry: entry, captured: captured[entry.target.id])
        }
    }

    private func planEntry(entry: ProductsUpdateTool.Entry,
                           captured: AnyCodableJSON?) async -> EntryPlan {
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
            return await planProductTarget(entry: entry, captured: captured)
        }
    }

    private func planProductTarget(entry: ProductsUpdateTool.Entry,
                                   captured: AnyCodableJSON?) async -> EntryPlan {
        let entity: AnyCodableJSON
        if let captured {
            entity = captured
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
            let reason = "Product #\(entry.id) is a variable product. Target its variations directly "
                + "with target.kind=\"variation\" and the variation id plus parent_id."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
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

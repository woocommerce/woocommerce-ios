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
            return await planVariation(entry: entry,
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
            return await planVariableParent(entry: entry)
        case "variation":
            let reason = "Product #\(entry.id) is a variation. Use target.kind=\"variation\" with "
                + "parent_id and the variation id, not target.kind=\"product\"."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        default:
            return planProduct(entry: entry, source: entity)
        }
    }

    private func discoveryReason(_ statusCode: Int) -> String {
        statusCode == 404 ? "Product not found" : "Discovery request failed (HTTP \(statusCode))"
    }

    private func planProduct(entry: ProductsUpdateTool.Entry, source: AnyCodableJSON) -> EntryPlan {
        var patch: [String: AnyCodableJSON] = [:]
        applyExplicitPriceFields(entry: entry, into: &patch)
        if let failure = applyPercentDiscount(entry: entry, source: source, into: &patch) {
            return EntryPlan(preDispatchFailures: [(entry.id, failure)])
        }
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

    /// Variable parents accept name/status/sku on the parent row itself; price and stock live on
    /// the variations. Without `scope=all_variations` those variation-level fields are refused so the
    /// model never silently writes across an entire variation set. With explicit scope they fan out
    /// to every variation, and parent-only fields still land on the parent in the same entry.
    private func planVariableParent(entry: ProductsUpdateTool.Entry) async -> EntryPlan {
        if entry.stockQuantity != nil {
            let reason = "Cannot set stock_quantity on a variable parent; target specific variations with "
                + "target.kind=\"variation\" and update each."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        }
        var parentPatch: [String: AnyCodableJSON] = [:]
        if let value = entry.status { parentPatch["status"] = .string(value) }
        if let value = entry.name { parentPatch["name"] = .string(value) }
        if let value = entry.sku { parentPatch["sku"] = .string(value) }

        let hasExpansionFields = entry.regularPrice != nil || entry.salePrice != nil
            || entry.percentDiscount != nil || entry.stockStatus != nil
        let scopedFanout = entry.target.scope == .allVariations

        if hasExpansionFields && !scopedFanout {
            let reason = "Cannot apply variation-level fields (regular_price, sale_price, "
                + "percent_discount, stock_status) to variable parent #\(entry.id) without explicit "
                + "fanout consent. To target a specific variation, use "
                + "target.kind=\"variation\" with parent_id. To apply the change to ALL variations, "
                + "set target.scope=\"all_variations\"."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
        }
        guard hasExpansionFields else {
            guard !parentPatch.isEmpty else {
                return EntryPlan(preDispatchFailures: [(entry.id, "no editable field resolved for this entry")])
            }
            let write = PlannedWrite(targetID: entry.id, expandedParent: nil, patch: parentPatch)
            return EntryPlan(writes: [write])
        }

        let expansion = await planVariableParentExpansion(entry: entry, parentID: entry.id)
        guard !parentPatch.isEmpty else { return expansion }
        // If the per-variation expansion refused entirely, applying parent-only fields would be a
        // surprise partial write that contradicts the tool description's "refused entirely" promise.
        let expansionRefused = expansion.writes.isEmpty && !expansion.preDispatchFailures.isEmpty
        if expansionRefused {
            let combinedReason = "Cannot apply parent-only fields (e.g. name/status/sku) and per-variation "
                + "fields (e.g. price/stock_status) in the same update for product #\(entry.id) because the "
                + "per-variation expansion was refused. Issue two separate updates: one for the parent-only "
                + "fields, and one with target.kind=\"variation\" entries for the per-variation fields."
            return EntryPlan(preDispatchFailures: [(entry.id, combinedReason)])
        }
        let parentWrite = PlannedWrite(targetID: entry.id, expandedParent: nil, patch: parentPatch)
        return EntryPlan(preDispatchFailures: expansion.preDispatchFailures,
                         writes: [parentWrite] + expansion.writes)
    }

    private func planVariableParentExpansion(entry: ProductsUpdateTool.Entry,
                                             parentID: Int) async -> EntryPlan {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(parentID)/variations",
                                            query: ["per_page": String(ProductsUpdateTool.variationsPerPage)],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode),
              let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return EntryPlan(preDispatchFailures: [(entry.id, "Could not enumerate variations for parent \(parentID)")])
        }
        // Refuse partial application: writing only the first page would leave variations inconsistent.
        // A parent with exactly variationsPerPage rows and no X-WP-TotalPages header is refused on
        // purpose: a full page is indistinguishable from the first page of many, so we cannot prove a
        // second page does not exist (covers older adapters or mocks that drop the header). This
        // conservative refusal is intentional, not a bug.
        let pageCapMet = rows.count >= ProductsUpdateTool.variationsPerPage
        if Self.totalPagesValue(headers: response.headers) > 1 || pageCapMet {
            let reason = "Cannot update variable product #\(entry.id): it has more than "
                + "\(ProductsUpdateTool.variationsPerPage) variations and updating only the first "
                + "\(ProductsUpdateTool.variationsPerPage) would leave the rest in an inconsistent state. "
                + "Issue updates with target.kind=\"variation\" for specific variation ids instead."
            return EntryPlan(preDispatchFailures: [(entry.id, reason)])
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
        return EntryPlan(preDispatchFailures: failures, writes: writes)
    }

    /// `.none` means the row had no `id` to target; the loop skips it silently.
    private enum VariationOutcome {
        case success(PlannedWrite)
        case failure((Int, String))
        case none
    }

    private func plannedVariationWrite(entry: ProductsUpdateTool.Entry,
                                       row: AnyCodableJSON,
                                       parentID: Int) -> VariationOutcome {
        guard let identifier = RESTResponseParsing.intField(row, "id") else { return .none }
        let variationID = Int(identifier)
        var patch: [String: AnyCodableJSON] = [:]
        if let value = entry.regularPrice { patch["regular_price"] = .string(value) }
        if let value = entry.salePrice { patch["sale_price"] = .string(value) }
        if let percent = entry.percentDiscount {
            guard let regular = RESTResponseParsing.decimalField(row, "regular_price"),
                  let salePrice = Self.computeSalePrice(regular: regular, percent: percent) else {
                return .failure((variationID, "Cannot compute percent discount: regular_price is empty"))
            }
            patch["sale_price"] = .string(salePrice)
        }
        if let value = entry.stockStatus { patch["stock_status"] = .string(value) }
        guard !patch.isEmpty else {
            return .failure((variationID, "no editable field resolved"))
        }
        return .success(PlannedWrite(targetID: variationID,
                                     expandedParent: parentID,
                                     patch: patch))
    }

    private static func totalPagesValue(headers: [String: String]) -> Int {
        for (key, value) in headers where key.caseInsensitiveCompare("X-WP-TotalPages") == .orderedSame {
            return Int(value) ?? 0
        }
        return 0
    }

    private func planVariation(entry: ProductsUpdateTool.Entry,
                               parentID: Int,
                               variationID: Int) async -> EntryPlan {
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
        if entry.percentDiscount != nil {
            // Only fetch the variation when we need its regular_price for percent math.
            let probe = await client.request(method: "GET",
                                             path: "wc/v3/products/\(parentID)/variations/\(variationID)",
                                             query: nil,
                                             body: nil)
            guard HTTPStatusClassification.isSuccess(probe.statusCode),
                  let decoded = RESTResponseParsing.decodeJSON(probe.data) else {
                return EntryPlan(preDispatchFailures: [(entry.id, discoveryReason(probe.statusCode))])
            }
            if let failure = applyPercentDiscount(entry: entry, source: decoded, into: &patch) {
                return EntryPlan(preDispatchFailures: [(entry.id, failure)])
            }
        }
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

    private func applyPercentDiscount(entry: ProductsUpdateTool.Entry,
                                      source: AnyCodableJSON,
                                      into patch: inout [String: AnyCodableJSON]) -> String? {
        guard let percent = entry.percentDiscount else { return nil }
        guard let regular = RESTResponseParsing.decimalField(source, "regular_price"),
              let salePrice = Self.computeSalePrice(regular: regular, percent: percent) else {
            return "Cannot compute percent discount: regular_price is empty"
        }
        patch["sale_price"] = .string(salePrice)
        return nil
    }

    private static func computeSalePrice(regular: Decimal, percent: Double) -> String? {
        guard regular > 0 else { return nil }
        let factorString = String(format: "%.6f", (100.0 - percent) / 100.0)
        guard let factor = Decimal(string: factorString) else { return nil }
        let computed = regular * factor
        return RESTResponseParsing.formatDecimal(computed)
    }
}

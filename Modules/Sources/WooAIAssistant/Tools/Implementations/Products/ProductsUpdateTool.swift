import Foundation
import CocoaLumberjackSwift

public enum ProductsUpdateTool {

    public static let name = "products_update"

    public static let maxBatchSize = 100

    static let concurrencyCap = 5
    static let variationsPerPage = 100
    /// Mirrors the WC REST `per_page` ceiling so a single `?include=` chunk covers up to 100 ids.
    static let discoveryChunkSize = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Update one or more EXISTING product entities (simple products, variable products, or \
        variations) in a single call. Each update needs a `target` object identifying what to \
        write, plus at least one field to change. The target shape mirrors what \
        orders_list/products_list/show_cards emit on each row, so copy that object verbatim. \
        This tool does NOT create new products or delete products; for those, point the merchant \
        at the Products tab in the app. \
        Target shapes: `{kind: "product", id: N}` for a top-level product (simple or variable \
        parent); `{kind: "variation", id: V, parent_id: P}` for one specific variation; \
        `{kind: "product", id: N, scope: "all_variations"}` to fan price/stock changes out to \
        every variation of variable parent N. Without `scope`, variable-parent entries only \
        apply parent-level fields (name, status, sku); price and stock changes are rejected with \
        a pointer to target specific variations or to set scope=all_variations. Examples: \
        `{target: {kind: "product", id: 42}, percent_discount: 10}` discounts simple product \
        42; `{target: {kind: "variation", id: 58, parent_id: 41}, percent_discount: 10}` \
        discounts ONE variation - use this with the target object on order line_items; \
        `{target: {kind: "product", id: 821, scope: "all_variations"}, percent_discount: 10}` \
        discounts ALL variations under variable parent 821. \
        Editable fields: `regular_price`, `sale_price`, `percent_discount`, `stock_quantity`, \
        `status`, `name`, `stock_status`, `sku`. For percentage-off discounts use \
        `percent_discount` per entry and the server computes per-item `sale_price` from the \
        entity's current regular price. Otherwise set `sale_price` explicitly. `stock_quantity` \
        on a variable parent is rejected even with scope; target specific variations. Variations \
        do not have settable names. Variable parents with more than 100 variations are refused \
        entirely when `scope: "all_variations"` is set; target specific variation ids instead. \
        The result has an `updated` array of target objects ({kind:"product", id} or \
        {kind:"variation", id, parent_id}); pass each one to `show_cards` (a variation maps to \
        the combined parent/variation ref) or back into `products_update.updates[].target`.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "updates": .object([
                    "type": .string("array"),
                    "description": .string("Per-target updates. Each entry must include `target` and at least one field."),
                    "items": .object([
                        "type": .string("object"),
                        "additionalProperties": .bool(false),
                        "properties": .object([
                            "target": .object([
                                "type": .string("object"),
                                "additionalProperties": .bool(false),
                                "description": .string("Routing object identifying the entity to update. Copy "
                                    + "from orders_list/products_list row.target or show_cards line_item.target."),
                                "properties": .object([
                                    "kind": .object([
                                        "type": .string("string"),
                                        "enum": .array([.string("product"), .string("variation")]),
                                        "description": .string("\"product\" for top-level products; "
                                            + "\"variation\" for a specific variation.")
                                    ]),
                                    "id": .object([
                                        "type": .string("integer"),
                                        "description": .string("The product or variation ID.")
                                    ]),
                                    "parent_id": .object([
                                        "type": .string("integer"),
                                        "description": .string("Required when kind=variation; "
                                            + "must equal the variation's parent product id.")
                                    ]),
                                    "scope": .object([
                                        "type": .string("string"),
                                        "enum": .array([.string("all_variations")]),
                                        "description": .string("Only valid on kind=product variable parents. "
                                            + "Set to \"all_variations\" to fan changes out to every variation.")
                                    ])
                                ]),
                                "required": .array([.string("kind"), .string("id")])
                            ]),
                            "regular_price": .object([
                                "type": .string("string"),
                                "description": .string("Decimal string, e.g. \"19.99\".")
                            ]),
                            "sale_price": .object([
                                "type": .string("string"),
                                "description": .string("Decimal string. Empty string clears the sale price.")
                            ]),
                            "percent_discount": .object([
                                "type": .string("number"),
                                "description": .string("Percent off, greater than 0 and less than 100. "
                                    + "Computed against the entity's current regular_price.")
                            ]),
                            "stock_quantity": .object([
                                "type": .string("integer"),
                                "description": .string("Sets manage_stock=true automatically. Rejected for variable parents.")
                            ]),
                            "status": .object([
                                "type": .string("string"),
                                "enum": .array(allowedStatuses.sorted().map { .string($0) }),
                                "description": .string("Publication status. Applies directly to simple "
                                    + "products and variations; on a variable parent it updates only "
                                    + "the parent.")
                            ]),
                            "name": .object([
                                "type": .string("string"),
                                "description": .string("New display name. Only valid for top-level products "
                                    + "(simple or variable parent). Variations do not have settable names; "
                                    + "their display name is derived from parent + attributes.")
                            ]),
                            "stock_status": .object([
                                "type": .string("string"),
                                "enum": .array(allowedStockStatuses.sorted().map { .string($0) }),
                                "description": .string("Inventory state label. Applies to simple products and "
                                    + "variations directly.")
                            ]),
                            "sku": .object([
                                "type": .string("string"),
                                "description": .string("Product or variation SKU. Must be unique store-wide. "
                                    + "On a variable parent, applies to the parent's own SKU slot (not "
                                    + "expanded to variations to avoid uniqueness collisions).")
                            ])
                        ]),
                        "required": .array([.string("target")])
                    ])
                ])
            ]),
            "required": .array([.string("updates")])
        ]),
        safetyLevel: .unsafe
    )

    private struct UpdatesEnvelope: Decodable, Sendable {
        let updates: [ProductsUpdateEntry]
    }

    typealias Entry = ValidatedEntry

    /// Post-validation wrapper exposed to helpers; mirrors `ProductsUpdateEntry` but with
    /// a fully resolved typed `target` so downstream code does not re-validate on every read.
    struct ValidatedEntry: Sendable {
        let target: Target
        let regularPrice: String?
        let salePrice: String?
        let percentDiscount: Double?
        let stockQuantity: Int?
        let status: String?
        let name: String?
        let stockStatus: String?
        let sku: String?

        var id: Int { target.id }

        struct Target: Sendable {
            let kind: Kind
            let id: Int
            let parentID: Int?
            let scope: Scope?
        }

        enum Kind: String, Sendable {
            case product
            case variation
        }

        enum Scope: String, Sendable {
            case allVariations = "all_variations"
        }

        init(_ raw: ProductsUpdateEntry, target: Target) {
            self.target = target
            self.regularPrice = raw.regularPrice
            self.salePrice = raw.salePrice
            self.percentDiscount = raw.percentDiscount
            self.stockQuantity = raw.stockQuantity
            self.status = raw.status
            self.name = raw.name
            self.stockStatus = raw.stockStatus
            self.sku = raw.sku
        }
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values
    private static let allowedStockStatuses = AllowedProductStockStatuses.values
    static let allowedEntryKeys: Set<String> = Set(ProductsUpdateEntry.CodingKeys.allCases.map(\.rawValue))
    static let allowedArguments: Set<String> = ["updates"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        if let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                        allowed: allowedArguments,
                                                        toolName: name) {
            return .failed(failed)
        }
        if let failed = entryKeyRejection(arguments: arguments) {
            return .failed(failed)
        }
        let envelope: UpdatesEnvelope
        switch RESTToolDispatch.decodeArguments(UpdatesEnvelope.self, from: arguments, toolName: name) {
        case .success(let value): envelope = value
        case .failure(let failed): return .failed(failed)
        }
        guard !envelope.updates.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "updates must not be empty"))
        }
        guard envelope.updates.count <= maxBatchSize else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "updates has \(envelope.updates.count) entries; max is \(maxBatchSize)"))
        }
        let validated: [ValidatedEntry]
        switch validatedEntries(from: envelope.updates) {
        case .valid(let value): validated = value
        case .invalid(let failed): return .failed(failed)
        }
        let discovery = await ProductsUpdateDiscovery(client: client).discover(entries: validated)
        let plans = await ProductsUpdatePlanner(client: client).plan(entries: validated, discovery: discovery)
        let outcomes = await ProductsUpdateBatchDispatcher(client: client).dispatch(plans: plans)
        let receipt = ProductsUpdateReceiptBuilder.build(plans: plans,
                                                         outcomes: outcomes,
                                                         requestedCount: validated.count)
        return finalize(receipt: receipt)
    }

    private enum EntriesValidation {
        case valid([ValidatedEntry])
        case invalid(ToolResult.Failed)
    }

    private static func validatedEntries(from updates: [ProductsUpdateEntry]) -> EntriesValidation {
        var validated: [ValidatedEntry] = []
        var seenTargets: Set<String> = []
        for entry in updates {
            switch validate(entry: entry) {
            case .valid(let value):
                let key = "\(value.target.kind.rawValue):\(value.target.id)"
                if !seenTargets.insert(key).inserted {
                    let reason = "Duplicate target: \(key). Specify each entity at most once per update call."
                    return .invalid(.init(toolName: name, kind: .invalidToolCall, reason: reason))
                }
                validated.append(value)
            case .invalid(let failed):
                return .invalid(failed)
            }
        }
        return .valid(validated)
    }

    private static func finalize(receipt: RunReceipt) -> ToolResult {
        let cappedPayload = LLMPayloadCap.capped(receipt.payload, toolName: name)
        if !receipt.outcomeUnknownStatuses.isEmpty {
            return .failed(.init(toolName: name,
                                 kind: .outcomeUnknown,
                                 reason: outcomeUnknownReason(payload: cappedPayload)))
        }
        return .success(.init(toolName: name,
                              structured: cappedPayload,
                              uiStructured: nil))
    }

    private static func outcomeUnknownReason(payload: AnyCodableJSON) -> String {
        let prefix = "One or more product updates did not get a confirmed response. Verify on the store before retrying."
        do {
            let data = try JSONEncoder().encode(payload)
            guard let json = String(data: data, encoding: .utf8) else { return prefix }
            return "\(prefix) \(json)"
        } catch {
            DDLogError("\(name): failed to encode outcome-unknown payload: \(error)")
            return prefix
        }
    }

    private enum ValidationOutcome {
        case valid(ValidatedEntry)
        case invalid(ToolResult.Failed)
    }

    private static func validate(entry: ProductsUpdateEntry) -> ValidationOutcome {
        let targetResult = validateTarget(entry.target)
        let target: ValidatedEntry.Target
        switch targetResult {
        case .valid(let value): target = value
        case .invalid(let failed): return .invalid(failed)
        }
        guard entry.hasAnyField else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "each entry must set at least one editable field"))
        }
        if let status = entry.status, !allowedStatuses.contains(status) {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        if let stockStatus = entry.stockStatus, !allowedStockStatuses.contains(stockStatus) {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "stock_status must be one of: \(allowedStockStatuses.sorted().joined(separator: ", "))"))
        }
        if let percent = entry.percentDiscount, percent <= 0 || percent >= 100 {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "percent_discount must be between 0 and 100 (exclusive)"))
        }
        return .valid(ValidatedEntry(entry, target: target))
    }

    private enum TargetValidation {
        case valid(ValidatedEntry.Target)
        case invalid(ToolResult.Failed)
    }

    private static func validateTarget(_ raw: ProductsUpdateEntry.Target?) -> TargetValidation {
        guard let raw else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "each entry must include a target object {kind, id, ...}"))
        }
        guard let kindRaw = raw.kind, !kindRaw.isEmpty else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "target.kind is required; use \"product\" or \"variation\""))
        }
        guard let kind = ValidatedEntry.Kind(rawValue: kindRaw) else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "target.kind must be \"product\" or \"variation\""))
        }
        guard let id = raw.id, id > 0 else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "target.id is required and must be a positive integer"))
        }
        var scope: ValidatedEntry.Scope?
        if let scopeRaw = raw.scope {
            guard let resolved = ValidatedEntry.Scope(rawValue: scopeRaw) else {
                return .invalid(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "target.scope must be \"all_variations\" or omitted"))
            }
            scope = resolved
        }
        switch kind {
        case .product:
            if raw.parentID != nil {
                return .invalid(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "target.parent_id is only valid when kind=\"variation\""))
            }
            return .valid(.init(kind: .product, id: id, parentID: nil, scope: scope))
        case .variation:
            if scope != nil {
                return .invalid(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "target.scope is not valid when kind=\"variation\""))
            }
            guard let parentID = raw.parentID, parentID > 0 else {
                return .invalid(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "target.parent_id is required and must be > 0 when kind=\"variation\""))
            }
            guard parentID != id else {
                return .invalid(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "target.parent_id must differ from target.id"))
            }
            return .valid(.init(kind: .variation, id: id, parentID: parentID, scope: nil))
        }
    }

    private static func entryKeyRejection(arguments: String) -> ToolResult.Failed? {
        guard let data = arguments.data(using: .utf8) else { return nil }
        let parsed: [String: Any]?
        do {
            parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            DDLogError("\(name): failed to parse arguments for key rejection: \(error)")
            return nil
        }
        guard let entries = parsed?["updates"] as? [[String: Any]] else {
            return nil
        }
        var unknown: Set<String> = []
        for entry in entries {
            for key in entry.keys where !allowedEntryKeys.contains(key) {
                unknown.insert(key)
            }
        }
        guard !unknown.isEmpty else { return nil }
        let list = unknown.sorted().joined(separator: ", ")
        return .init(toolName: name,
                     kind: .invalidToolCall,
                     reason: "Unsupported \(name) argument(s): \(list)")
    }
}

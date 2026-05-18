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
        variations) in a single call. Each update needs an existing `id` and at least one \
        field to change. The id can reference any product entity - routing is automatic. \
        This tool does NOT create new products or delete products; for those, point the \
        merchant at the Products tab in the app. \
        Editable fields: `regular_price`, `sale_price`, `percent_discount`, `stock_quantity`, \
        `status`, `name`, `stock_status`, `sku`. For percentage-off discounts use \
        `percent_discount` per entry and the server computes per-item `sale_price` from the \
        entity's current regular price. Otherwise set `sale_price` explicitly. When the id \
        is a variable product, `status`/`name`/`sku` update the parent, while \
        `sale_price`/`regular_price`/`percent_discount`/`stock_status` update every variation \
        (`percent_discount` is computed per variation, the rest applied uniformly); both kinds \
        may be combined in one entry. `stock_quantity` on a variable parent is rejected with a \
        pointer to drill into variations. Variations do not have settable names. Variable \
        products with more than 100 variations are refused entirely; issue updates for specific \
        variation ids instead. After a successful update call `show_cards` with each updated \
        entity's id.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "updates": .object([
                    "type": .string("array"),
                    "description": .string("Per-id updates. Each entry must include `id` and at least one field."),
                    "items": .object([
                        "type": .string("object"),
                        "additionalProperties": .bool(false),
                        "properties": .object([
                            "id": .object([
                                "type": .string("integer"),
                                "description": .string("The product or variation ID. Required.")
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
                                "description": .string("Percent off (1-99). Computed against the entity's current regular_price.")
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
                                    + "variations directly. On a variable parent it is applied uniformly to "
                                    + "every variation under it.")
                            ]),
                            "sku": .object([
                                "type": .string("string"),
                                "description": .string("Product or variation SKU. Must be unique store-wide. "
                                    + "On a variable parent, applies to the parent's own SKU slot (not "
                                    + "expanded to variations to avoid uniqueness collisions).")
                            ])
                        ]),
                        "required": .array([.string("id")])
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
    /// `id` guaranteed non-nil so downstream code does not re-check on every read.
    struct ValidatedEntry: Sendable {
        let id: Int
        let regularPrice: String?
        let salePrice: String?
        let percentDiscount: Double?
        let stockQuantity: Int?
        let status: String?
        let name: String?
        let stockStatus: String?
        let sku: String?

        init(_ raw: ProductsUpdateEntry, id: Int) {
            self.id = id
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
        var validated: [ValidatedEntry] = []
        for entry in envelope.updates {
            switch validate(entry: entry) {
            case .valid(let value): validated.append(value)
            case .invalid(let failed): return .failed(failed)
            }
        }
        let captured = await ProductsUpdateDiscovery(client: client).discover(entries: validated)
        let plans = await ProductsUpdatePlanner(client: client).plan(entries: validated, captured: captured)
        let outcomes = await ProductsUpdateBatchDispatcher(client: client).dispatch(plans: plans)
        let receipt = ProductsUpdateReceiptBuilder.build(plans: plans,
                                                         outcomes: outcomes,
                                                         requestedCount: validated.count)
        return finalize(receipt: receipt)
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
        guard let id = entry.id else {
            return .invalid(.init(toolName: name,
                                  kind: .invalidToolCall,
                                  reason: "each entry must include an id"))
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
        return .valid(ValidatedEntry(entry, id: id))
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

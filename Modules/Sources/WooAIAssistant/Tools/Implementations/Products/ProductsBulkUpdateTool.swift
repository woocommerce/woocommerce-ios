import Foundation

public enum ProductsBulkUpdateTool {

    public static let name = "products_bulk_update"

    /// WC silently truncates batches above this server-side default; enforce locally to fail fast.
    public static let maxBatchSize = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Apply the same allowlisted update to many products at once (max 100). \
        Good for category-wide repricing, flipping a set of products to draft, \
        or stock resets after a restock. Per-product differences require \
        separate products_update calls. Variable products in the batch will \
        silently no-op price changes; use product_variations_update for those. \
        Only call when the merchant has explicitly requested a bulk change. \
        Gather the ids from the merchant's message or, when they describe a \
        selection ("all products from the last 5 orders", "every product in \
        the recent orders"), from a prior tool result - resolve unique \
        product_ids from orders_list line_items rather than asking the \
        merchant to type them. After the bulk update succeeds, call \
        `show_cards` with family `product` and the updated ids so the \
        merchant sees the new state.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "ids": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Product IDs to update. Required. Max \(maxBatchSize) per call.")
                ]),
                "patch": .object([
                    "type": .string("object"),
                    "additionalProperties": .bool(false),
                    "properties": .object([
                        "name": .object(["type": .string("string")]),
                        "regular_price": .object(["type": .string("string")]),
                        "sale_price": .object(["type": .string("string")]),
                        "stock_quantity": .object(["type": .string("integer")]),
                        "status": .object([
                            "type": .string("string"),
                            "enum": .array(allowedStatuses.sorted().map { .string($0) })
                        ])
                    ]),
                    "description": .string("Patch applied to every id. At least one field required.")
                ])
            ]),
            "required": .array([.string("ids"), .string("patch")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let ids: [Int]
        let patch: Patch
    }

    private struct Patch: Decodable, Sendable {
        let name: String?
        let regularPrice: String?
        let salePrice: String?
        let stockQuantity: Int?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case name
            case regularPrice = "regular_price"
            case salePrice = "sale_price"
            case stockQuantity = "stock_quantity"
            case status
        }

        var hasAnyField: Bool {
            name != nil || regularPrice != nil || salePrice != nil || stockQuantity != nil || status != nil
        }
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values
    static let allowedArguments: Set<String> = ["ids", "patch"]
    static let allowedPatchKeys: Set<String> = ["name", "regular_price", "sale_price", "stock_quantity", "status"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        if let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                        allowed: allowedArguments,
                                                        toolName: name) {
            return .failed(failed)
        }
        if let failed = patchKeyRejection(arguments: arguments) {
            return .failed(failed)
        }
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        guard !args.ids.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "ids must not be empty"))
        }
        guard args.ids.count <= maxBatchSize else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "ids has \(args.ids.count) entries; max is \(maxBatchSize)"))
        }
        if let status = args.patch.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        guard args.patch.hasAnyField else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "patch must set at least one field"))
        }

        var template: [String: Any] = [:]
        if let value = args.patch.name { template["name"] = value }
        if let value = args.patch.regularPrice { template["regular_price"] = value }
        if let value = args.patch.salePrice { template["sale_price"] = value }
        if let value = args.patch.stockQuantity {
            template["stock_quantity"] = value
            template["manage_stock"] = true
        }
        if let value = args.patch.status { template["status"] = value }

        let updates: [[String: Any]] = args.ids.map { id in
            var entry = template
            entry["id"] = id
            return entry
        }
        guard let payload = try? JSONSerialization.data(withJSONObject: ["update": updates]) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "could not serialize batch body"))
        }
        let patchKeys = patchKeysInOrder(args.patch)
        return await RESTToolDispatch.dispatchBatchWrite(method: "POST",
                                                         path: "wc/v3/products/batch",
                                                         body: payload,
                                                         client: client,
                                                         toolName: name,
                                                         requestedCount: args.ids.count,
                                                         patchKeys: patchKeys)
    }

    private static func patchKeysInOrder(_ patch: Patch) -> [String] {
        var keys: [String] = []
        if patch.name != nil { keys.append("name") }
        if patch.regularPrice != nil { keys.append("regular_price") }
        if patch.salePrice != nil { keys.append("sale_price") }
        if patch.stockQuantity != nil { keys.append("stock_quantity") }
        if patch.status != nil { keys.append("status") }
        return keys
    }

    private static func patchKeyRejection(arguments: String) -> ToolResult.Failed? {
        guard let data = arguments.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let patch = parsed["patch"] as? [String: Any] else {
            return nil
        }
        let unknown = patch.keys.filter { !allowedPatchKeys.contains($0) }.sorted()
        guard !unknown.isEmpty else { return nil }
        return .init(toolName: name,
                     kind: .invalidToolCall,
                     reason: "Unsupported \(name) argument(s): \(unknown.joined(separator: ", "))")
    }
}

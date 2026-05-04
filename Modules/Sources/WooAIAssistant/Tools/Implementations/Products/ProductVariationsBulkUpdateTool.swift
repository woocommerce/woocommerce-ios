import Foundation
import CocoaLumberjackSwift

public enum ProductVariationsBulkUpdateTool {

    public static let name = "product_variations_bulk_update"

    /// WC silently truncates batches above this server-side default; enforce locally to fail fast.
    public static let maxBatchSize = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Update many variations of the same parent product in one batch (max \
        100). Each entry sets allowlisted fields per variation: regular_price, \
        sale_price, stock_quantity, stock_status, sku, status. Use this \
        instead of multiple product_variations_update calls when more than \
        one variation of the same parent is being updated together.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "product_id": .object([
                    "type": .string("integer"),
                    "description": .string("Parent (variable) product ID. Required.")
                ]),
                "variations": .object([
                    "type": .string("array"),
                    "description": .string("Per-variation updates. Each entry must include the variation id."),
                    "items": .object([
                        "type": .string("object"),
                        "additionalProperties": .bool(false),
                        "properties": .object([
                            "id": .object([
                                "type": .string("integer"),
                                "description": .string("Variation ID. Required.")
                            ]),
                            "regular_price": .object(["type": .string("string")]),
                            "sale_price": .object(["type": .string("string")]),
                            "stock_quantity": .object([
                                "type": .string("integer"),
                                "description": .string("Sets manage_stock=true automatically.")
                            ]),
                            "stock_status": .object([
                                "type": .string("string"),
                                "enum": .array(allowedStockStatuses.sorted().map { .string($0) })
                            ]),
                            "sku": .object(["type": .string("string")]),
                            "status": .object([
                                "type": .string("string"),
                                "enum": .array(allowedStatuses.sorted().map { .string($0) })
                            ])
                        ]),
                        "required": .array([.string("id")])
                    ])
                ])
            ]),
            "required": .array([.string("product_id"), .string("variations")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let productID: Int
        let variations: [Variation]

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case variations
        }
    }

    private struct Variation: Decodable, Sendable {
        let id: Int
        let regularPrice: String?
        let salePrice: String?
        let stockQuantity: Int?
        let stockStatus: String?
        let sku: String?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case id
            case regularPrice = "regular_price"
            case salePrice = "sale_price"
            case stockQuantity = "stock_quantity"
            case stockStatus = "stock_status"
            case sku, status
        }

        var hasAnyField: Bool {
            regularPrice != nil || salePrice != nil || stockQuantity != nil
                || stockStatus != nil || sku != nil || status != nil
        }
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values
    private static let allowedStockStatuses: Set<String> = ["instock", "outofstock", "onbackorder"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        guard !args.variations.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "variations must not be empty"))
        }
        guard args.variations.count <= maxBatchSize else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "variations has \(args.variations.count) entries; max is \(maxBatchSize)"))
        }
        for variation in args.variations {
            if let status = variation.status, !allowedStatuses.contains(status) {
                return .failed(.init(toolName: name,
                                     kind: .invalidToolCall,
                                     reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
            }
            if let stockStatus = variation.stockStatus, !allowedStockStatuses.contains(stockStatus) {
                return .failed(.init(toolName: name,
                                     kind: .invalidToolCall,
                                     reason: "stock_status must be one of: \(allowedStockStatuses.sorted().joined(separator: ", "))"))
            }
            guard variation.hasAnyField else {
                return .failed(.init(toolName: name,
                                     kind: .invalidToolCall,
                                     reason: "each variation must set at least one editable field"))
            }
        }

        let updates: [[String: Any]] = args.variations.map { variation in
            var entry: [String: Any] = ["id": variation.id]
            if let value = variation.regularPrice { entry["regular_price"] = value }
            if let value = variation.salePrice { entry["sale_price"] = value }
            if let value = variation.stockQuantity {
                entry["stock_quantity"] = value
                entry["manage_stock"] = true
            }
            if let value = variation.stockStatus { entry["stock_status"] = value }
            if let value = variation.sku { entry["sku"] = value }
            if let value = variation.status { entry["status"] = value }
            return entry
        }
        let payload: Data
        do {
            payload = try JSONSerialization.data(withJSONObject: ["update": updates])
        } catch {
            DDLogError("[ProductVariationsBulkUpdateTool] Failed to encode batch body: \(error)")
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "could not serialize batch body"))
        }
        return await RESTToolDispatch.dispatchBatchWrite(method: "POST",
                                                         path: "wc/v3/products/\(args.productID)/variations/batch",
                                                         body: payload,
                                                         client: client,
                                                         toolName: name,
                                                         family: .productVariation)
    }
}

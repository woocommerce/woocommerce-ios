import Foundation
import Storage
import Yosemite

public enum ProductsBulkUpdateTool {
    public static let name = "products_bulk_update"
    public static let maxBatchSize = 100

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        ProductsBulkUpdateToolImplementation(dataSource: AssistantProductsDataSource(siteID: siteID,
                                                                                     storageManager: storageManager,
                                                                                     dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantProductsDataSourceProtocol) -> RESTTool {
        ProductsBulkUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct ProductsBulkUpdateToolImplementation: Sendable {
    private static let name = ProductsBulkUpdateTool.name
    private static let maxBatchSize = ProductsBulkUpdateTool.maxBatchSize

    private let dataSource: any AssistantProductsDataSourceProtocol

    init(dataSource: any AssistantProductsDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func makeRESTTool() -> RESTTool {
        RESTTool(definition: Self.definition) { arguments, _ in
            await execute(arguments: arguments)
        }
    }

    private static let definition = AITool(
        name: name,
        description: """
        Apply the same allowlisted update to many products at once (max 100). \
        Good for category-wide repricing, flipping a set of products to draft, \
        or stock resets after a restock. Per-product differences require \
        separate products_update calls. Variable products in the batch will \
        silently no-op price changes; use product_variations_update for those. \
        Only call when the merchant has explicitly requested a bulk change \
        with a concrete list of ids.
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

        var productPatch: ProductUpdatePatch {
            ProductUpdatePatch(name: name,
                               regularPrice: regularPrice,
                               salePrice: salePrice,
                               stockQuantity: stockQuantity,
                               status: status)
        }
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values

    private func execute(arguments: String) async -> ToolResult {
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: Self.name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let failure = validate(args: args) {
            return .failed(failure)
        }

        let builder = WriteToolResultBuilder(toolName: Self.name)
        switch await dataSource.bulkUpdateProducts(ids: args.ids.map(Int64.init), patch: args.patch.productPatch) {
        case .success(let result):
            return builder.batchSuccess(result)
        case .failure(let error):
            return builder.failure(error)
        }
    }

    private func validate(args: Args) -> ToolResult.Failed? {
        guard !args.ids.isEmpty else {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: "ids must not be empty")
        }
        guard args.ids.count <= Self.maxBatchSize else {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: "ids has \(args.ids.count) entries; max is \(Self.maxBatchSize)")
        }
        if let status = args.patch.status, !Self.allowedStatuses.contains(status) {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses))
        }
        guard args.patch.productPatch.hasAnyField else {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: "patch must set at least one field")
        }
        return nil
    }
}

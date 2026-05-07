import Foundation
import Storage
import Yosemite

public enum ProductVariationsBulkUpdateTool {
    public static let name = "product_variations_bulk_update"
    public static let maxBatchSize = 100

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        ProductVariationsBulkUpdateToolImplementation(dataSource: AssistantProductVariationsDataSource(siteID: siteID,
                                                                                                       storageManager: storageManager,
                                                                                                       dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantProductVariationsDataSourceProtocol) -> RESTTool {
        ProductVariationsBulkUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct ProductVariationsBulkUpdateToolImplementation: Sendable {
    private static let name = ProductVariationsBulkUpdateTool.name
    private static let maxBatchSize = ProductVariationsBulkUpdateTool.maxBatchSize

    private let dataSource: any AssistantProductVariationsDataSourceProtocol

    init(dataSource: any AssistantProductVariationsDataSourceProtocol) {
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

        var patch: ProductVariationUpdatePatch {
            ProductVariationUpdatePatch(regularPrice: regularPrice,
                                        salePrice: salePrice,
                                        stockQuantity: stockQuantity,
                                        stockStatus: stockStatus,
                                        sku: sku,
                                        status: status)
        }
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values
    private static let allowedStockStatuses: Set<String> = ["instock", "outofstock", "onbackorder"]

    private func execute(arguments: String) async -> ToolResult {
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: Self.name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let failure = validate(args: args) {
            return .failed(failure)
        }

        let updates = args.variations.map {
            ProductVariationBatchPatch(id: Int64($0.id), patch: $0.patch)
        }
        let builder = WriteToolResultBuilder(toolName: Self.name)
        switch await dataSource.bulkUpdateVariations(productID: Int64(args.productID), patches: updates) {
        case .success(let result):
            return builder.batchSuccess(result)
        case .failure(let error):
            return builder.failure(error)
        }
    }

    private func validate(args: Args) -> ToolResult.Failed? {
        guard !args.variations.isEmpty else {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: "variations must not be empty")
        }
        guard args.variations.count <= Self.maxBatchSize else {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: "variations has \(args.variations.count) entries; max is \(Self.maxBatchSize)")
        }
        for variation in args.variations {
            if let status = variation.status, !Self.allowedStatuses.contains(status) {
                return .init(toolName: Self.name,
                             kind: .invalidToolCall,
                             reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses))
            }
            if let stockStatus = variation.stockStatus, !Self.allowedStockStatuses.contains(stockStatus) {
                return .init(toolName: Self.name,
                             kind: .invalidToolCall,
                             reason: RESTToolDispatch.allowedValuesMessage(field: "stock_status", values: Self.allowedStockStatuses))
            }
            guard variation.patch.hasAnyField else {
                return .init(toolName: Self.name,
                             kind: .invalidToolCall,
                             reason: "each variation must set at least one editable field")
            }
        }
        return nil
    }
}

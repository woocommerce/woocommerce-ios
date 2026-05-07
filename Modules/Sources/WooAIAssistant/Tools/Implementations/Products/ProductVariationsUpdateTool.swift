import Foundation
import Storage
import Yosemite

public enum ProductVariationsUpdateTool {
    public static let name = "product_variations_update"

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        ProductVariationsUpdateToolImplementation(dataSource: AssistantProductVariationsDataSource(siteID: siteID,
                                                                                                   storageManager: storageManager,
                                                                                                   dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantProductVariationsDataSourceProtocol) -> RESTTool {
        ProductVariationsUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct ProductVariationsUpdateToolImplementation: Sendable {
    private static let name = ProductVariationsUpdateTool.name

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
        Update a product variation's allowlisted fields: regular_price, \
        sale_price, stock_quantity, stock_status, sku, status. Provide only \
        the fields you want to change. Requires product_id (parent) and id \
        (variation). Only call when the merchant has explicitly requested a \
        change; never call to answer an information question.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "product_id": .object([
                    "type": .string("integer"),
                    "description": .string("Parent (variable) product ID. Required.")
                ]),
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
            "required": .array([.string("product_id"), .string("id")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let productID: Int
        let id: Int
        let regularPrice: String?
        let salePrice: String?
        let stockQuantity: Int?
        let stockStatus: String?
        let sku: String?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
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

        let builder = WriteToolResultBuilder(toolName: Self.name)
        switch await dataSource.updateVariation(productID: Int64(args.productID),
                                                variationID: Int64(args.id),
                                                patch: args.patch) {
        case .success(let variation):
            return builder.cardSuccess(family: .productVariation,
                                       id: variation.productVariationID,
                                       payload: CardEntityPayloadFactory.payload(from: variation))
        case .failure(let error):
            return builder.failure(error)
        }
    }

    private func validate(args: Args) -> ToolResult.Failed? {
        if let status = args.status, !Self.allowedStatuses.contains(status) {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses))
        }
        if let stockStatus = args.stockStatus, !Self.allowedStockStatuses.contains(stockStatus) {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: RESTToolDispatch.allowedValuesMessage(field: "stock_status", values: Self.allowedStockStatuses))
        }
        guard args.patch.hasAnyField else {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: "at least one editable field must be provided")
        }
        return nil
    }
}

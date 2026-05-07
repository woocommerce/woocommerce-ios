import Foundation
import Storage
import Yosemite

public enum ProductsUpdateTool {
    public static let name = "products_update"

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        ProductsUpdateToolImplementation(dataSource: AssistantProductsDataSource(siteID: siteID,
                                                                                 storageManager: storageManager,
                                                                                 dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantProductsDataSourceProtocol) -> RESTTool {
        ProductsUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct ProductsUpdateToolImplementation: Sendable {
    private static let name = ProductsUpdateTool.name

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
        Update a product's allowlisted fields: name, regular_price, sale_price, \
        stock_quantity, status. Provide only the fields you want to change. For \
        variable products, prices live on each variation - use \
        product_variations_update on the parent's variations instead. Only call \
        when the merchant has explicitly requested a change; never call to answer \
        an information question.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "id": .object([
                    "type": .string("integer"),
                    "description": .string("The product ID. Required.")
                ]),
                "name": .object(["type": .string("string")]),
                "regular_price": .object([
                    "type": .string("string"),
                    "description": .string("Decimal string, e.g. \"19.99\".")
                ]),
                "sale_price": .object([
                    "type": .string("string"),
                    "description": .string("Decimal string. Empty string clears the sale price.")
                ]),
                "stock_quantity": .object([
                    "type": .string("integer"),
                    "description": .string("Sets manage_stock=true automatically so the change sticks.")
                ]),
                "status": .object([
                    "type": .string("string"),
                    "enum": .array(allowedStatuses.sorted().map { .string($0) })
                ])
            ]),
            "required": .array([.string("id")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let id: Int
        let name: String?
        let regularPrice: String?
        let salePrice: String?
        let stockQuantity: Int?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case regularPrice = "regular_price"
            case salePrice = "sale_price"
            case stockQuantity = "stock_quantity"
            case status
        }

        var patch: ProductUpdatePatch {
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
        if let status = args.status, !Self.allowedStatuses.contains(status) {
            return .failed(.init(toolName: Self.name,
                                 kind: .invalidToolCall,
                                 reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses)))
        }
        guard args.patch.hasAnyField else {
            return .failed(.init(toolName: Self.name,
                                 kind: .invalidToolCall,
                                 reason: "at least one editable field must be provided"))
        }

        let builder = WriteToolResultBuilder(toolName: Self.name)
        switch await dataSource.updateProduct(id: Int64(args.id), patch: args.patch) {
        case .success(let product):
            return builder.cardSuccess(family: .product,
                                       id: product.productID,
                                       payload: CardEntityPayloadFactory.payload(from: product))
        case .failure(let error):
            if error is AssistantDataSourceError {
                return .failed(.init(toolName: Self.name,
                                     kind: .invalidToolCall,
                                     reason: error.localizedDescription))
            }
            return builder.failure(error)
        }
    }
}

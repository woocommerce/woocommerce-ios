import Foundation

public enum ProductVariationsUpdateTool {

    public static let name = "product_variations_update"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
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
    }

    private static let allowedStatuses = AllowedProductUpdateStatuses.values
    private static let allowedStockStatuses: Set<String> = ["instock", "outofstock", "onbackorder"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let status = args.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        if let stockStatus = args.stockStatus, !allowedStockStatuses.contains(stockStatus) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "stock_status must be one of: \(allowedStockStatuses.sorted().joined(separator: ", "))"))
        }

        var body: [String: Any] = [:]
        if let value = args.regularPrice { body["regular_price"] = value }
        if let value = args.salePrice { body["sale_price"] = value }
        if let value = args.stockQuantity {
            body["stock_quantity"] = value
            body["manage_stock"] = true
        }
        if let value = args.stockStatus { body["stock_status"] = value }
        if let value = args.sku { body["sku"] = value }
        if let value = args.status { body["status"] = value }

        guard !body.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "at least one editable field must be provided"))
        }
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "could not serialize update body"))
        }
        return await RESTToolDispatch.dispatchEntityWrite(method: "PUT",
                                                          path: "wc/v3/products/\(args.productID)/variations/\(args.id)",
                                                          body: payload,
                                                          client: client,
                                                          toolName: name,
                                                          family: .product,
                                                          summarize: ProductSummary.make)
    }
}

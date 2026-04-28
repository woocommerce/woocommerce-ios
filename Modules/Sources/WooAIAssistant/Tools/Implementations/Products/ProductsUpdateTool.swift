import Foundation

public enum ProductsUpdateTool {

    public static let name = "products_update"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Update a product's allowlisted fields: name, regular_price, sale_price, \
        stock_quantity, status. Provide only the fields you want to change. For \
        variable products, prices live on each variation - use \
        product_variations_update on the parent's variations instead.
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
        ])
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
    }

    private static let allowedStatuses: Set<String> = ["draft", "pending", "private", "publish"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let status = args.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 toolCallID: "",
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }

        var body: [String: Any] = [:]
        if let value = args.name { body["name"] = value }
        if let value = args.regularPrice { body["regular_price"] = value }
        if let value = args.salePrice { body["sale_price"] = value }
        if let value = args.stockQuantity {
            body["stock_quantity"] = value
            body["manage_stock"] = true
        }
        if let value = args.status { body["status"] = value }

        guard !body.isEmpty else {
            return .failed(.init(toolName: name,
                                 toolCallID: "",
                                 kind: .invalidToolCall,
                                 reason: "at least one editable field must be provided"))
        }

        // Pre-flight GET catches WC's silent no-op when price is set on a variable parent;
        // the extra round-trip on simple products is cheaper than looping on a no-op write.
        if body["regular_price"] != nil || body["sale_price"] != nil {
            if let failure = await variablePriceRefusal(productID: args.id, client: client) {
                return .failed(failure)
            }
        }

        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return .failed(.init(toolName: name,
                                 toolCallID: "",
                                 kind: .invalidToolCall,
                                 reason: "could not serialize update body"))
        }
        return await RESTToolDispatch.dispatchEntityWrite(method: "PUT",
                                                          path: "wc/v3/products/\(args.id)",
                                                          body: payload,
                                                          client: client,
                                                          toolName: name,
                                                          family: .product,
                                                          summarize: ProductSummary.make)
    }

    private static func variablePriceRefusal(productID: Int, client: WCRESTClient) async -> ToolResult.Failed? {
        let probe = await client.request(method: "GET",
                                         path: "wc/v3/products/\(productID)",
                                         query: nil,
                                         body: nil)
        guard HTTPStatusClassification.isSuccess(probe.statusCode),
              let entity = RESTResponseParsing.decodeJSON(probe.data),
              RESTResponseParsing.stringField(entity, "type") == "variable" else {
            return nil
        }
        let reason = "Product #\(productID) is a variable product; price lives on each variation, not the parent. " +
                     "Call product_variations_list(product_id: \(productID)) to enumerate variations, then update each via product_variations_update."
        return .init(toolName: name,
                     toolCallID: "",
                     kind: .invalidToolCall,
                     reason: reason)
    }
}

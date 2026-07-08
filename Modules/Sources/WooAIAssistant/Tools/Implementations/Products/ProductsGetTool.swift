import Foundation

public enum ProductsGetTool {

    public static let name = "products_get"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Fetch a single product with full detail (price, stock, categories, \
        type, full description). Use when the merchant references a specific \
        product by ID, including by position from a prior turn ("the first \
        one", "that product"). Required when the merchant asks about the \
        full description, categories, or other fields the rendered product \
        card doesn't surface. For variations / sizes / colors of variable \
        products, use product_variations_list instead. Don't redundantly \
        call this to re-render an existing card; only fetch when the \
        merchant asks for fields the card doesn't show.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "id": .object([
                    "type": .string("integer"),
                    "description": .string("The product ID. Required.")
                ])
            ]),
            "required": .array([.string("id")])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let id: Int
    }

    private static let allowedArguments: Set<String> = ["id"]

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        if let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                        allowed: allowedArguments,
                                                        toolName: name) {
            return .failed(failed)
        }
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(args.id)",
                                            query: nil,
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "expected JSON object"))
        }
        let pruned = RESTPayloadPruning.prune(entity)
        let summary = ProductSummary.make(from: pruned)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name)))
    }
}

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
        type). Use when the merchant references a specific product by ID. \
        For variable products use product_variations_list to inspect the \
        variants.
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
        ])
    )

    private struct Args: Decodable, Sendable {
        let id: Int
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(args.id)",
                                            query: nil,
                                            body: nil,
                                            headers: nil)
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
        let card = RenderedCardPayload(family: .product,
                                       id: RESTResponseParsing.intField(pruned, "id") ?? Int64(args.id),
                                       element: pruned)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: UIStructured(cards: [card])))
    }
}

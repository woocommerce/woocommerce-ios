import Foundation

public enum ProductsGetTool {
    public static let name = "products_get"

    public static func make() -> RESTTool {
        ProductsGetToolImplementation().makeRESTTool()
    }
}

private struct ProductsGetToolImplementation: Sendable {

    private static let name = ProductsGetTool.name

    func makeRESTTool() -> RESTTool {
        RESTTool(definition: Self.definition) { arguments, client in
            await execute(arguments: arguments, client: client)
        }
    }

    private static let definition = AITool(
        name: name,
        description: """
        Fetch a single product with full detail (price, stock, categories, \
        type). Use when the merchant references a specific product by ID. \
        For variable products, use product_variations_list only when the \
        merchant explicitly asks about variations, sizes, colors, options, or \
        variation-level stock. Do NOT call this tool to render a card after products_list \
        - `show_cards` re-fetches product detail itself when given a reference. \
        Use bounded fanout: only call after a list/card when the merchant \
        asks for fields the list summary or card doesn't show, and limit to \
        the specific entity referenced.
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

    private func execute(arguments: String, client: WCRESTClient) async -> ToolResult {
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: Self.name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(args.id)",
                                            query: nil,
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: Self.name))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
            return .failed(.init(toolName: Self.name,
                                 kind: .toolFailed,
                                 reason: "expected JSON object"))
        }
        let pruned = RESTPayloadPruning.prune(entity)
        let summary = ProductSummary.make(from: pruned)
        return .success(.init(toolName: Self.name,
                              structured: LLMPayloadCap.capped(summary, toolName: Self.name)))
    }
}

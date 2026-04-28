import Foundation

public enum ProductVariationsListTool {

    public static let name = "product_variations_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List the variations of a variable product. Required: product_id (the \
        parent). Use after products_list / products_get surfaces a variable \
        product to answer "what sizes are available", "which variant is out \
        of stock", etc.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "product_id": .object([
                    "type": .string("integer"),
                    "description": .string("The parent (variable) product ID. Required.")
                ]),
                "page": .object([
                    "type": .string("integer"),
                    "description": .string("1-based page number; default 1.")
                ]),
                "per_page": .object([
                    "type": .string("integer"),
                    "description": .string("Max items; clamped 1-50, default 20.")
                ])
            ]),
            "required": .array([.string("product_id")])
        ])
    )

    private struct Args: Decodable, Sendable {
        let productID: Int
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case page
            case perPage = "per_page"
        }
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        var query: [String: String] = [
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if let page = args.page, page > 1 { query["page"] = String(page) }

        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(args.productID)/variations",
                                            query: query,
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "expected JSON array"))
        }
        let summary = ProductVariationsListSummary.make(productID: Int64(args.productID), from: rows)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

import Foundation

public enum ProductVariationsListTool {
    public static let name = "product_variations_list"

    public static func make() -> RESTTool {
        ProductVariationsListToolImplementation().makeRESTTool()
    }
}

private struct ProductVariationsListToolImplementation: Sendable {

    private static let name = ProductVariationsListTool.name

    func makeRESTTool() -> RESTTool {
        RESTTool(definition: Self.definition) { arguments, client in
            await execute(arguments: arguments, client: client)
        }
    }

    private static let definition = AITool(
        name: name,
        description: """
        List variations for one variable product when the merchant explicitly \
        asks about variations, sizes, colors, options, or a known variation \
        ID. Required: product_id (the parent). Do not use this for broad \
        product-level inventory questions such as "out-of-stock products"; \
        product stock and variation stock are separate WooCommerce concepts.
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
        ]),
        safetyLevel: .safe
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

    private func execute(arguments: String, client: WCRESTClient) async -> ToolResult {
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: Self.name) {
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
            return .failed(RESTToolDispatch.failed(from: response, toolName: Self.name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return .failed(.init(toolName: Self.name,
                                 kind: .toolFailed,
                                 reason: "expected JSON array"))
        }
        let summary = ProductVariationsListSummary.make(productID: Int64(args.productID), from: rows)
        return .success(.init(toolName: Self.name,
                              structured: LLMPayloadCap.capped(summary, toolName: Self.name),
                              uiStructured: nil))
    }
}

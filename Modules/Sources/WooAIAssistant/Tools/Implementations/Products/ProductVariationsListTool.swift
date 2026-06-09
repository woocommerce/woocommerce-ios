import Foundation

public enum ProductVariationsListTool {

    public static let name = "product_variations_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List variations for one variable product, or fetch a single variation \
        when `variation_id` is given. Use when the merchant explicitly asks \
        about variations, sizes, colors, options, or a known variation ID. \
        Required: product_id (the parent). Pass variation_id to retrieve just \
        that one variation with full detail instead of the whole list. Do not \
        use this for broad product-level inventory questions such as \
        "out-of-stock products"; product stock and variation stock are \
        separate WooCommerce concepts.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "product_id": .object([
                    "type": .string("integer"),
                    "description": .string("The parent (variable) product ID. Required.")
                ]),
                "variation_id": .object([
                    "type": .string("integer"),
                    "description": .string("Optional. When set, fetch just this one variation with full detail "
                        + "instead of listing all variations.")
                ]),
                "page": .object([
                    "type": .string("integer"),
                    "description": .string("1-based page number; default 1. Ignored when variation_id is set.")
                ]),
                "per_page": .object([
                    "type": .string("integer"),
                    "description": .string("Max items; clamped 1-50, default 20. Ignored when variation_id is set.")
                ])
            ]),
            "required": .array([.string("product_id")])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let productID: Int
        let variationID: Int?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case variationID = "variation_id"
            case page
            case perPage = "per_page"
        }
    }

    private static let allowedArguments: Set<String> = ["product_id", "variation_id", "page", "per_page"]

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
        if let variationID = args.variationID {
            return await fetchSingle(productID: args.productID, variationID: variationID, client: client)
        }
        return await fetchList(args: args, client: client)
    }

    private static func fetchSingle(productID: Int,
                                    variationID: Int,
                                    client: WCRESTClient) async -> ToolResult {
        let response = await client.request(method: "GET",
                                            path: "wc/v3/products/\(productID)/variations/\(variationID)",
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
        let summary = ProductVariationDetailSummary.make(from: RESTPayloadPruning.prune(entity))
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }

    private static func fetchList(args: Args, client: WCRESTClient) async -> ToolResult {
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

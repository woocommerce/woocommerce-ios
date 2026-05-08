import Foundation

public enum ProductsListTool {

    public static let name = "products_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List products, optionally filtered by status, category, tag, sku, \
        or keyword search. Terse merchant phrases such as "get scarf", \
        "show scarf", "find scarf", or "product scarf" are product searches: \
        use search with the product noun or phrase. For top / best-selling \
        product questions, use orderby=popularity, order=desc, then pass results to `show_cards`. \
        For latest/last single-product questions, use per_page=1, orderby=date, \
        order=desc, then pass the result to `show_cards`. \
        For aggregate sales totals prefer analytics tools. For prose \
        questions about a specific product's stock quantity, prices, etc., \
        call products_get with the ID. After calling, pass returned ids to \
        `show_cards` to render rather than re-fetching each product with \
        products_get; never say no match was found unless the returned count \
        is zero. \
        Do not use this tool to resolve a pronoun, ordinal, or qualifier when \
        prior product rows/cards are already in context; use the prior id with \
        `show_cards`. If a search returns no matches, do not retry with \
        synonyms or broader terms - say no match was found.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "search": .object([
                    "type": .string("string"),
                    "description": .string("Free-text search across product name and content.")
                ]),
                "status": .object([
                    "type": .string("string"),
                    "enum": .array([.string("any"), .string("draft"), .string("pending"),
                                    .string("private"), .string("publish")]),
                    "description": .string("Publication status; default 'any'.")
                ]),
                "category": .object([
                    "type": .string("integer"),
                    "description": .string("Category ID filter.")
                ]),
                "tag": .object([
                    "type": .string("integer"),
                    "description": .string("Tag ID filter.")
                ]),
                "sku": .object([
                    "type": .string("string"),
                    "description": .string("Exact SKU lookup.")
                ]),
                "include": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Specific product IDs to include.")
                ]),
                "stock_status": .object([
                    "type": .string("string"),
                    "enum": .array([.string("instock"), .string("outofstock"), .string("onbackorder")]),
                    "description": .string("Filter by stock status. Use 'outofstock' or 'onbackorder' for low-stock-style queries.")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array([.string("date"), .string("id"), .string("title"),
                                    .string("price"), .string("popularity"), .string("rating")]),
                    "description": .string("Sort key; default 'date'. Use 'popularity' for top / best-selling products.")
                ]),
                "order": .object([
                    "type": .string("string"),
                    "enum": .array([.string("asc"), .string("desc")]),
                    "description": .string("Sort direction; default 'desc'.")
                ]),
                "page": .object([
                    "type": .string("integer"),
                    "description": .string("1-based page number; default 1.")
                ]),
                "per_page": .object([
                    "type": .string("integer"),
                    "description": .string("Max items; clamped 1-50, default 20.")
                ])
            ])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let search: String?
        let status: String?
        let category: Int?
        let tag: Int?
        let sku: String?
        let include: [Int]?
        let stockStatus: String?
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case search, status, category, tag, sku, include, orderby, order, page
            case stockStatus = "stock_status"
            case perPage = "per_page"
        }
    }

    private static func query(from args: Args) -> [String: String] {
        var query: [String: String] = [
            "orderby": args.orderby ?? "date",
            "order": args.order ?? "desc",
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if let status = args.status, status != "any" { query["status"] = status }
        if let search = args.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query["search"] = search
        }
        if let category = args.category { query["category"] = String(category) }
        if let tag = args.tag { query["tag"] = String(tag) }
        if let sku = args.sku?.trimmingCharacters(in: .whitespacesAndNewlines), !sku.isEmpty {
            query["sku"] = sku
        }
        if let include = args.include, !include.isEmpty {
            query["include"] = include.map(String.init).joined(separator: ",")
        }
        if let stockStatus = args.stockStatus?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stockStatus.isEmpty {
            query["stock_status"] = stockStatus
        }
        if let page = args.page, page > 1 { query["page"] = String(page) }
        return query
    }

    static let allowedArguments: Set<String> = [
        "search", "status", "category", "tag", "sku", "include", "stock_status",
        "orderby", "order", "page", "per_page"
    ]

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
                                            path: "wc/v3/products",
                                            query: query(from: args),
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
        let summary = ProductsListSummary.make(from: rows)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

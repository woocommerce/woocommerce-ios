import Foundation

public enum ProductsListTool {

    public static let name = "products_list"
    public static let maxIncludeIDs = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List products, optionally filtered by status, category, sku, \
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
                "sku": .object([
                    "type": .string("string"),
                    "description": .string("Exact SKU lookup.")
                ]),
                "include": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Specific product IDs to include. Max \(maxIncludeIDs).")
                ]),
                "stock_status": .object([
                    "type": .string("string"),
                    "enum": .array([.string("instock"), .string("outofstock"), .string("onbackorder")]),
                    "description": .string("Filter by stock status. Use 'outofstock' or 'onbackorder' for low-stock-style queries.")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array([.string("date"), .string("title"), .string("popularity")]),
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
        let sku: String?
        let include: [Int]?
        let stockStatus: String?
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case search, status, category, sku, include, orderby, order, page
            case stockStatus = "stock_status"
            case perPage = "per_page"
        }
    }

    private static let allowedOrderby: Set<String> = ["date", "title", "popularity"]
    private static let allowedOrder: Set<String> = ["asc", "desc"]

    private static func query(from args: Args) -> [String: String] {
        var query: [String: String] = [
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if args.include?.isEmpty == false {
            query["orderby"] = "include"
        } else {
            query["orderby"] = args.orderby ?? "date"
            query["order"] = args.order ?? "desc"
        }
        if let status = args.status, status != "any" { query["status"] = status }
        if let search = args.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query["search"] = search
        }
        if let category = args.category { query["category"] = String(category) }
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
        "search", "status", "category", "sku", "include", "stock_status",
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
        if let failed = validateCombinations(args) {
            return .failed(failed)
        }
        let perPage = RESTToolDispatch.clampedPerPage(args.perPage)
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
        let canLoadMore = canLoadMore(rowsCount: rows.count, perPage: perPage, args: args)
        let summary = ProductsListSummary.make(from: rows, canLoadMore: canLoadMore)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }

    private static func validateCombinations(_ args: Args) -> ToolResult.Failed? {
        if let include = args.include {
            if include.isEmpty {
                return failure("include must contain at least one product ID.")
            }
            if include.count > maxIncludeIDs {
                return failure("include can contain at most \(maxIncludeIDs) product IDs.")
            }
            let conflicts = (args.search != nil) || (args.sku != nil) || (args.orderby != nil) || (args.order != nil)
            if conflicts {
                return failure("include cannot be combined with search, sku, orderby, or order.")
            }
        }
        if (args.orderby != nil || args.order != nil) && (args.search != nil || args.sku != nil) {
            return failure("orderby and order cannot be combined with search or sku.")
        }
        if let orderby = args.orderby, !allowedOrderby.contains(orderby) {
            return failure("'\(orderby)' is not an allowed orderby.")
        }
        if let order = args.order, !allowedOrder.contains(order) {
            return failure("'\(order)' is not an allowed order.")
        }
        return nil
    }

    private static func failure(_ reason: String) -> ToolResult.Failed {
        .init(toolName: name, kind: .invalidToolCall, reason: reason)
    }

    private static func canLoadMore(rowsCount: Int, perPage: Int, args: Args) -> Bool {
        if let include = args.include, !include.isEmpty {
            let page = max(1, args.page ?? 1)
            return include.count > page * perPage
        }
        return rowsCount >= perPage
    }
}

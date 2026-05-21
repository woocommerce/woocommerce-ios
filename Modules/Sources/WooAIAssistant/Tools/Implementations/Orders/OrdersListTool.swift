import Foundation

public enum OrdersListTool {

    public static let name = "orders_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List orders, optionally filtered by status, date range, or customer. \
        Use to find specific orders, list pending fulfilment, or pull the most \
        recent N. For latest/last single-order questions, use per_page=1, \
        orderby=date, order=desc, then pass the result to `show_cards`. \
        For aggregate sales numbers prefer analytics_orders. For prose \
        questions about a specific order's payment method, customer email, \
        etc., call orders_get with the ID. \
        After calling, pass results to `show_cards` to render rather than \
        re-fetching each order with orders_get. Each line_item carries a \
        `target` object {kind, id, parent_id?} you can pass directly to \
        products_update.updates[].target - the target encodes whether the \
        line is a simple product or a specific variation, so you do not need \
        to interpret product_id or variation_id yourself. If a search \
        returns no matches, do not retry with synonyms or broader terms - \
        say no match was found.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "status": .object([
                    "type": .string("string"),
                    "enum": .array([.string("any"), .string("pending"), .string("processing"),
                                    .string("on-hold"), .string("completed"), .string("cancelled"),
                                    .string("refunded"), .string("failed"), .string("trash")]),
                    "description": .string("Order status filter; use 'any' to skip filtering.")
                ]),
                "search": .object([
                    "type": .string("string"),
                    "description": .string("Free-text search across order content.")
                ]),
                "customer": .object([
                    "type": .string("integer"),
                    "description": .string("Customer ID; resolve via customers_list first.")
                ]),
                "include": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Specific order IDs to include.")
                ]),
                "after": .object([
                    "type": .string("string"),
                    "description": .string("YYYY-MM-DD lower bound on date_created.")
                ]),
                "before": .object([
                    "type": .string("string"),
                    "description": .string("YYYY-MM-DD upper bound on date_created.")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array([.string("date"), .string("id"), .string("modified"),
                                    .string("title")]),
                    "description": .string("Sort key; default 'date'.")
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
        let status: String?
        let search: String?
        let customer: Int?
        let include: [Int]?
        let after: String?
        let before: String?
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case status, search, customer, include, after, before, orderby, order, page
            case perPage = "per_page"
        }
    }

    private static func query(from args: Args) -> RESTToolDispatch.DecodedArguments<[String: String]> {
        var query: [String: String] = [
            "orderby": args.orderby ?? "date",
            "order": args.order ?? "desc",
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if let status = args.status, status != "any" { query["status"] = status }
        if let search = args.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query["search"] = search
        }
        if let customer = args.customer { query["customer"] = String(customer) }
        if let include = args.include, !include.isEmpty {
            query["include"] = include.map(String.init).joined(separator: ",")
        }
        // The model passes bare YYYY-MM-DD per the prompt's `# Today` anchors; the
        // orders endpoint rejects those, so pad to inclusive ISO-8601 day boundaries.
        if let after = args.after {
            guard let lower = RESTDateBounds.lowerBound(after) else {
                return .failure(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "after must be YYYY-MM-DD"))
            }
            query["after"] = lower
        }
        if let before = args.before {
            guard let upper = RESTDateBounds.upperBound(before) else {
                return .failure(.init(toolName: name,
                                      kind: .invalidToolCall,
                                      reason: "before must be YYYY-MM-DD"))
            }
            query["before"] = upper
        }
        if let page = args.page, page > 1 { query["page"] = String(page) }
        return .success(query)
    }

    private static let allowedArguments: Set<String> = [
        "status", "search", "customer", "include", "after", "before",
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
        let resolvedQuery: [String: String]
        switch query(from: args) {
        case .success(let value): resolvedQuery = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: resolvedQuery,
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
        let summary = OrdersListSummary.make(from: rows)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

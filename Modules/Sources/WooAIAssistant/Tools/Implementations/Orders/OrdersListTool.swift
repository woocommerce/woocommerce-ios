import Foundation

public enum OrdersListTool {

    public static let name = "orders_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    static let definition = AITool(
        name: name,
        description: """
        List orders, optionally filtered by status, date range, or customer. \
        Use to find specific orders, list pending fulfilment, or pull the most \
        recent N. For aggregate sales numbers prefer analytics_orders / \
        analytics_revenue. Pass extra_fields when the merchant asks about a \
        non-default row field (e.g. payment_method_title) to avoid fanning out \
        to orders_get.
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
                    "description": .string("ISO-8601 lower bound on date_modified.")
                ]),
                "before": .object([
                    "type": .string("string"),
                    "description": .string("ISO-8601 upper bound on date_modified.")
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
                ]),
                "extra_fields": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string"),
                        "enum": .array([
                            .string("billing"),
                            .string("shipping"),
                            .string("payment_method_title"),
                            .string("customer_id"),
                            .string("customer_note"),
                            .string("date_paid_gmt"),
                            .string("date_created_gmt"),
                            .string("shipping_total")
                        ])
                    ]),
                    "description": .string(
                        "Non-default fields to include on each row in ONE call. " +
                        "Pass when the merchant asks about a field outside the default id/number/status/total/currency."
                    )
                ])
            ])
        ])
    )

    struct Args: Decodable {
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
        let extraFields: [String]?

        enum CodingKeys: String, CodingKey {
            case status, search, customer, include, after, before, orderby, order, page
            case perPage = "per_page"
            case extraFields = "extra_fields"
        }
    }

    static func query(from args: Args) -> [String: String] {
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
        if let after = args.after { query["after"] = after }
        if let before = args.before { query["before"] = before }
        if let page = args.page, page > 1 { query["page"] = String(page) }
        return query
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let decoded = RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name)
        guard case .ok(let args) = decoded else {
            if case .invalid(let failed) = decoded { return .failed(failed) }
            return .failed(.init(toolName: name, toolCallID: "", kind: .invalidToolCall, reason: ""))
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: query(from: args),
                                            body: nil,
                                            headers: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return .failed(.init(toolName: name,
                                 toolCallID: "",
                                 kind: .toolFailed,
                                 reason: "expected JSON array"))
        }
        let summary = OrdersListSummary.make(from: rows)
        return .success(.init(toolName: name,
                              toolCallID: "",
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

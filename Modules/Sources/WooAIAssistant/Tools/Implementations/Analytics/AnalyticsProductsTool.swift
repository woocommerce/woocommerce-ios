import Foundation

public enum AnalyticsProductsTool {

    public static let name = "analytics_products"

    static let allowedOrderBy: Set<String> = ["items_sold", "net_revenue"]

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Top-selling products within a date range. Returns each product's product_id, items_sold, \
        net_revenue, orders_count, plus name, sku, price, and stock_status, sorted highest first. \
        Use this for "best sellers this week", "top products in April", "what sold the most last \
        month", or any best/top-product question scoped to a time window. For all-time best sellers \
        with no date range, use products_list with orderby=popularity instead. For revenue or order \
        totals (not a per-product breakdown), use analytics_orders. Each row carries a `target` \
        object {kind:"product", id} you can pass straight to show_cards (family `product`) to render \
        the products, or to products_update.updates[].target. After calling, pass the returned \
        product_ids to show_cards rather than describing each row in prose.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "after": .object([
                    "type": .string("string"),
                    "description": .string("Inclusive start date YYYY-MM-DD.")
                ]),
                "before": .object([
                    "type": .string("string"),
                    "description": .string("Inclusive end date YYYY-MM-DD.")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array(allowedOrderBy.sorted().map { .string($0) }),
                    "description": .string("Ranking metric; default 'items_sold'. Use 'net_revenue' "
                        + "for top products by revenue.")
                ]),
                "per_page": .object([
                    "type": .string("integer"),
                    "description": .string("Max products; clamped 1-50, default 20.")
                ])
            ]),
            "required": .array([.string("after"), .string("before")])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let after: String
        let before: String
        let orderby: String?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case after, before, orderby
            case perPage = "per_page"
        }
    }

    private static let allowedArguments: Set<String> = ["after", "before", "orderby", "per_page"]

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
        let orderby = args.orderby ?? "items_sold"
        if !allowedOrderBy.contains(orderby) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "orderby must be items_sold or net_revenue"))
        }
        guard let bounds = RESTDateBounds.bounds(start: args.after, end: args.before) else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "after and before must be YYYY-MM-DD"))
        }
        let response = await client.request(method: "GET",
                                            path: "wc-analytics/reports/products",
                                            query: [
                                                "after": bounds.after,
                                                "before": bounds.before,
                                                "orderby": orderby,
                                                "order": "desc",
                                                "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage)),
                                                "extended_info": "true"
                                            ],
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
        let summary = AnalyticsProductsSummary.make(from: rows,
                                                    range: (args.after, args.before),
                                                    orderby: orderby)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

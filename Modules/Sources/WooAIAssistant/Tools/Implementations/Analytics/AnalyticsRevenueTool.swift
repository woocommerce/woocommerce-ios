import Foundation

public enum AnalyticsRevenueTool {

    public static let name = "analytics_revenue"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Revenue analytics for a date range. Returns totals (gross sales, \
        refunds, taxes, shipping, net revenue) and per-interval subtotals \
        for revenue charts. Prefer this over orders_list for any aggregate \
        revenue question. For breakdown requests (by week, by day), set the \
        `interval` parameter directly to the implied dimension rather than \
        asking the merchant which window or grain they meant. When a request \
        combines a grouping grain with a date window, interval follows the \
        grouping grain.
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
                "interval": .object([
                    "type": .string("string"),
                    "enum": .array([.string("hour"), .string("day"),
                                    .string("week"), .string("month"), .string("year")]),
                    "description": .string("Bucketing interval; default 'day'.")
                ]),
                "currency": .object([
                    "type": .string("string"),
                    "description": .string("Optional ISO currency override.")
                ])
            ]),
            "required": .array([.string("after"), .string("before")])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let after: String
        let before: String
        let interval: String?
        let currency: String?
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        guard let bounds = AnalyticsDateBounds.bounds(start: args.after, end: args.before) else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "after and before must be YYYY-MM-DD"))
        }
        var query: [String: String] = [
            "after": bounds.after,
            "before": bounds.before,
            "interval": args.interval ?? "day",
            "_fields": "totals,intervals"
        ]
        if let currency = args.currency?.trimmingCharacters(in: .whitespacesAndNewlines), !currency.isEmpty {
            query["currency"] = currency
        }

        let response = await client.request(method: "GET",
                                            path: "wc-analytics/reports/revenue/stats",
                                            query: query,
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "expected JSON object"))
        }
        let summary = AnalyticsStatsSummary.make(from: payload, range: (args.after, args.before))
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}

import Foundation

public enum AnalyticsOrdersTool {

    public static let name = "analytics_orders"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Order analytics for a date range. Returns totals (order count, items \
        sold, gross/net sales, average order value) and per-interval \
        subtotals. Prefer this over orders_list for any aggregate question. \
        For breakdown requests (by week, by day), set the `interval` \
        parameter directly to the implied dimension rather than asking the \
        merchant which window or grain they meant. When a request combines a \
        grouping grain with a date window, interval follows the grouping grain. \
        For "this period vs last", "vs last week", "compare to last month", \
        and similar comparison phrasing, set `compare_to=previous_period` on \
        the SAME call - the response then includes both `totals` for the \
        requested window AND `previous_period_totals` for the prior window. \
        Use those two blocks directly. Do NOT issue a second analytics_orders \
        call for the prior window; the data is already in the first response. \
        Order stats are card-backed: after any successful call for an aggregate \
        order stats question, do not stop with prose; call show_cards with \
        family analytics_stats and an id built from the same after/before/interval \
        values and currency:none.
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
                "compare_to": .object([
                    "type": .string("string"),
                    "enum": .array([.string("previous_period")]),
                    "description": .string("Set to 'previous_period' for any comparison phrasing (vs last week, " +
                        "compared to last month, etc.). The response then carries both windows; do NOT issue a " +
                        "second analytics call for the prior window.")
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
        let compareTo: String?

        enum CodingKeys: String, CodingKey {
            case after, before, interval
            case compareTo = "compare_to"
        }
    }

    static let allowedArguments: Set<String> = ["after", "before", "interval", "compare_to"]

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
        if let compareTo = args.compareTo, compareTo != "previous_period" {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "compare_to must be previous_period"))
        }
        guard let bounds = AnalyticsDateBounds.bounds(start: args.after, end: args.before) else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "after and before must be YYYY-MM-DD"))
        }
        let interval = args.interval ?? "day"
        let primary = await fetchPayload(client: client,
                                         after: bounds.after,
                                         before: bounds.before,
                                         interval: interval)
        guard case .success(let payload) = primary else {
            if case .failure(let failed) = primary { return .failed(failed) }
            return .failed(.init(toolName: name, kind: .toolFailed, reason: "unexpected analytics outcome"))
        }

        var comparison = AnalyticsStatsSummary.ComparisonInputs(interval: interval)
        if args.compareTo == "previous_period" {
            comparison = await comparisonInputs(args: args,
                                                interval: interval,
                                                client: client)
        }

        let summary = AnalyticsStatsSummary.make(from: payload,
                                                 range: (args.after, args.before),
                                                 comparison: comparison)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }

    private enum FetchOutcome {
        case success(AnyCodableJSON)
        case failure(ToolResult.Failed)
    }

    private static func fetchPayload(client: WCRESTClient,
                                     after: String,
                                     before: String,
                                     interval: String) async -> FetchOutcome {
        let response = await client.request(method: "GET",
                                            path: "wc-analytics/reports/orders/stats",
                                            query: [
                                                "after": after,
                                                "before": before,
                                                "interval": interval,
                                                "_fields": "totals,intervals"
                                            ],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failure(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data) else {
            return .failure(.init(toolName: name, kind: .toolFailed, reason: "expected JSON object"))
        }
        return .success(payload)
    }

    private static func comparisonInputs(args: Args,
                                         interval: String,
                                         client: WCRESTClient) async -> AnalyticsStatsSummary.ComparisonInputs {
        guard let previousRange = AnalyticsDateBounds.previousPeriodBounds(after: args.after,
                                                                           before: args.before),
              let previousBounds = AnalyticsDateBounds.bounds(start: previousRange.after,
                                                              end: previousRange.before) else {
            return AnalyticsStatsSummary.ComparisonInputs(
                interval: interval,
                previousPeriodPartial: true,
                previousPeriodWarning: "Previous period totals could not be fetched."
            )
        }
        let outcome = await fetchPayload(client: client,
                                         after: previousBounds.after,
                                         before: previousBounds.before,
                                         interval: interval)
        switch outcome {
        case .success(let payload):
            let totals = RESTResponseParsing.objectField(payload, "totals")
            return AnalyticsStatsSummary.ComparisonInputs(interval: interval,
                                                          previousPeriodTotals: totals)
        case .failure:
            return AnalyticsStatsSummary.ComparisonInputs(
                interval: interval,
                previousPeriodPartial: true,
                previousPeriodWarning: "Previous period totals could not be fetched."
            )
        }
    }
}

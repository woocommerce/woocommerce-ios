import Foundation

public enum OrdersGetTool {

    public static let name = "orders_get"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Fetch a single order with full detail (line items, billing/shipping, \
        status, customer_id). Use when the merchant references a specific \
        order by ID. The customer_id can chain into customers_list for \
        follow-up questions about the buyer. Do not call this tool to \
        render a card after `orders_list` — `show_cards` re-fetches order \
        detail itself when given a reference. Use bounded fanout: only call \
        after a list/card when the merchant asks for fields the list summary \
        or card doesn't show, and limit to the specific entity referenced.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "id": .object([
                    "type": .string("integer"),
                    "description": .string("The order ID. Required.")
                ])
            ]),
            "required": .array([.string("id")])
        ]),
        safetyLevel: .safe
    )

    private struct Args: Decodable, Sendable {
        let id: Int
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders/\(args.id)",
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
        let pruned = RESTPayloadPruning.prune(entity)
        let summary = OrderSummary.make(from: pruned)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name)))
    }
}

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
        order by ID, including by position from a prior turn ("the first \
        one", "that order"). Required when the merchant asks about line \
        items / products / contents of an order - the rendered order card \
        does not surface them. The customer_id can chain into customers_list \
        for follow-up questions about the buyer. Don't redundantly call this \
        to re-render an existing card; only fetch when the merchant asks \
        for fields the card doesn't show.
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

    private static let allowedArguments: Set<String> = ["id"]

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

import Foundation

public enum OrdersUpdateTool {

    public static let name = "orders_update"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Update an order's allowlisted fields: status, customer_note, billing email. \
        Status changes such as completed/cancelled/refunded fire customer emails - the \
        merchant confirms before this dispatches. Do NOT use this to issue a refund - \
        moving an order to "refunded" only changes the status, it does not return funds.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "id": .object([
                    "type": .string("integer"),
                    "description": .string("The order ID. Required.")
                ]),
                "status": .object([
                    "type": .string("string"),
                    "enum": .array(allowedStatuses.sorted().map { .string($0) }),
                    "description": .string("New order status.")
                ]),
                "customer_note": .object([
                    "type": .string("string"),
                    "description": .string("Internal note shown to the customer in their account.")
                ]),
                "billing_email": .object([
                    "type": .string("string"),
                    "description": .string("Replacement billing email (mapped to billing.email).")
                ])
            ]),
            "required": .array([.string("id")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let id: Int
        let status: String?
        let customerNote: String?
        let billingEmail: String?

        enum CodingKeys: String, CodingKey {
            case id
            case status
            case customerNote = "customer_note"
            case billingEmail = "billing_email"
        }
    }

    private static let allowedStatuses = AllowedOrderUpdateStatuses.values

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let status = args.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        var body: [String: Any] = [:]
        if let status = args.status { body["status"] = status }
        if let note = args.customerNote { body["customer_note"] = note }
        if let email = args.billingEmail { body["billing"] = ["email": email] }
        guard !body.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "at least one editable field must be provided"))
        }
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "could not serialize update body"))
        }
        return await RESTToolDispatch.dispatchEntityWrite(method: "PUT",
                                                          path: "wc/v3/orders/\(args.id)",
                                                          body: payload,
                                                          client: client,
                                                          toolName: name,
                                                          family: .order,
                                                          summarize: OrderSummary.make)
    }
}

import Foundation
import CocoaLumberjackSwift

public enum OrdersUpdateTool {

    public static let name = "orders_update"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Update an order's allowlisted fields: status, customer_note, billing email. \
        Status changes such as completed/cancelled fire customer emails - the merchant \
        confirms before this dispatches. Refunds are NOT supported - the assistant \
        cannot set status to "refunded"; the merchant taps an order to issue a refund. \
        Only call when the merchant has explicitly requested a change. Do NOT call to \
        trigger side effects (e.g. flipping a status to send a customer email) or to \
        answer information questions. After a successful update, call `show_cards` \
        with family `order` and the updated id so the merchant sees the new state.
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
                    "maxLength": .int(Int64(OrderWriteArgumentValidation.customerNoteMaxLength)),
                    "description": .string("Internal note shown to the customer in their account.")
                ]),
                "billing_email": .object([
                    "type": .string("string"),
                    "maxLength": .int(Int64(OrderWriteArgumentValidation.billingEmailMaxLength)),
                    "format": .string("email"),
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
    private static let allowedArguments: Set<String> = ["id", "status", "customer_note", "billing_email"]

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
        if args.status == OrderUpdateRefundGuard.blockedStatus {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: OrderUpdateRefundGuard.message))
        }
        if let status = args.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        if let reason = OrderWriteArgumentValidation.validate(customerNote: args.customerNote,
                                                              billingEmail: args.billingEmail) {
            return .failed(.init(toolName: name, kind: .invalidToolCall, reason: reason))
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
        let payload: Data
        do {
            payload = try JSONSerialization.data(withJSONObject: body)
        } catch {
            DDLogError("[OrdersUpdateTool] Failed to encode update body: \(error)")
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

import Foundation
import Storage
import Yosemite

public enum OrdersUpdateTool {
    public static let name = "orders_update"

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        OrdersUpdateToolImplementation(dataSource: AssistantOrdersDataSource(siteID: siteID,
                                                                             storageManager: storageManager,
                                                                             dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantOrdersDataSourceProtocol) -> RESTTool {
        OrdersUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct OrdersUpdateToolImplementation: Sendable {
    private static let name = OrdersUpdateTool.name

    private let dataSource: any AssistantOrdersDataSourceProtocol

    init(dataSource: any AssistantOrdersDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func makeRESTTool() -> RESTTool {
        RESTTool(definition: Self.definition) { arguments, _ in
            await execute(arguments: arguments)
        }
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
        answer information questions.
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

        var patch: OrderUpdatePatch {
            OrderUpdatePatch(status: status, customerNote: customerNote, billingEmail: billingEmail)
        }
    }

    private static let allowedStatuses = AllowedOrderUpdateStatuses.values

    private func execute(arguments: String) async -> ToolResult {
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: Self.name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let failure = validate(args: args) {
            return .failed(failure)
        }

        let builder = WriteToolResultBuilder(toolName: Self.name)
        switch await dataSource.updateOrder(id: Int64(args.id), patch: args.patch) {
        case .success(let order):
            return builder.cardSuccess(family: .order,
                                       id: order.orderID,
                                       payload: CardEntityPayloadFactory.payload(from: order))
        case .failure(let error):
            return builder.failure(error)
        }
    }

    private func validate(args: Args) -> ToolResult.Failed? {
        if args.status == OrderUpdateRefundGuard.blockedStatus {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: OrderUpdateRefundGuard.message)
        }
        if let status = args.status, !Self.allowedStatuses.contains(status) {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses))
        }
        guard args.patch.hasAnyField else {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: "at least one editable field must be provided")
        }
        return nil
    }
}

import Foundation
import Storage
import Yosemite

public enum OrdersBulkUpdateTool {
    public static let name = "orders_bulk_update"
    public static let maxBatchSize = 100

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) -> RESTTool {
        OrdersBulkUpdateToolImplementation(dataSource: AssistantOrdersDataSource(siteID: siteID,
                                                                                 storageManager: storageManager,
                                                                                 dispatchAction: dispatchAction)).makeRESTTool()
    }

    static func make(dataSource: any AssistantOrdersDataSourceProtocol) -> RESTTool {
        OrdersBulkUpdateToolImplementation(dataSource: dataSource).makeRESTTool()
    }
}

private struct OrdersBulkUpdateToolImplementation: Sendable {
    private static let name = OrdersBulkUpdateTool.name
    private static let maxBatchSize = OrdersBulkUpdateTool.maxBatchSize

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
        Apply the same allowlisted update to many orders at once (max 100). \
        The same patch (status, customer_note, billing email) is applied to \
        every order id in the list. Per-order differences require separate \
        orders_update calls. Refunds are NOT supported - status cannot be \
        set to "refunded"; the merchant taps each order to issue a refund. \
        Only call when the merchant has explicitly requested a bulk change \
        with a concrete list of ids.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "ids": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Order IDs to update. Required. Max \(maxBatchSize) per call.")
                ]),
                "patch": .object([
                    "type": .string("object"),
                    "additionalProperties": .bool(false),
                    "properties": .object([
                        "status": .object([
                            "type": .string("string"),
                            "enum": .array(allowedStatuses.sorted().map { .string($0) })
                        ]),
                        "customer_note": .object(["type": .string("string")]),
                        "billing_email": .object(["type": .string("string")])
                    ]),
                    "description": .string("Patch applied to every id. At least one field required.")
                ])
            ]),
            "required": .array([.string("ids"), .string("patch")])
        ]),
        safetyLevel: .unsafe
    )

    private struct Args: Decodable, Sendable {
        let ids: [Int]
        let patch: Patch
    }

    private struct Patch: Decodable, Sendable {
        let status: String?
        let customerNote: String?
        let billingEmail: String?

        enum CodingKeys: String, CodingKey {
            case status
            case customerNote = "customer_note"
            case billingEmail = "billing_email"
        }

        var orderPatch: OrderUpdatePatch {
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
        switch await dataSource.bulkUpdateOrders(ids: args.ids.map(Int64.init), patch: args.patch.orderPatch) {
        case .success(let result):
            return builder.batchSuccess(result)
        case .failure(let error):
            return builder.failure(error)
        }
    }

    private func validate(args: Args) -> ToolResult.Failed? {
        guard !args.ids.isEmpty else {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: "ids must not be empty")
        }
        guard args.ids.count <= Self.maxBatchSize else {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: "ids has \(args.ids.count) entries; max is \(Self.maxBatchSize)")
        }
        if args.patch.status == OrderUpdateRefundGuard.blockedStatus {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: OrderUpdateRefundGuard.message)
        }
        if let status = args.patch.status, !Self.allowedStatuses.contains(status) {
            return .init(toolName: Self.name,
                         kind: .invalidToolCall,
                         reason: RESTToolDispatch.allowedValuesMessage(field: "status", values: Self.allowedStatuses))
        }
        guard args.patch.orderPatch.hasAnyField else {
            return .init(toolName: Self.name, kind: .invalidToolCall, reason: "patch must set at least one field")
        }
        return nil
    }
}

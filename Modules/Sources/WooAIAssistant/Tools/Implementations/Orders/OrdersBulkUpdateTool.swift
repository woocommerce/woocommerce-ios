import Foundation

public enum OrdersBulkUpdateTool {

    public static let name = "orders_bulk_update"

    /// WC silently truncates batches above this server-side default; enforce locally to fail fast.
    public static let maxBatchSize = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Apply the same allowlisted update to many orders at once (max 100). \
        The same patch (status, customer_note, billing email) is applied to \
        every order id in the list. Per-order differences require separate \
        orders_update calls. Only call when the merchant has explicitly \
        requested a bulk change with a concrete list of ids.
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

        var hasAnyField: Bool {
            status != nil || customerNote != nil || billingEmail != nil
        }
    }

    private static let allowedStatuses = AllowedOrderUpdateStatuses.values

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        guard !args.ids.isEmpty else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "ids must not be empty"))
        }
        guard args.ids.count <= maxBatchSize else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "ids has \(args.ids.count) entries; max is \(maxBatchSize)"))
        }
        if let status = args.patch.status, !allowedStatuses.contains(status) {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "status must be one of: \(allowedStatuses.sorted().joined(separator: ", "))"))
        }
        guard args.patch.hasAnyField else {
            return .failed(.init(toolName: name,
                                 kind: .invalidToolCall,
                                 reason: "patch must set at least one field"))
        }

        var template: [String: Any] = [:]
        if let status = args.patch.status { template["status"] = status }
        if let note = args.patch.customerNote { template["customer_note"] = note }
        if let email = args.patch.billingEmail { template["billing"] = ["email": email] }

        let updates: [[String: Any]] = args.ids.map { id in
            var entry = template
            entry["id"] = id
            return entry
        }
        guard let payload = try? JSONSerialization.data(withJSONObject: ["update": updates]) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "could not serialize batch body"))
        }
        return await RESTToolDispatch.dispatchBatchWrite(method: "POST",
                                                         path: "wc/v3/orders/batch",
                                                         body: payload,
                                                         client: client,
                                                         toolName: name,
                                                         family: .order)
    }
}

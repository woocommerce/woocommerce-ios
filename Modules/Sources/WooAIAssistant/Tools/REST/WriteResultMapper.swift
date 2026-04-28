import Foundation

/// Maps a write response into a `ToolResult`, surfacing the `outcome_unknown`
/// state on transport drops and timeouts. A write that vanished into a black
/// hole could still have applied server-side, so retrying it would risk a
/// duplicate update; the orchestrator renders this kind as a "verify on the
/// store" prompt rather than an automatic retry.
enum WriteResultMapper {
    /// Statuses the adaptor synthesises after the body upload finished without
    /// a confirmed response. On a write these collapse into `.outcomeUnknown`.
    static let outcomeUnknownStatusCodes: Set<Int> = [
        HTTPStatusClassification.transportFailure,
        408
    ]

    /// The idempotency key is echoed into the failure `code` so the orchestrator
    /// can show it to the merchant for manual reconciliation.
    static func mapEntity(_ response: WCRESTResponse,
                          toolName: String,
                          idempotencyKey: String,
                          family: CardFamilyID,
                          summarize: (AnyCodableJSON) -> AnyCodableJSON) -> ToolResult {
        if let unknown = unknownOutcomeFailure(response: response,
                                               toolName: toolName,
                                               idempotencyKey: idempotencyKey) {
            return .failed(unknown)
        }
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: toolName))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
            return .failed(.init(toolName: toolName,
                                 toolCallID: "",
                                 kind: .toolFailed,
                                 reason: "expected JSON object"))
        }
        let pruned = RESTPayloadPruning.prune(entity)
        let summary = summarize(pruned)
        let id = RESTResponseParsing.intField(pruned, "id") ?? 0
        let card = RenderedCardPayload(family: family, id: id, element: pruned)
        return .success(.init(toolName: toolName,
                              toolCallID: "",
                              structured: LLMPayloadCap.capped(summary, toolName: toolName),
                              uiStructured: UIStructured(cards: [card])))
    }

    /// WC's batch endpoint returns 200 with an `update` array even when
    /// individual entries failed, so the summary counts updates and surfaces
    /// the per-entry errors instead of letting partial failures look successful.
    static func mapBatch(_ response: WCRESTResponse,
                         toolName: String,
                         idempotencyKey: String,
                         family: CardFamilyID) -> ToolResult {
        if let unknown = unknownOutcomeFailure(response: response,
                                               toolName: toolName,
                                               idempotencyKey: idempotencyKey) {
            return .failed(unknown)
        }
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: toolName))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data),
              let updates = RESTResponseParsing.objectField(entity, "update").flatMap(RESTResponseParsing.arrayItems) else {
            return .failed(.init(toolName: toolName,
                                 toolCallID: "",
                                 kind: .toolFailed,
                                 reason: "expected {\"update\":[...]} batch payload"))
        }
        var updatedIDs: [Int64] = []
        var failedEntries: [AnyCodableJSON] = []
        for item in updates {
            if RESTResponseParsing.objectField(item, "error") != nil {
                failedEntries.append(item)
            } else if let identifier = RESTResponseParsing.intField(item, "id") {
                updatedIDs.append(identifier)
            }
        }
        var summary: [String: AnyCodableJSON] = [
            "tool": .string(toolName),
            "updated_count": .int(Int64(updatedIDs.count)),
            "failed_count": .int(Int64(failedEntries.count))
        ]
        if !updatedIDs.isEmpty {
            summary["updated_ids"] = .array(updatedIDs.map { .int($0) })
        }
        if !failedEntries.isEmpty {
            summary["failed"] = .array(failedEntries)
        }
        let cards = updatedIDs.map { id in
            RenderedCardPayload(family: family, id: id, element: .object(["id": .int(id)]))
        }
        return .success(.init(toolName: toolName,
                              toolCallID: "",
                              structured: LLMPayloadCap.capped(.object(summary), toolName: toolName),
                              uiStructured: cards.isEmpty ? nil : UIStructured(cards: cards)))
    }

    private static func unknownOutcomeFailure(response: WCRESTResponse,
                                              toolName: String,
                                              idempotencyKey: String) -> ToolResult.Failed? {
        guard outcomeUnknownStatusCodes.contains(response.statusCode) else { return nil }
        return .init(toolName: toolName,
                     toolCallID: "",
                     kind: .outcomeUnknown,
                     reason: "Write request did not get a confirmed response. The change may or may not have applied; verify on the store before retrying.",
                     code: idempotencyKey)
    }
}

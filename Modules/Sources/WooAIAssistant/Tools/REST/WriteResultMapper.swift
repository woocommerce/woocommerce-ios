import Foundation

/// Maps write responses, classifying transport drops and timeouts as `outcomeUnknown`.
/// The write may still have applied server-side, so retrying risks a duplicate update.
enum WriteResultMapper {
    static func mapEntity(_ response: WCRESTResponse,
                          toolName: String,
                          family: CardFamilyID,
                          summarize: (AnyCodableJSON) -> AnyCodableJSON) -> ToolResult {
        if let unknown = unknownOutcomeFailure(response: response, toolName: toolName) {
            return .failed(unknown)
        }
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: toolName))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
            return .failed(.init(toolName: toolName,
                                 kind: .toolFailed,
                                 reason: "expected JSON object"))
        }
        let pruned = RESTPayloadPruning.prune(entity)
        let summary = summarize(pruned)
        let uiStructured: UIStructured?
        if let id = RESTResponseParsing.intField(pruned, "id") {
            uiStructured = UIStructured(cards: [RenderedCardPayload(family: family, id: id, element: pruned)])
        } else {
            uiStructured = nil
        }
        return .success(.init(toolName: toolName,
                              structured: LLMPayloadCap.capped(summary, toolName: toolName),
                              uiStructured: uiStructured))
    }

    /// WC's batch endpoint returns 200 even when individual entries fail, so the summary
    /// counts and surfaces per-entry errors rather than trusting the envelope status.
    static func mapBatch(_ response: WCRESTResponse,
                         toolName: String,
                         family: CardFamilyID) -> ToolResult {
        if let unknown = unknownOutcomeFailure(response: response, toolName: toolName) {
            return .failed(unknown)
        }
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: toolName))
        }
        guard let entity = RESTResponseParsing.decodeJSON(response.data),
              let updates = RESTResponseParsing.objectField(entity, "update").flatMap(RESTResponseParsing.arrayItems) else {
            return .failed(.init(toolName: toolName,
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
                              structured: LLMPayloadCap.capped(.object(summary), toolName: toolName),
                              uiStructured: cards.isEmpty ? nil : UIStructured(cards: cards)))
    }

    private static func unknownOutcomeFailure(response: WCRESTResponse,
                                              toolName: String) -> ToolResult.Failed? {
        guard HTTPStatusClassification.isOutcomeUnknownStatus(response.statusCode) else { return nil }
        return .init(toolName: toolName,
                     kind: .outcomeUnknown,
                     reason: "Write request did not get a confirmed response. The change may or may not have applied; verify on the store before retrying.")
    }
}

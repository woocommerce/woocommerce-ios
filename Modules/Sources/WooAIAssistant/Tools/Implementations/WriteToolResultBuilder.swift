import Foundation

struct WriteToolResultBuilder {
    private let toolName: String

    init(toolName: String) {
        self.toolName = toolName
    }

    func cardSuccess<Payload: Encodable>(family: CardFamily,
                                         id: Int64,
                                         payload: Payload) -> ToolResult {
        guard let json = CardEntityPayloadFactory.json(from: payload) else {
            return .failed(.init(toolName: toolName,
                                 kind: .toolFailed,
                                 reason: "could not serialize updated entity"))
        }
        return .success(.init(toolName: toolName,
                              structured: LLMPayloadCap.capped(json, toolName: toolName),
                              uiStructured: UIStructured(cards: [
                                  RenderedCardPayload(family: family, id: String(id), element: json)
                              ])))
    }

    func batchSuccess(_ result: BulkWriteResult) -> ToolResult {
        let summary: [String: AnyCodableJSON] = [
            "tool": .string(toolName),
            "updated": .array(result.updatedIDs.map { .int($0) }),
            "failed": .array(result.failedItems.map {
                .object([
                    "id": .int($0.id),
                    "message": .string($0.message)
                ])
            })
        ]
        return .success(.init(toolName: toolName,
                              structured: LLMPayloadCap.capped(.object(summary), toolName: toolName),
                              uiStructured: nil))
    }

    func failure(_ error: Error) -> ToolResult {
        if WriteOutcomeClassifier.isOutcomeUnknown(error) {
            return ToolResult.failed(ToolResult.Failed(toolName: toolName,
                                                       kind: .outcomeUnknown,
                                                       reason: "Write request did not get a confirmed response. The change may or may not have applied; verify on the store before retrying."))
        }
        return ToolResult.failed(ToolResult.Failed(toolName: toolName,
                                                   kind: .toolFailed,
                                                   reason: error.localizedDescription))
    }
}

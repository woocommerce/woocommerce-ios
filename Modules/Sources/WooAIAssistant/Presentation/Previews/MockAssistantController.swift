#if DEBUG
import Foundation

@MainActor
enum MockAssistantController {

    static func make(messages: [ChatMessage] = [],
                     streaming: AssistantConversation.StreamingState = .idle) -> AssistantController {
        let conversation = AssistantConversation(seededMessages: messages)
        conversation.setStreaming(streaming)
        let context = AssistantContext(siteID: 0,
                                       siteURL: URL(string: "https://example.com")!,
                                       blogID: nil)
        return AssistantController(backend: InertBackend(),
                                   context: context,
                                   conversation: conversation)
    }

    static func userMessage(_ text: String) -> ChatMessage {
        ChatMessage(role: .user,
                    segments: [.text(id: UUID(), content: text)])
    }

    static func assistantText(_ text: String, streaming: Bool = false) -> ChatMessage {
        ChatMessage(role: .assistant,
                    segments: [.text(id: UUID(), content: text)],
                    isStreaming: streaming)
    }

    static func assistantWithToolPill(text: String,
                                      tool: String,
                                      status: ToolCallStatus,
                                      streaming: Bool) -> ChatMessage {
        var segments: [MessageSegment] = []
        segments.append(.toolCall(id: UUID(),
                                  toolCallID: UUID().uuidString,
                                  toolName: tool,
                                  argumentsPreview: nil,
                                  status: status))
        if !text.isEmpty {
            segments.append(.text(id: UUID(), content: text))
        }
        return ChatMessage(role: .assistant,
                           segments: segments,
                           isStreaming: streaming)
    }

    static func assistantWithCard(text: String,
                                  toolName: String,
                                  payload: AnyCodableJSON,
                                  streaming: Bool = false) -> ChatMessage {
        let toolCallID = UUID().uuidString
        let syntheticID = "\(toolCallID):card:0"
        let syntheticTool = "\(toolName).order"
        let segments: [MessageSegment] = [
            .text(id: UUID(), content: text),
            .toolResult(id: UUID(),
                        toolCallID: toolCallID,
                        toolName: toolName,
                        payload: payload),
            .toolResult(id: UUID(),
                        toolCallID: syntheticID,
                        toolName: syntheticTool,
                        payload: payload),
            .cardRender(id: UUID(),
                        toolCallID: syntheticID,
                        toolName: syntheticTool,
                        payload: payload)
        ]
        return ChatMessage(role: .assistant,
                           segments: segments,
                           isStreaming: streaming)
    }

    static func assistantConfirmation(text: String,
                                      proposalID: UUID,
                                      tool: String,
                                      preview: String,
                                      status: ConfirmationStatus) -> ChatMessage {
        let segments: [MessageSegment] = [
            .text(id: UUID(), content: text),
            .confirmation(id: UUID(),
                          proposalID: proposalID,
                          toolName: tool,
                          preview: preview,
                          status: status)
        ]
        return ChatMessage(role: .assistant, segments: segments)
    }

    static func sampleOrderListPayload() -> AnyCodableJSON {
        .array([
            .object([
                "id": .int(3479),
                "total": .string("$84.20"),
                "status": .string("processing")
            ]),
            .object([
                "id": .int(3478),
                "total": .string("$214.00"),
                "status": .string("completed")
            ])
        ])
    }
}

private struct InertBackend: AssistantBackendConfirming {
    func send(turn: AssistantTurn,
              context: AssistantContext,
              session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func confirmProposal(_ id: UUID) async {}

    func cancelProposal(_ id: UUID) async {}
}

#endif

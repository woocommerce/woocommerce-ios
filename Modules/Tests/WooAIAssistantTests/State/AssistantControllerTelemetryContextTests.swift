import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantControllerTelemetryContextTests {

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    @Test
    func test_send_when_called_then_attaches_telemetry_context_to_turn() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))]])
        let generator = StubAssistantIdGenerator(["conversation-1", "request-1"])
        let conversation = AssistantConversation(idGenerator: generator)
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             conversation: conversation,
                                             idGenerator: generator)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let recordedTurn = try #require(backend.recordedTurns.first)
        let context = try #require(recordedTurn.telemetryContext)
        #expect(context.conversationID == "conversation-1")
        #expect(context.requestID == "request-1")
        #expect(!context.messageID.isEmpty)
    }

    @Test
    func test_send_when_called_twice_then_each_turn_gets_fresh_requestID() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))],
                        [.event(.completed(routeConfidence: nil))]])
        let generator = StubAssistantIdGenerator(["conversation-1", "request-1", "request-2"])
        let conversation = AssistantConversation(idGenerator: generator)
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             conversation: conversation,
                                             idGenerator: generator)

        // When
        controller.send("first")
        await controller.activeTask?.value
        controller.send("second")
        await controller.activeTask?.value

        // Then
        let first = try #require(backend.recordedTurns[safe: 0]?.telemetryContext)
        let second = try #require(backend.recordedTurns[safe: 1]?.telemetryContext)
        #expect(first.conversationID == second.conversationID)
        #expect(first.requestID != second.requestID)
        #expect(first.messageID != second.messageID)
    }

    @Test
    func test_send_when_messageID_minted_then_telemetry_context_uses_it() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))]])
        let conversation = AssistantConversation()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             conversation: conversation)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let assistantMessage = try #require(conversation.messages.first { $0.role == .assistant })
        let recordedTurn = try #require(backend.recordedTurns.first)
        let context = try #require(recordedTurn.telemetryContext)
        #expect(context.messageID == assistantMessage.id.uuidString)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

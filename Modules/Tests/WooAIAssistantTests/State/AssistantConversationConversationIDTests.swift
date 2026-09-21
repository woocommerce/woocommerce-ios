import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantConversationConversationIDTests {

    @Test
    func test_init_when_called_then_mints_conversation_id_via_generator() {
        // Given
        let generator = StubAssistantIdGenerator(["fixed-conversation-id"])

        // When
        let conversation = AssistantConversation(idGenerator: generator)

        // Then
        #expect(conversation.conversationID == "fixed-conversation-id")
        #expect(generator.requests == 1)
    }

    @Test
    func test_conversationID_when_messages_are_added_then_remains_stable() {
        // Given
        let generator = StubAssistantIdGenerator(["stable-id"])
        let conversation = AssistantConversation(idGenerator: generator)
        let original = conversation.conversationID

        // When
        _ = conversation.appendUserMessage("hello")
        _ = conversation.beginAssistantMessage()

        // Then
        #expect(conversation.conversationID == original)
    }

    @Test
    func test_reset_when_called_then_regenerates_conversation_id() {
        // Given
        let generator = StubAssistantIdGenerator(["first-id", "second-id"])
        let conversation = AssistantConversation(idGenerator: generator)
        #expect(conversation.conversationID == "first-id")

        // When
        conversation.reset()

        // Then
        #expect(conversation.conversationID == "second-id")
    }
}

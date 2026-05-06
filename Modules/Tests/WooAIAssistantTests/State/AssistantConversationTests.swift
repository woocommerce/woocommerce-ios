import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct AssistantConversationTests {

    @Test
    func test_apply_when_textChunk_then_appends_to_text_segment() async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()

        // When
        conversation.apply(.textChunk("Hello "), to: messageID)
        conversation.apply(.textChunk("world"), to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        #expect(segments.count == 1)
        if case .text(_, let content) = segments[0] {
            #expect(content == "Hello world")
        } else {
            Issue.record("expected text segment")
        }
    }

    @Test
    func test_apply_when_toolCall_lifecycle_then_status_advances_in_place() async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()

        // When
        conversation.apply(.toolCallStarted(id: "c1",
                                            name: "orders_list",
                                            argumentsJSON: "{}"),
                           to: messageID)
        conversation.apply(.toolCallCompleted(id: "c1",
                                              name: "orders_list",
                                              resultJSON: "{\"count\":1}"),
                           to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        #expect(segments.count == 1)
        if case .toolCall(_, let toolCallID, _, _, let status) = segments[0] {
            #expect(toolCallID == "c1")
            if case .completed(let summary) = status {
                #expect(summary == "{\"count\":1}")
            } else {
                Issue.record("expected completed status")
            }
        }
    }

    @Test
    func test_apply_when_cardRender_referencing_known_toolCallID_then_appends_cardRender_segment()
    async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        conversation.apply(.toolCallStarted(id: "c1", name: "orders_get", argumentsJSON: nil),
                           to: messageID)
        conversation.apply(.toolResult(toolCallID: "c1",
                                       toolName: "orders_get",
                                       payload: .object(["id": .int(42)])),
                           to: messageID)

        // When
        conversation.apply(.cardRender(toolCallID: "c1"), to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        let cardRender = segments.first { segment in
            if case .cardRender = segment { return true }
            return false
        }
        let card = try #require(cardRender)
        if case .cardRender(_, let toolCallID, let toolName, let payload) = card {
            #expect(toolCallID == "c1")
            #expect(toolName == "orders_get")
            #expect(payload == .object(["id": .int(42)]))
        }
    }

    @Test
    func test_apply_when_cardRender_referencing_unknown_toolCallID_then_silently_drops()
    async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        conversation.apply(.textChunk("hi"), to: messageID)
        let countBefore = conversation.messages.last?.segments.count ?? 0

        // When
        conversation.apply(.cardRender(toolCallID: "missing"), to: messageID)

        // Then
        let countAfter = conversation.messages.last?.segments.count ?? 0
        #expect(countAfter == countBefore)
    }

    @Test
    func test_apply_when_toolCallStarted_for_show_cards_then_no_toolCall_segment_appended()
    async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()

        // When
        conversation.apply(.toolCallStarted(id: "c1",
                                            name: ShowCardsTool.name,
                                            argumentsJSON: nil),
                           to: messageID)

        // Then
        let segments = conversation.messages.last?.segments ?? []
        let toolCallSegments = segments.filter { segment in
            if case .toolCall = segment { return true }
            return false
        }
        #expect(toolCallSegments.isEmpty)
    }

    @Test
    func test_apply_when_failed_with_outcomeUnknown_then_appends_distinct_failure_segment()
    async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        let unknownError = AssistantError(kind: .outcomeUnknown,
                                          message: "Couldn't confirm completion.")

        // When
        conversation.apply(.failed(unknownError), to: messageID)

        // Then
        if case .outcomeUnknown(let message) = conversation.streamingState {
            #expect(message == "Couldn't confirm completion.")
        } else {
            Issue.record("expected outcomeUnknown streaming state, got \(conversation.streamingState)")
        }
    }

    @Test
    func test_apply_when_outcomeUnknown_then_textChunk_then_completed_then_state_remains_outcomeUnknown()
    async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        let unknownError = AssistantError(kind: .outcomeUnknown,
                                          message: "Couldn't confirm completion.")

        // When
        conversation.apply(.failed(unknownError), to: messageID)
        conversation.setStreaming(.streaming)
        conversation.apply(.textChunk("ok"), to: messageID)
        conversation.apply(.completed(routeConfidence: nil), to: messageID)
        conversation.setStreaming(.idle)

        // Then
        if case .outcomeUnknown(let message) = conversation.streamingState {
            #expect(message == "Couldn't confirm completion.")
        } else {
            Issue.record("expected outcomeUnknown streaming state, got \(conversation.streamingState)")
        }
        #expect(conversation.messages.last?.isStreaming == false)
        let textSegments = conversation.messages.last?.segments.compactMap { segment -> String? in
            if case .text(_, let content) = segment { return content }
            return nil
        } ?? []
        #expect(textSegments.contains("ok"))
    }

    @Test
    func test_apply_when_completed_then_trims_trailing_whitespace_from_text_segments() async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()

        // When
        conversation.apply(.textChunk("Hello world."), to: messageID)
        conversation.apply(.textChunk("\n\n\n"), to: messageID)
        conversation.apply(.completed(routeConfidence: nil), to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        guard case .text(_, let content) = segments[0] else {
            Issue.record("expected .text, got \(segments[0])")
            return
        }
        #expect(content == "Hello world.")
    }

    @Test
    func test_apply_mid_stream_does_not_trim_text() async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()

        // When
        conversation.apply(.textChunk("Hello\n"), to: messageID)
        conversation.apply(.textChunk("world."), to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        guard case .text(_, let content) = segments[0] else {
            Issue.record("expected .text, got \(segments[0])")
            return
        }
        #expect(content == "Hello\nworld.")
    }

    @Test
    func test_apply_when_confirmationRequired_then_pending_segment_is_appended() async throws {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        let proposal = ToolProposal(toolName: "orders_update",
                                    toolCallID: "c1",
                                    preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")))

        // When
        conversation.apply(.confirmationRequired(proposal: proposal), to: messageID)
        conversation.apply(.confirmationResolved(proposalID: proposal.id, approved: true),
                           to: messageID)

        // Then
        let segments = try #require(conversation.messages.last?.segments)
        let confirmation = segments.first { segment in
            if case .confirmation = segment { return true }
            return false
        }
        let segment = try #require(confirmation)
        if case .confirmation(_, _, _, _, let status) = segment {
            #expect(status == .confirmed)
        }
    }
}

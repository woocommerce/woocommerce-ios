import Foundation
import Testing
@testable import WooAIAssistant

struct AssistantEventTests {
    @Test
    func test_assistantEvent_failed_carries_error_kind() {
        // Given
        let error = AssistantError(kind: .outcomeUnknown,
                                   message: "Write may have completed but the response was lost.")

        // When
        let event: AssistantEvent = .failed(error)

        // Then
        guard case .failed(let captured) = event else {
            Issue.record("expected .failed, got \(event)")
            return
        }
        #expect(captured.kind == .outcomeUnknown)
        #expect(captured.message == "Write may have completed but the response was lost.")
    }

    @Test
    func test_assistantError_when_constructed_with_unknown_kind_then_code_is_nil() {
        // Given / When
        let error = AssistantError(kind: .unknown, message: "Generic failure")

        // Then
        #expect(error.kind == .unknown)
        #expect(error.code == nil)
    }

    @Test
    func test_assistantEvent_when_cardRender_then_carries_extras() {
        // Given
        let extras = ["3551": ["last_note": "Customer asked for tracking"]]

        // When
        let event: AssistantEvent = .cardRender(toolCallID: "call_1", extras: extras)

        // Then
        guard case .cardRender(let toolCallID, let captured) = event else {
            Issue.record("expected .cardRender, got \(event)")
            return
        }
        #expect(toolCallID == "call_1")
        #expect(captured == extras)
    }

    @Test
    func test_assistantEvent_when_toolResult_then_carries_payload_keyed_by_tool_call_id() {
        // Given
        let payload: AnyCodableJSON = .object(["count": .int(2)])

        // When
        let event: AssistantEvent = .toolResult(toolCallID: "call_1",
                                                toolName: "orders_list",
                                                payload: payload)

        // Then
        guard case .toolResult(let id, let name, let captured) = event else {
            Issue.record("expected .toolResult, got \(event)")
            return
        }
        #expect(id == "call_1")
        #expect(name == "orders_list")
        #expect(captured == payload)
    }

    @Test
    func test_toolProposal_when_constructed_then_exposes_fields() {
        // Given
        let proposalID = UUID()

        // When
        let proposal = ToolProposal(id: proposalID,
                                    toolName: "orders_update",
                                    toolCallID: "call_1",
                                    preview: "Mark order #3551 completed")

        // Then
        #expect(proposal.id == proposalID)
        #expect(proposal.toolName == "orders_update")
        #expect(proposal.toolCallID == "call_1")
        #expect(proposal.preview == "Mark order #3551 completed")
    }
}

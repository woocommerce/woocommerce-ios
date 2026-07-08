import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SuppressibleAssistantTelemetryTrackerTests {

    private func makeContext(requestID: String) -> AssistantTelemetryContext {
        AssistantTelemetryContext(conversationID: "conv",
                                  requestID: requestID,
                                  messageID: "msg")
    }

    @Test
    func test_track_when_not_suppressed_then_forwards_to_underlying() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        let event = AssistantTelemetryEvent.toolCallCompleted(context: makeContext(requestID: "req-1"),
                                                              toolName: "orders_list",
                                                              status: .success,
                                                              errorKind: nil,
                                                              durationMs: 12)

        // When
        sut.track(event)

        // Then
        #expect(recording.events.count == 1)
        if case .toolCallCompleted(_, let name, let status, _, _) = recording.events[0] {
            #expect(name == "orders_list")
            #expect(status == .success)
        } else {
            Issue.record("expected toolCallCompleted, got \(recording.events[0])")
        }
    }

    @Test
    func test_track_when_request_id_suppressed_and_event_is_tool_call_completed_then_drops_event() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        sut.suppressToolEvents(for: "req-1")
        let event = AssistantTelemetryEvent.toolCallCompleted(context: makeContext(requestID: "req-1"),
                                                              toolName: "orders_list",
                                                              status: .success,
                                                              errorKind: nil,
                                                              durationMs: 12)

        // When
        sut.track(event)

        // Then
        #expect(recording.events.isEmpty)
    }

    @Test
    func test_track_when_request_id_suppressed_and_event_is_show_cards_processed_then_drops_event() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        sut.suppressToolEvents(for: "req-1")
        let event = AssistantTelemetryEvent.showCardsProcessed(context: makeContext(requestID: "req-1"),
                                                               requestedCount: 3,
                                                               renderedCount: 3,
                                                               missingCount: 0,
                                                               rejectedCount: 0)

        // When
        sut.track(event)

        // Then
        #expect(recording.events.isEmpty)
    }

    @Test
    func test_track_when_request_id_suppressed_and_event_is_turn_completed_then_still_forwards() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        sut.suppressToolEvents(for: "req-1")
        let event = AssistantTelemetryEvent.turnCompleted(context: makeContext(requestID: "req-1"),
                                                          outcome: .cancelledByUser,
                                                          durationMs: 100,
                                                          errorKind: nil,
                                                          isRetry: false,
                                                          completionStack: "stack",
                                                          promptVersion: "p1",
                                                          toolCatalogVersion: "t1")

        // When
        sut.track(event)

        // Then
        try #require(recording.events.count == 1)
        if case .turnCompleted(_, let outcome, _, _, _, _, _, _) = recording.events[0] {
            #expect(outcome == .cancelledByUser)
        } else {
            Issue.record("expected turnCompleted, got \(recording.events[0])")
        }
    }

    @Test
    func test_track_when_request_id_suppressed_and_event_is_conversation_started_then_still_forwards() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        sut.suppressToolEvents(for: "req-1")
        let event = AssistantTelemetryEvent.conversationStarted(context: makeContext(requestID: "req-1"))

        // When
        sut.track(event)

        // Then
        try #require(recording.events.count == 1)
        if case .conversationStarted = recording.events[0] {} else {
            Issue.record("expected conversationStarted, got \(recording.events[0])")
        }
    }

    @Test
    func test_suppress_when_called_multiple_times_then_only_suppresses_listed_request_ids() async throws {
        // Given
        let recording = RecordingAssistantTelemetryTracker()
        let sut = SuppressibleAssistantTelemetryTracker(underlying: recording)
        sut.suppressToolEvents(for: "req-1")
        sut.suppressToolEvents(for: "req-3")
        let suppressed1 = AssistantTelemetryEvent.toolCallCompleted(context: makeContext(requestID: "req-1"),
                                                                    toolName: "t1",
                                                                    status: .success,
                                                                    errorKind: nil,
                                                                    durationMs: 1)
        let live = AssistantTelemetryEvent.toolCallCompleted(context: makeContext(requestID: "req-2"),
                                                             toolName: "t2",
                                                             status: .success,
                                                             errorKind: nil,
                                                             durationMs: 2)
        let suppressed2 = AssistantTelemetryEvent.toolCallCompleted(context: makeContext(requestID: "req-3"),
                                                                    toolName: "t3",
                                                                    status: .success,
                                                                    errorKind: nil,
                                                                    durationMs: 3)

        // When
        sut.track(suppressed1)
        sut.track(live)
        sut.track(suppressed2)

        // Then
        try #require(recording.events.count == 1)
        if case .toolCallCompleted(let context, let name, _, _, _) = recording.events[0] {
            #expect(context.requestID == "req-2")
            #expect(name == "t2")
        } else {
            Issue.record("expected toolCallCompleted for req-2, got \(recording.events[0])")
        }
    }
}

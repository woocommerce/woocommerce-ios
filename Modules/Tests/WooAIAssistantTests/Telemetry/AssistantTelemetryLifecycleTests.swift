import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantTelemetryLifecycleTests {

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    @Test
    func test_send_when_first_message_then_emits_conversationStarted_before_turnStarted() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        try #require(tracker.events.count >= 2)
        if case .conversationStarted = tracker.events[0] {} else {
            Issue.record("expected conversationStarted first, got \(tracker.events[0])")
        }
        if case .turnStarted = tracker.events[1] {} else {
            Issue.record("expected turnStarted second, got \(tracker.events[1])")
        }
    }

    @Test
    func test_send_when_second_turn_then_does_not_re_emit_conversationStarted() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))],
                        [.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("first")
        await controller.activeTask?.value
        controller.send("second")
        await controller.activeTask?.value

        // Then
        let conversationStartedCount = tracker.events.filter {
            if case .conversationStarted = $0 { return true }
            return false
        }.count
        #expect(conversationStartedCount == 1)
    }

    @Test
    func test_send_when_retry_then_turnStarted_isRetry_is_true_and_new_requestID() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))],
                        [.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("first")
        await controller.activeTask?.value
        controller.retry("first")
        await controller.activeTask?.value

        // Then
        let turnStartedEvents = tracker.events.compactMap { event -> (String, Bool)? in
            if case .turnStarted(let context, let isRetry, _, _, _) = event {
                return (context.requestID, isRetry)
            }
            return nil
        }
        try #require(turnStartedEvents.count == 2)
        #expect(turnStartedEvents[0].1 == false)
        #expect(turnStartedEvents[1].1 == true)
        #expect(turnStartedEvents[0].0 != turnStartedEvents[1].0)
    }

    @Test
    func test_send_when_loop_completes_then_emits_turnCompleted_success_once() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let turnCompletedEvents = tracker.events.compactMap { event -> AssistantTelemetryOutcome? in
            if case .turnCompleted(_, let outcome, _, _, _, _, _, _) = event { return outcome }
            return nil
        }
        #expect(turnCompletedEvents == [.success])
    }

    @Test
    func test_run_when_orchestrator_reaches_max_iterations_then_turn_completed_outcome_is_max_iterations_without_error_kind() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.terminated(.maxIterations(iterations: 5)))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let turnCompleted = tracker.events.compactMap { event -> (AssistantTelemetryOutcome, AssistantTelemetryErrorKind?)? in
            if case .turnCompleted(_, let outcome, _, let errorKind, _, _, _, _) = event {
                return (outcome, errorKind)
            }
            return nil
        }
        try #require(turnCompleted.count == 1)
        #expect(turnCompleted[0].0 == .maxIterations)
        #expect(turnCompleted[0].1 == nil)
    }

    @Test
    func test_send_when_loop_fails_then_emits_turnCompleted_failed_with_error_kind() async throws {
        // Given
        let backend = MockAssistantBackend()
        let assistantError = AssistantError(kind: .network, message: "boom")
        backend.script([[.event(.failed(assistantError))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let turnCompleted = tracker.events.compactMap { event -> (AssistantTelemetryOutcome, AssistantTelemetryErrorKind?)? in
            if case .turnCompleted(_, let outcome, _, let errorKind, _, _, _, _) = event {
                return (outcome, errorKind)
            }
            return nil
        }
        try #require(turnCompleted.count == 1)
        #expect(turnCompleted[0].0 == .failed)
        #expect(turnCompleted[0].1 == .network)
    }

    @Test
    func test_cancel_when_called_during_turn_then_emits_turnCompleted_cancelledByUser() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.script([[]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)
        controller.send("hello")

        // When
        controller.cancel()
        backend.releaseStream(at: 0)
        await controller.activeTask?.value

        // Then
        let turnCompletedOutcomes = tracker.events.compactMap { event -> AssistantTelemetryOutcome? in
            if case .turnCompleted(_, let outcome, _, _, _, _, _, _) = event { return outcome }
            return nil
        }
        #expect(turnCompletedOutcomes == [.cancelledByUser])
    }

    @Test
    func test_cancel_when_late_tool_completion_arrives_then_suppressible_wrapper_drops_it() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.script([[.event(.toolCallStarted(id: "call-1",
                                                 name: "orders_list",
                                                 argumentsJSON: "{}"))]])
        let recording = RecordingAssistantTelemetryTracker()
        let wrapper = SuppressibleAssistantTelemetryTracker(underlying: recording)
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: wrapper)
        controller.send("hello")
        let cancelledRequestID = try #require(recording.events.compactMap { event -> String? in
            if case .turnStarted(let context, _, _, _, _) = event { return context.requestID }
            return nil
        }.first)

        // When
        controller.cancel()
        let lateContext = AssistantTelemetryContext(conversationID: "any",
                                                    requestID: cancelledRequestID,
                                                    messageID: "any")
        wrapper.track(.toolCallCompleted(context: lateContext,
                                         toolName: "orders_list",
                                         status: .success,
                                         errorKind: nil,
                                         durationMs: 17))
        backend.releaseStream(at: 0)
        await controller.activeTask?.value

        // Then
        let cancelledCount = recording.events.filter { event in
            if case .turnCompleted(let context, .cancelledByUser, _, _, _, _, _, _) = event {
                return context.requestID == cancelledRequestID
            }
            return false
        }.count
        let lateToolCount = recording.events.filter { event in
            if case .toolCallCompleted(let context, _, _, _, _) = event {
                return context.requestID == cancelledRequestID
            }
            return false
        }.count
        #expect(cancelledCount == 1)
        #expect(lateToolCount == 0)
    }

    @Test
    func test_turnCompleted_emitted_exactly_once_per_request_id_in_success_path() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([[.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.send("hello")
        await controller.activeTask?.value

        // Then
        let completionsByRequestID = Dictionary(grouping: tracker.events) { event -> String? in
            if case .turnCompleted(let context, _, _, _, _, _, _, _) = event { return context.requestID }
            return nil
        }
        for (key, group) in completionsByRequestID where key != nil {
            #expect(group.count == 1, "expected exactly one turn_completed per request_id, got \(group.count) for \(key ?? "nil")")
        }
    }
}

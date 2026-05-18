import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantControllerRetryTests {

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    @Test
    func test_retryLastFailedTurn_when_canSend_and_last_user_message_present_then_emits_is_retry_true() async throws {
        // Given
        let backend = MockAssistantBackend()
        let assistantError = AssistantError(kind: .network, message: "boom")
        backend.script([[.event(.failed(assistantError))],
                        [.event(.completed(routeConfidence: nil))]])
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)
        controller.send("show me yesterday's orders")
        await controller.activeTask?.value

        // When
        controller.retryLastFailedTurn()
        await controller.activeTask?.value

        // Then
        let turnStartedRetryFlags = tracker.events.compactMap { event -> Bool? in
            if case .turnStarted(_, let isRetry, _, _, _) = event { return isRetry }
            return nil
        }
        try #require(turnStartedRetryFlags.count == 2)
        #expect(turnStartedRetryFlags[0] == false)
        #expect(turnStartedRetryFlags[1] == true)
        #expect(backend.recordedTurns.count == 2)
        #expect(backend.recordedTurns[1].prompt == "show me yesterday's orders")
    }

    @Test
    func test_retryLastFailedTurn_when_no_user_message_then_no_op() async throws {
        // Given
        let backend = MockAssistantBackend()
        let tracker = RecordingAssistantTelemetryTracker()
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             telemetryTracker: tracker)

        // When
        controller.retryLastFailedTurn()
        await controller.activeTask?.value

        // Then
        #expect(backend.recordedTurns.isEmpty)
        #expect(tracker.events.isEmpty)
    }

    @Test
    func test_retryLastFailedTurn_when_turn_already_running_then_no_op() async throws {
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
        // canSend flips to false synchronously on send, so the retry guard fires without
        // depending on whether the backend Task has executed yet.
        #expect(!controller.canSend)
        controller.retryLastFailedTurn()

        // Then: send() emits turn_started synchronously, so exactly one turn_started
        // proves the second call hit the canSend guard.
        let turnStartedCount = tracker.events.filter {
            if case .turnStarted = $0 { return true }
            return false
        }.count
        #expect(turnStartedCount == 1)

        // Cleanup: drain the held stream so the test can complete.
        controller.cancel()
        backend.releaseStream(at: 0)
        await controller.activeTask?.value
    }
}

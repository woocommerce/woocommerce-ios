import Foundation

/// Wraps an underlying tracker so the controller can mute late-arriving tool telemetry once a
/// turn has been cancelled. Without this, tool tasks that finish after `cancel()` would emit
/// `tool_call_completed` and `show_cards_processed` events that inflate success metrics for
/// results the merchant never saw.
@MainActor
public final class SuppressibleAssistantTelemetryTracker: AssistantTelemetryTracker {

    private let underlying: AssistantTelemetryTracker
    private var suppressedRequestIDs: Set<String> = []

    public init(underlying: AssistantTelemetryTracker) {
        self.underlying = underlying
    }

    public func suppressToolEvents(for requestID: String) {
        suppressedRequestIDs.insert(requestID)
    }

    public nonisolated func track(_ event: AssistantTelemetryEvent) {
        MainActor.assumeIsolated {
            if shouldDrop(event) { return }
            underlying.track(event)
        }
    }

    private func shouldDrop(_ event: AssistantTelemetryEvent) -> Bool {
        switch event {
        case .toolCallCompleted, .showCardsProcessed:
            return suppressedRequestIDs.contains(event.requestID)
        case .conversationStarted, .turnStarted, .cardTapped, .turnCompleted:
            return false
        }
    }
}

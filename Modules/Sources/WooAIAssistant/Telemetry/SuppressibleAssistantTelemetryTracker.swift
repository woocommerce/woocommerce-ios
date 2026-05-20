import Foundation

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

    nonisolated public func track(_ event: AssistantTelemetryEvent) {
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

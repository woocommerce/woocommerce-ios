import Foundation
@testable import WooAIAssistant

@MainActor
final class RecordingAssistantTelemetryTracker: AssistantTelemetryTracker {

    private(set) var events: [AssistantTelemetryEvent] = []

    nonisolated func track(_ event: AssistantTelemetryEvent) {
        MainActor.assumeIsolated {
            events.append(event)
        }
    }
}

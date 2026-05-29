import SwiftUI

struct AssistantCardTelemetryDispatcher: Sendable {

    let tracker: AssistantTelemetryTracker
    let contextLookup: @MainActor @Sendable (ChatMessage.ID) -> AssistantTelemetryContext?

    @MainActor
    func recordTap(messageID: ChatMessage.ID?,
                   cardFamily: AssistantTelemetryCardFamily,
                   actionFamily: AssistantTelemetryActionFamily) {
        guard let messageID, let context = contextLookup(messageID) else { return }
        tracker.track(.cardTapped(context: context,
                                  cardFamily: cardFamily,
                                  actionFamily: actionFamily))
    }
}

private struct AssistantCardTelemetryKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AssistantCardTelemetryDispatcher = .init(
        tracker: NoopAssistantTelemetryTracker(),
        contextLookup: { _ in nil }
    )
}

extension EnvironmentValues {
    var assistantCardTelemetry: AssistantCardTelemetryDispatcher {
        get { self[AssistantCardTelemetryKey.self] }
        set { self[AssistantCardTelemetryKey.self] = newValue }
    }
}

import Foundation

public protocol AssistantTelemetryTracker: Sendable {
    func track(_ event: AssistantTelemetryEvent)
    @MainActor func suppressToolEvents(for requestID: String)
}

public extension AssistantTelemetryTracker {
    @MainActor func suppressToolEvents(for requestID: String) {}
}

public struct NoopAssistantTelemetryTracker: AssistantTelemetryTracker {
    public init() {}

    public func track(_ event: AssistantTelemetryEvent) {}
}

/// Analytics surface the assistant module uses. Generic by design - typed
/// event constructors land in a later PR alongside the Tracks catalog.
public protocol AssistantAnalyticsProviding: Sendable {
    func track(event: String, properties: [String: String])
}

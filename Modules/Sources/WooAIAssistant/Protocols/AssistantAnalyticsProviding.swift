/// Analytics surface the assistant module uses.
public protocol AssistantAnalyticsProviding: Sendable {
    func track(event: String, properties: [String: String])
}

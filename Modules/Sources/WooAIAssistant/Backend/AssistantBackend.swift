import Foundation

public protocol AssistantBackend: Sendable {
    func send(turn: AssistantTurn,
              context: AssistantContext,
              session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error>
    func reset() async
}

public extension AssistantBackend {
    func reset() async {}
}

public protocol AssistantBackendConfirming: AssistantBackend {
    func confirmProposal(_ id: UUID) async
    func cancelProposal(_ id: UUID) async
}

public struct AssistantTurn: Sendable {
    public let id: String
    public let prompt: String
    public let telemetryContext: AssistantTelemetryContext?

    public init(id: String = UUID().uuidString,
                prompt: String,
                telemetryContext: AssistantTelemetryContext? = nil) {
        self.id = id
        self.prompt = prompt
        self.telemetryContext = telemetryContext
    }
}

public struct AssistantContext: Sendable {
    public let siteID: Int64
    public let siteURL: URL
    public let blogID: Int64?

    public init(siteID: Int64, siteURL: URL, blogID: Int64?) {
        self.siteID = siteID
        self.siteURL = siteURL
        self.blogID = blogID
    }
}

public enum BackendYield: Sendable {
    case event(AssistantEvent)
    case sessionUpdate(AssistantSession)
}

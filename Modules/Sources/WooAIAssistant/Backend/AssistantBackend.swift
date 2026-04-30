import Foundation

/// The single abstraction the UI and `AssistantController` depend on so a different
/// implementation (Claude direct, A2A/SSE workflow agent, anything else) can swap in
/// without changing the chat surface.
public protocol AssistantBackend: Sendable {
    func send(turn: AssistantTurn,
              context: AssistantContext,
              session: AssistantSession?) -> AsyncThrowingStream<BackendYield, Error>
}

/// Backends that surface in-loop safety confirmations conform to this so the
/// controller's confirm/cancel taps can resume the agent. Backends that don't
/// dispatch tools (legacy workflow agents) won't conform.
public protocol AssistantBackendConfirming: AssistantBackend {
    func confirmProposal(_ id: UUID) async
    func cancelProposal(_ id: UUID) async
}

public struct AssistantTurn: Sendable {
    public let id: String
    public let prompt: String

    public init(id: String = UUID().uuidString, prompt: String) {
        self.id = id
        self.prompt = prompt
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

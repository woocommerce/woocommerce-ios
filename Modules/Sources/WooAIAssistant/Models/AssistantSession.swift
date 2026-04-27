/// Opaque handle a backend uses to associate turns with a running
/// conversation. The two fields map cleanly to A2A's (`sessionId`, `taskId`)
/// pair while staying generic enough for other transports.
public struct AssistantSession: Equatable, Sendable {
    public let sessionID: String
    public let taskID: String?

    public init(sessionID: String, taskID: String? = nil) {
        self.sessionID = sessionID
        self.taskID = taskID
    }
}

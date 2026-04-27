/// `sessionID` is stable for the lifetime of the conversation; `taskID` is
/// set only when the conversation is bound to a discrete task scope.
public struct AssistantSession: Equatable, Sendable {
    public let sessionID: String
    public let taskID: String?

    public init(sessionID: String, taskID: String? = nil) {
        self.sessionID = sessionID
        self.taskID = taskID
    }
}

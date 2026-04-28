/// Result of a single tool dispatch. Sealed so every executor commits to
/// one of the four shapes; the orchestrator pattern-matches without
/// stringly-typed status fields, and tools never `throw` past this point.
public enum ToolResult: Sendable {
    /// Successful execution. `structured` is the compact, model-visible
    /// summary; `uiStructured` is the optional full render payload that
    /// stays app-side and never re-enters model context.
    case success(Success)

    /// Tool ran but the operation logically failed (NotFound, validation,
    /// HTTP 4xx). Surfaced to the model as `{"error":..., "reason":...}`.
    case failed(Failed)

    /// Tool was rejected by safety policy before dispatch (e.g. unconfirmed
    /// destructive write). Distinct from `.failed` so analytics can split.
    case rejectedBySafety(SafetyRejection)

    /// Confirmation flow was started; the loop resumes after the user
    /// confirms or cancels. Carries the proposal payload for the UI.
    case awaitingConfirmation(ConfirmationProposal)

    public struct Success: Sendable {
        public let toolName: String
        public let toolCallID: String
        public let structured: AnyCodableJSON
        public let uiStructured: UIStructured?

        public init(toolName: String,
                    toolCallID: String = "",
                    structured: AnyCodableJSON,
                    uiStructured: UIStructured? = nil) {
            self.toolName = toolName
            self.toolCallID = toolCallID
            self.structured = structured
            self.uiStructured = uiStructured
        }
    }

    public struct Failed: Sendable, Error {
        public let toolName: String
        public let toolCallID: String
        public let kind: AssistantErrorKind
        public let reason: String
        public let code: String?

        public init(toolName: String,
                    toolCallID: String = "",
                    kind: AssistantErrorKind,
                    reason: String,
                    code: String? = nil) {
            self.toolName = toolName
            self.toolCallID = toolCallID
            self.kind = kind
            self.reason = reason
            self.code = code
        }
    }

    public struct SafetyRejection: Sendable {
        public let toolName: String
        public let toolCallID: String
        public let reason: String

        public init(toolName: String, toolCallID: String = "", reason: String) {
            self.toolName = toolName
            self.toolCallID = toolCallID
            self.reason = reason
        }
    }

    public struct ConfirmationProposal: Sendable {
        public let toolName: String
        public let toolCallID: String
        public let proposal: AnyCodableJSON

        public init(toolName: String, toolCallID: String = "", proposal: AnyCodableJSON) {
            self.toolName = toolName
            self.toolCallID = toolCallID
            self.proposal = proposal
        }
    }

    func stamping(toolCallID: String) -> ToolResult {
        switch self {
        case .success(let s):
            return .success(.init(toolName: s.toolName,
                                  toolCallID: toolCallID,
                                  structured: s.structured,
                                  uiStructured: s.uiStructured))
        case .failed(let f):
            return .failed(.init(toolName: f.toolName,
                                 toolCallID: toolCallID,
                                 kind: f.kind,
                                 reason: f.reason,
                                 code: f.code))
        case .rejectedBySafety(let r):
            return .rejectedBySafety(.init(toolName: r.toolName,
                                           toolCallID: toolCallID,
                                           reason: r.reason))
        case .awaitingConfirmation(let p):
            return .awaitingConfirmation(.init(toolName: p.toolName,
                                               toolCallID: toolCallID,
                                               proposal: p.proposal))
        }
    }
}

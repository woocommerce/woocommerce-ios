import Foundation

/// Represents a single message in the AI Help chat conversation.
///
struct AIHelpChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date
    var diagnosticStatus: DiagnosticStatus?
    var actions: [MessageAction]

    init(role: Role,
         content: String,
         timestamp: Date = Date(),
         diagnosticStatus: DiagnosticStatus? = nil,
         actions: [MessageAction] = []) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.diagnosticStatus = diagnosticStatus
        self.actions = actions
    }

    /// Who sent this message.
    ///
    enum Role {
        /// System-generated informational message.
        case system
        /// User's selection or input.
        case user
        /// Result of an automated diagnostic check.
        case diagnosticResult
    }

    /// Status of a diagnostic check.
    ///
    enum DiagnosticStatus {
        case success
        case failure
        case loading
        case warning
    }

    /// An actionable button within a message.
    ///
    struct MessageAction: Identifiable {
        let id = UUID()
        let title: String
        let actionType: ActionType

        enum ActionType {
            case enableAnalytics
            case fileZendeskTicket
            case openNotificationSettings
            case enableOrderNotifications
            case enableReviewNotifications
        }
    }
}

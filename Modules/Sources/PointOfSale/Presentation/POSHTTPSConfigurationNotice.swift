import Foundation

/// Content and actions for the HTTPS configuration warning supplied by the host app.
public struct POSHTTPSConfigurationNotice {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    let onDismiss: () -> Void

    public init(title: String,
                message: String,
                actionTitle: String,
                onAction: @escaping () -> Void,
                onDismiss: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }
}

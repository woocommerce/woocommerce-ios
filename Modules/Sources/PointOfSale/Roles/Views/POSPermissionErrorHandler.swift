import SwiftUI
import enum Networking.NetworkError

/// Handles 403 permission errors from POS API calls by showing an alert
/// with options to dismiss or switch user (lock screen).
struct POSPermissionErrorAlert: ViewModifier {
    @Environment(\.posPermissions) private var permissions
    @Binding var error: Error?

    func body(content: Content) -> some View {
        content
            .alert(Localization.title, isPresented: showAlert) {
                Button(Localization.ok, role: .cancel) {
                    error = nil
                }
                if permissions.hasAnyPINs {
                    Button(Localization.switchUser) {
                        error = nil
                        permissions.lock()
                    }
                }
            } message: {
                Text(Localization.message)
            }
    }

    private var showAlert: Binding<Bool> {
        Binding(
            get: { error?.isPermissionError == true },
            set: { if !$0 { error = nil } }
        )
    }
}

extension View {
    /// Shows a permission error alert when a 403 is encountered during POS operations.
    func posPermissionErrorAlert(error: Binding<Error?>) -> some View {
        modifier(POSPermissionErrorAlert(error: error))
    }
}

// MARK: - Error Detection

private extension Error {
    /// Whether this error represents a 403 permission/capability failure.
    var isPermissionError: Bool {
        if let networkError = self as? NetworkError {
            switch networkError {
            case .unacceptableStatusCode(let statusCode, _):
                return statusCode == 403
            default:
                return false
            }
        }
        return false
    }
}

// MARK: - Localization

private enum Localization {
    static let title = NSLocalizedString(
        "pos.permissionError.title",
        value: "Permission required",
        comment: "Title of the alert shown when a POS API call fails due to insufficient permissions."
    )
    static let message = NSLocalizedString(
        "pos.permissionError.message",
        value: "Your account doesn't have permission for this action. Ask a store manager to check your role settings, or switch to a different user.",
        comment: "Message shown when a POS API call returns a 403 permission error."
    )
    static let ok = NSLocalizedString(
        "pos.permissionError.ok",
        value: "OK",
        comment: "Button to dismiss the POS permission error alert."
    )
    static let switchUser = NSLocalizedString(
        "pos.permissionError.switchUser",
        value: "Switch user",
        comment: "Button to lock POS and show the PIN screen so a different user can sign in."
    )
}

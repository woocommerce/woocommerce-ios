import SwiftUI
import enum Networking.POSAuthError

/// Overlay that shows the POS lock screen when the permission provider is locked
/// or when staff PINs are configured and no operator is signed in.
struct POSLockScreenOverlay: View {
    @StateObject private var model: POSLockScreenModel
    @State private var pinState: POSPINEntryState = .idle
    @State private var showForgotPINAlert: Bool = false
    @State private var pinViewID = UUID()

    init(permissionProvider: POSPermissionProviding) {
        _model = StateObject(
            wrappedValue: POSLockScreenModel(provider: permissionProvider)
        )
    }

    var body: some View {
        if model.isShowingLockScreen {
            POSLockScreenView(
                pinState: $pinState,
                onPINEntered: { pin in
                    handlePINEntered(pin)
                },
                onForgotPIN: {
                    showForgotPINAlert = true
                }
            )
            .alert(Localization.forgotPINTitle, isPresented: $showForgotPINAlert) {
                Button(Localization.forgotPINDismiss, role: .cancel) { }
            } message: {
                Text(Localization.forgotPINBody)
            }
            .id(pinViewID)
            .onAppear {
                pinState = .idle
                pinViewID = UUID()
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: model.isShowingLockScreen)
        }
    }

    private func handlePINEntered(_ pin: String) {
        pinState = .loading
        Task { @MainActor in
            do {
                try await model.authenticatePIN(pin)
                pinState = .idle
            } catch let error as POSAuthError {
                switch error {
                case .rateLimited(let retryAfter):
                    if retryAfter < 0 {
                        pinState = .lockout(message: Localization.permanentlyLocked)
                    } else {
                        pinState = .lockout(message: error.errorDescription ?? Localization.invalidPIN)
                    }
                default:
                    pinState = .error(message: error.errorDescription ?? Localization.invalidPIN)
                }
            } catch {
                pinState = .error(message: Localization.invalidPIN)
            }
        }
    }

    private enum Localization {
        static let invalidPIN = NSLocalizedString(
            "pos.lockScreen.invalidPIN",
            value: "Invalid PIN",
            comment: "Error shown when an incorrect PIN is entered on the POS lock screen"
        )
        static let permanentlyLocked = NSLocalizedString(
            "pos.lockScreen.permanentlyLocked",
            value: "Too many failed attempts. Log out to reset.",
            comment: "Message shown on the POS lock screen after too many failed PIN attempts, requiring logout to recover."
        )
        static let forgotPINTitle = NSLocalizedString(
            "pos.lockScreen.forgotPIN.title",
            value: "Forgot your PIN?",
            comment: "Title of the alert shown when tapping Forgot PIN on the POS lock screen"
        )
        static let forgotPINBody = NSLocalizedString(
            "pos.lockScreen.forgotPIN.body",
            value: "Ask the store owner to reset your PIN in WooCommerce > Settings > Point of sale > Staff.",
            comment: "Body text of the Forgot PIN alert, explaining how to reset PINs via the web admin."
        )
        static let forgotPINDismiss = NSLocalizedString(
            "pos.lockScreen.forgotPIN.dismiss",
            value: "OK",
            comment: "Button to dismiss the Forgot PIN alert on the POS lock screen"
        )
    }
}

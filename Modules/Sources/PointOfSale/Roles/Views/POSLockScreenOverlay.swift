import SwiftUI

/// Overlay that shows the POS lock screen when the permission provider is locked.
struct POSLockScreenOverlay: View {
    @StateObject private var model: POSLockScreenModel
    @State private var pinState: POSPINEntryState = .idle
    @State private var showForgotPINAlert: Bool = false

    private let isRemoteMode: Bool
    private let onLogOut: (() -> Void)?

    init(permissionProvider: POSPermissionProviding,
         onLogOut: (() -> Void)? = nil) {
        let authenticator: POSPINAuthenticating
        if let local = permissionProvider as? LocalPOSPermissionProvider {
            authenticator = LocalPOSPINAuthenticator(provider: local)
            self.isRemoteMode = false
        } else if let remote = permissionProvider as? RemotePOSPermissionProvider {
            authenticator = RemotePOSPINAuthenticator(provider: remote)
            self.isRemoteMode = true
        } else {
            authenticator = NoOpPOSPINAuthenticator()
            self.isRemoteMode = false
        }
        self.onLogOut = onLogOut
        _model = StateObject(
            wrappedValue: POSLockScreenModel(
                provider: permissionProvider,
                authenticator: authenticator
            )
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
                forgotPINAlertButtons
            } message: {
                Text(forgotPINAlertMessage)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: model.isShowingLockScreen)
        }
    }

    @ViewBuilder
    private var forgotPINAlertButtons: some View {
        if isRemoteMode {
            Button(Localization.forgotPINDismiss, role: .cancel) { }
        } else {
            Button(Localization.forgotPINLogOut, role: .destructive) {
                onLogOut?()
            }
            Button(Localization.forgotPINCancel, role: .cancel) { }
        }
    }

    private var forgotPINAlertMessage: String {
        if isRemoteMode {
            return Localization.forgotPINRemoteBody
        } else {
            return Localization.forgotPINLocalBody
        }
    }

    private func handlePINEntered(_ pin: String) {
        Task { @MainActor in
            let success = await model.authenticatePIN(pin)
            if !success {
                pinState = .error(message: Localization.invalidPIN)
            } else {
                pinState = .idle
            }
        }
    }

    private enum Localization {
        static let invalidPIN = NSLocalizedString(
            "pos.lockScreen.invalidPIN",
            value: "Invalid PIN",
            comment: "Error shown when an incorrect PIN is entered on the POS lock screen"
        )
        static let forgotPINTitle = NSLocalizedString(
            "pos.lockScreen.forgotPIN.title",
            value: "Forgot your PIN?",
            comment: "Title of the alert shown when tapping Forgot PIN on the POS lock screen"
        )
        static let forgotPINLocalBody = NSLocalizedString(
            "pos.lockScreen.forgotPIN.localBody",
            value: "You can log out and sign in with an admin account to reset PINs.",
            comment: "Body text of the Forgot PIN alert in local mode, explaining how to reset PINs."
        )
        static let forgotPINRemoteBody = NSLocalizedString(
            "pos.lockScreen.forgotPIN.remoteBody",
            value: "Ask the store owner to reset your PIN in WooCommerce > Settings > Point of sale > Staff.",
            comment: "Body text of the Forgot PIN alert in remote mode, explaining how to reset PINs."
        )
        static let forgotPINDismiss = NSLocalizedString(
            "pos.lockScreen.forgotPIN.dismiss",
            value: "OK",
            comment: "Button to dismiss the Forgot PIN alert on the POS lock screen"
        )
        static let forgotPINLogOut = NSLocalizedString(
            "pos.lockScreen.forgotPIN.logOut",
            value: "Log out",
            comment: "Button to log out from the Forgot PIN alert on the POS lock screen in local mode."
        )
        static let forgotPINCancel = NSLocalizedString(
            "pos.lockScreen.forgotPIN.cancel",
            value: "Cancel",
            comment: "Button to cancel the Forgot PIN alert on the POS lock screen."
        )
    }
}

/// No-op authenticator used when the provider type is neither local nor remote.
private struct NoOpPOSPINAuthenticator: POSPINAuthenticating {
    func authenticate(pin: String) async -> Bool { false }
    func verifyManagerPIN(_ pin: String) -> Bool { false }
}

import SwiftUI

/// Overlay that shows the POS lock screen when the permission provider is locked.
struct POSLockScreenOverlay: View {
    @StateObject private var model: POSLockScreenModel
    @State private var pinState: POSPINEntryState = .idle

    init(permissionProvider: POSPermissionProviding) {
        let authenticator: POSPINAuthenticating
        if let local = permissionProvider as? LocalPOSPermissionProvider {
            authenticator = LocalPOSPINAuthenticator(provider: local)
        } else if let remote = permissionProvider as? RemotePOSPermissionProvider {
            authenticator = RemotePOSPINAuthenticator(provider: remote)
        } else {
            authenticator = NoOpPOSPINAuthenticator()
        }
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
                }
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: model.isShowingLockScreen)
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
    }
}

/// No-op authenticator used when the provider type is neither local nor remote.
private struct NoOpPOSPINAuthenticator: POSPINAuthenticating {
    func authenticate(pin: String) async -> Bool { false }
    func verifyManagerPIN(_ pin: String) -> Bool { false }
}

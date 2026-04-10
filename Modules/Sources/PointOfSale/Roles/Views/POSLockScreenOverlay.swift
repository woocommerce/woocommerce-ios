import SwiftUI

/// Overlay that conditionally shows the POS lock screen based on the permission provider state.
/// Uses a timer to poll the provider's state since @Observable tracking doesn't work
/// through protocol-typed references.
struct POSLockScreenOverlay: View {
    let permissionProvider: POSPermissionProviding

    @State private var pinState: POSPINEntryState = .idle
    @State private var shouldShowLockScreen: Bool = false

    var body: some View {
        Group {
            if shouldShowLockScreen {
                POSLockScreenView(
                    pinState: $pinState,
                    onPINEntered: { pin in
                        handlePINEntered(pin)
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            refreshLockState()
        }
        .onReceive(Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()) { _ in
            refreshLockState()
        }
    }

    private func refreshLockState() {
        let newValue = permissionProvider.isLocked && permissionProvider.currentOperator == nil
        if newValue != shouldShowLockScreen {
            withAnimation(.easeInOut(duration: 0.25)) {
                shouldShowLockScreen = newValue
            }
        }
    }

    private func handlePINEntered(_ pin: String) {
        if let localProvider = permissionProvider as? LocalPOSPermissionProvider {
            handleLocalPIN(pin, provider: localProvider)
        } else if let remoteProvider = permissionProvider as? RemotePOSPermissionProvider {
            handleRemotePIN(pin, provider: remoteProvider)
        } else {
            pinState = .error(message: Localization.invalidPIN)
        }
    }

    private func handleLocalPIN(_ pin: String, provider: LocalPOSPermissionProvider) {
        if provider.authenticatePIN(pin) != nil {
            pinState = .idle
            refreshLockState()
        } else {
            pinState = .error(message: Localization.invalidPIN)
        }
    }

    private func handleRemotePIN(_ pin: String, provider: RemotePOSPermissionProvider) {
        Task { @MainActor in
            do {
                _ = try await provider.authenticateRemotePIN(pin)
                pinState = .idle
                refreshLockState()
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
    }
}

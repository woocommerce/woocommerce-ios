import SwiftUI

/// Overlay that conditionally shows the POS lock screen based on the permission provider state.
/// This view is responsible for observing the `@Observable` permission provider
/// and handling PIN authentication for the lock screen.
struct POSLockScreenOverlay: View {
    let permissionProvider: POSPermissionProviding

    @State private var pinState: POSPINEntryState = .idle

    var body: some View {
        if permissionProvider.isLocked && permissionProvider.currentOperator == nil {
            POSLockScreenView(
                operatorName: nil,
                pinState: $pinState,
                onPINEntered: { pin in
                    handlePINEntered(pin)
                }
            )
            .transition(.opacity)
            .animation(.easeInOut, value: permissionProvider.isLocked)
        }
    }

    private func handlePINEntered(_ pin: String) {
        guard let localProvider = permissionProvider as? LocalPOSPermissionProvider else {
            return
        }
        if localProvider.authenticatePIN(pin) != nil {
            pinState = .idle
        } else {
            pinState = .error(message: Localization.invalidPIN)
        }
    }

    private enum Localization {
        static let invalidPIN = NSLocalizedString(
            "pos.lockScreen.invalidPIN",
            value: "Invalid PIN",
            comment: "Error message shown when an incorrect PIN is entered on the POS lock screen"
        )
    }
}

import SwiftUI

/// Full-screen lock screen that wraps the PIN entry with a title
/// and a "Forgot PIN?" link.
struct POSLockScreenView: View {
    let onPINEntered: (String) -> Void

    @Binding var pinState: POSPINEntryState
    @State private var showForgotPINInfo: Bool = false

    init(pinState: Binding<POSPINEntryState>,
         onPINEntered: @escaping (String) -> Void) {
        self._pinState = pinState
        self.onPINEntered = onPINEntered
    }

    var body: some View {
        ZStack {
            Color.posSurfaceDim
                .ignoresSafeArea()

            VStack(spacing: POSSpacing.xxLarge) {
                Spacer()

                POSPINEntryView(
                    title: Localization.title,
                    state: $pinState,
                    onPINEntered: { pin in
                        onPINEntered(pin)
                    }
                )

                Spacer()

                forgotPINLink
            }
            .padding(POSPadding.xLarge)
            .alert(Localization.forgotPINTitle, isPresented: $showForgotPINInfo) {
                Button(Localization.forgotPINDismiss, role: .cancel) { }
            } message: {
                Text(Localization.forgotPINBody)
            }
        }
    }

    // MARK: - Forgot PIN Link

    private var forgotPINLink: some View {
        Button {
            showForgotPINInfo = true
        } label: {
            Text(Localization.forgotPINLink)
                .font(.posBodyLargeRegular(underline: true))
                .foregroundColor(.posOnSurfaceVariantLowest)
        }
        .padding(.bottom, POSPadding.large)
    }
}

// MARK: - Localization

private extension POSLockScreenView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.title",
            value: "Enter your PIN",
            comment: "Title on the POS lock screen asking the user to enter their PIN"
        )
        static let forgotPINLink = NSLocalizedString(
            "pos.lockScreen.forgotPINLink",
            value: "Forgot PIN?",
            comment: "Link at the bottom of the POS lock screen to show information about resetting a PIN"
        )
        static let forgotPINTitle = NSLocalizedString(
            "pos.lockScreen.forgotPIN.title",
            value: "Forgot your PIN?",
            comment: "Title of the alert shown when tapping Forgot PIN on the POS lock screen"
        )
        static let forgotPINBody = NSLocalizedString(
            "pos.lockScreen.forgotPIN.body",
            value: "Ask the store owner to reset your PIN in the WordPress admin under WooCommerce > Settings > POS Staff.",
            comment: "Body text of the alert explaining how to reset a POS PIN"
        )
        static let forgotPINDismiss = NSLocalizedString(
            "pos.lockScreen.forgotPIN.dismiss",
            value: "OK",
            comment: "Button to dismiss the Forgot PIN alert on the POS lock screen"
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Lock Screen") {
    @Previewable @State var pinState: POSPINEntryState = .idle

    POSLockScreenView(
        pinState: $pinState,
        onPINEntered: { _ in
            pinState = .error(message: "Invalid PIN")
        }
    )
}
#endif

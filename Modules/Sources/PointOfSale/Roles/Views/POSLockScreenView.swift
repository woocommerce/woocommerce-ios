import SwiftUI

/// Full-screen lock screen that wraps the PIN entry with a title
/// and a "Forgot PIN?" link.
struct POSLockScreenView: View {
    let onPINEntered: (String) -> Void
    let onForgotPIN: () -> Void

    @Binding var pinState: POSPINEntryState

    init(pinState: Binding<POSPINEntryState>,
         onPINEntered: @escaping (String) -> Void,
         onForgotPIN: @escaping () -> Void) {
        self._pinState = pinState
        self.onPINEntered = onPINEntered
        self.onForgotPIN = onForgotPIN
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
        }
    }

    // MARK: - Forgot PIN Link

    private var forgotPINLink: some View {
        Button {
            onForgotPIN()
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
        },
        onForgotPIN: {}
    )
}
#endif

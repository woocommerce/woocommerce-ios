import SwiftUI

/// Full-screen lock screen that wraps the PIN entry with branding
/// and a "Forgot PIN?" link.
struct POSLockScreenView: View {
    let operatorName: String?
    let onPINEntered: (String) -> Void

    @Binding var pinState: POSPINEntryState
    @State private var showForgotPINInfo: Bool = false

    init(operatorName: String?,
         pinState: Binding<POSPINEntryState>,
         onPINEntered: @escaping (String) -> Void) {
        self.operatorName = operatorName
        self._pinState = pinState
        self.onPINEntered = onPINEntered
    }

    var body: some View {
        ZStack {
            Color.posSurfaceDim
                .ignoresSafeArea()

            VStack(spacing: POSSpacing.xxLarge) {
                Spacer()

                if let operatorName {
                    operatorAvatar(name: operatorName)
                }

                POSPINEntryView(
                    title: Localization.title,
                    subtitle: subtitle,
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

    // MARK: - Subtitle

    private var subtitle: String? {
        guard let operatorName else { return nil }
        return String(format: Localization.subtitleFormat, operatorName)
    }

    // MARK: - Operator Avatar

    private func operatorAvatar(name: String) -> some View {
        let initials = Self.initials(from: name)
        return Text(initials)
            .font(.posHeadingBold)
            .foregroundColor(.posOnPrimary)
            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            .background(Color.posPrimary)
            .clipShape(Circle())
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

    // MARK: - Helpers

    static func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        switch components.count {
        case 0:
            return "?"
        case 1:
            return String(components[0].prefix(1)).uppercased()
        default:
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
    }
}

// MARK: - Constants

private extension POSLockScreenView {
    enum Constants {
        static let avatarSize: CGFloat = 72
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
        static let subtitleFormat = NSLocalizedString(
            "pos.lockScreen.subtitle",
            value: "Signed in as %1$@",
            comment: "Subtitle on the POS lock screen showing the signed-in operator name. "
            + "%1$@ is the operator's display name."
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
        operatorName: "Jane Smith",
        pinState: $pinState,
        onPINEntered: { _ in
            pinState = .error(message: "Invalid PIN")
        }
    )
}

#Preview("Lock Screen - No Name") {
    @Previewable @State var pinState: POSPINEntryState = .idle

    POSLockScreenView(
        operatorName: nil,
        pinState: $pinState,
        onPINEntered: { _ in }
    )
}
#endif

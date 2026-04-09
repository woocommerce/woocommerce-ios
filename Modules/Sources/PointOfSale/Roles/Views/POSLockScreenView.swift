import SwiftUI

/// Full-screen lock screen that wraps the PIN entry with branding
/// and a "Log in with a different account" link.
struct POSLockScreenView: View {
    let operatorName: String?
    let onPINEntered: (String) -> Void
    let onLogout: () -> Void

    @Binding var pinState: POSPINEntryState

    init(operatorName: String?,
         pinState: Binding<POSPINEntryState>,
         onPINEntered: @escaping (String) -> Void,
         onLogout: @escaping () -> Void) {
        self.operatorName = operatorName
        self._pinState = pinState
        self.onPINEntered = onPINEntered
        self.onLogout = onLogout
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

                logoutLink
            }
            .padding(POSPadding.xLarge)
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

    // MARK: - Logout Link

    private var logoutLink: some View {
        Button {
            onLogout()
        } label: {
            Text(Localization.logoutLink)
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
        static let logoutLink = NSLocalizedString(
            "pos.lockScreen.logoutLink",
            value: "Log in with a different account",
            comment: "Link at the bottom of the POS lock screen to log out and switch accounts"
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
        },
        onLogout: {}
    )
}

#Preview("Lock Screen - No Name") {
    @Previewable @State var pinState: POSPINEntryState = .idle

    POSLockScreenView(
        operatorName: nil,
        pinState: $pinState,
        onPINEntered: { _ in },
        onLogout: {}
    )
}
#endif

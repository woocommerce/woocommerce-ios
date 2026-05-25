import SwiftUI

struct POSLockScreenView: View {
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession) {
        self._model = State(initialValue: POSLockScreenModel(session: session))
    }

    init(model: POSLockScreenModel) {
        self._model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            Color.posSurfaceContainerLow
                .ignoresSafeArea()

            VStack(spacing: POSSpacing.xxLarge) {
                header

                if model.hasAnyPINs {
                    POSPINEntryView(state: model.pinEntryState) { pin in
                        Task {
                            await model.signIn(withPIN: pin)
                        }
                    }
                    .frame(height: Constants.pinEntryHeight)
                } else {
                    noPINsMessage
                }
            }
            .frame(maxWidth: Constants.contentWidth)
            .padding(POSPadding.xxLarge)
        }
        .task {
            await model.refreshPINStatus()
        }
    }
}

// MARK: - Subviews

private extension POSLockScreenView {
    var header: some View {
        VStack(spacing: POSSpacing.medium) {
            Image(systemName: "lock.fill")
                .font(.posHeadingBold)
                .foregroundColor(.posPrimary)
                .accessibilityHidden(true)

            VStack(spacing: POSSpacing.xSmall) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }
        }
    }

    var noPINsMessage: some View {
        VStack(spacing: POSSpacing.small) {
            Text(Localization.noPINsTitle)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.center)

            Text(Localization.noPINsMessage)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .padding(POSPadding.large)
        .background(Color.posSurface)
        .cornerRadius(POSCornerRadiusStyle.medium.value)
    }
}

// MARK: - Constants

private extension POSLockScreenView {
    enum Constants {
        static let contentWidth: CGFloat = 420
        static let pinEntryHeight: CGFloat = 430
    }
}

// MARK: - Localization

private extension POSLockScreenView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.title",
            value: "Enter staff PIN",
            comment: "Title shown on the POS lock screen."
        )
        static let subtitle = NSLocalizedString(
            "pos.lockScreen.subtitle",
            value: "Unlock POS to continue.",
            comment: "Subtitle shown on the POS lock screen."
        )
        static let noPINsTitle = NSLocalizedString(
            "pos.lockScreen.noPINs.title",
            value: "Staff PINs are not set up",
            comment: "Title shown on the POS lock screen when no staff PINs are available."
        )
        static let noPINsMessage = NSLocalizedString(
            "pos.lockScreen.noPINs.message",
            value: "Ask a store manager to set up staff PINs before locking POS.",
            comment: "Message shown on the POS lock screen when no staff PINs are available."
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Locked") {
    POSLockScreenView(session: MockPOSAccessSession(isLocked: true))
}

#Preview("Invalid PIN") {
    let model = POSLockScreenModel(session: MockPOSAccessSession(isLocked: true, signInResult: .failure(.invalidPIN)))
    model.pinEntryState = .error(message: "Incorrect PIN. Try again.")
    return POSLockScreenView(model: model)
}

#Preview("No PINs") {
    POSLockScreenView(session: MockPOSAccessSession(isLocked: true, hasAnyPINs: false, refreshedPINStatus: false))
}
#endif

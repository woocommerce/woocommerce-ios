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

                POSPINEntryView(state: model.pinEntryState) { pin in
                    Task {
                        await model.signIn(withPIN: pin)
                    }
                }
                .frame(height: Constants.pinEntryHeight)
            }
            .frame(maxWidth: Constants.contentWidth)
            .padding(POSPadding.xxLarge)
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
    }
}

// MARK: - Constants

private extension POSLockScreenView {
    enum Constants {
        static let contentWidth: CGFloat = 420
        static let pinEntryHeight: CGFloat = 430
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
#endif

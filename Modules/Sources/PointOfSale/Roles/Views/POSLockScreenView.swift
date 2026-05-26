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

            VStack(spacing: POSPINEntryView.titleToPINSpacing) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                POSPINEntryView(state: model.pinEntryState) { pin in
                    Task {
                        await model.signIn(withPIN: pin)
                    }
                }
                .frame(height: POSPINEntryView.preferredHeight)
            }
            .frame(maxWidth: POSPINEntryView.contentWidth)
            .padding(POSPadding.xxLarge)
        }
    }
}

// MARK: - Localization

private extension POSLockScreenView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.enterYourPIN.title",
            value: "Enter your PIN",
            comment: "Title shown on the POS lock screen."
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Locked") {
    POSLockScreenView(session: MockPOSAccessSession(isLocked: true))
}

#Preview("Invalid PIN") {
    let model = POSLockScreenModel(
        session: MockPOSAccessSession(isLocked: true, signInResult: .failure(.invalidPIN)),
        initialPinEntryState: .error(message: "Incorrect PIN. Try again.")
    )
    return POSLockScreenView(model: model)
}
#endif

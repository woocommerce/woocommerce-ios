import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posMetrics) private var metrics
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession) {
        self._model = State(initialValue: POSLockScreenModel(session: session))
    }

    init(model: POSLockScreenModel) {
        self._model = State(initialValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.posSurfaceContainerLow.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: metrics.spacing.large) {
                        Text(Localization.title)
                            .font(.posHeadingBold)
                            .foregroundStyle(Color.posOnSurface)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        POSPINEntryView(state: model.pinEntryState, onComplete: { pin in
                            await model.signIn(withPIN: pin)
                        })

                        Button(Localization.forgotPIN) { Task { await model.forgotPIN() } }
                            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                            .disabled(model.isRecovering)
                            .accessibilityIdentifier("pos-forgot-pin-button")
                    }
                    .frame(maxWidth: POSPINEntryView.contentWidth)
                    .padding(metrics.padding.xxLarge)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .task { await model.observeWait() }
        .alert(Localization.recoveryUnavailable, isPresented: $model.showsRecoveryUnavailable) {
            Button(Localization.ok, role: .cancel) {}
        }
    }
}

// MARK: - Localization

private extension POSLockScreenView {
    enum Localization {
        static let forgotPIN = NSLocalizedString(
            "pos.lockScreen.forgotPIN.button", value: "Forgot PIN?", comment: "Recovery entry on the POS lock screen, also available during a wait.")
        static let recoveryUnavailable = NSLocalizedString(
            "pos.lockScreen.recoveryUnavailable.message",
            value: "PIN recovery is not available yet.",
            comment: "Temporary message until POS account recovery is implemented.")
        static let ok = NSLocalizedString("pos.lockScreen.recoveryUnavailable.ok", value: "OK", comment: "Dismisses the POS PIN recovery unavailable message.")
        static let title = NSLocalizedString(
            "pos.lockScreen.unlockPOS.title",
            value: "Enter your PIN to unlock POS",
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
        initialPinEntryState: .error(kind: .invalidPIN)
    )
    return POSLockScreenView(model: model)
}
#endif

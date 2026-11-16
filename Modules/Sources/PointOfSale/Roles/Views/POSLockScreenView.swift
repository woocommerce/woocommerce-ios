import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posMetrics) private var metrics
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession) {
        self._model = State(initialValue: POSLockScreenModel(session: session))
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
                    }
                    .frame(maxWidth: POSPINEntryView.contentWidth)
                    .padding(metrics.padding.xxLarge)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .task { await model.observeWait() }
    }
}

// MARK: - Localization

private extension POSLockScreenView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.unlockPOS.title",
            value: "Enter your PIN to unlock POS",
            comment: "Title shown on the POS lock screen."
        )
    }
}

// MARK: - Preview

#if DEBUG
extension POSLockScreenView {
    init(model: POSLockScreenModel) {
        self._model = State(initialValue: model)
    }
}

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

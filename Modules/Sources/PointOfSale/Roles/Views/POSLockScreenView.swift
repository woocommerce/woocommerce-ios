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
        Group {
            switch model.content {
            case .loading:
                // Reuse the shared POS loading view so the lock-screen loading state is
                // indistinguishable from any other POS loading running in parallel (the
                // dashboard's own catalog/order syncs all use this same component).
                PointOfSaleLoadingView()
            case .pinEntry:
                pinEntryScreen
            case .unavailable:
                unavailableScreen
            }
        }
        .task {
            await model.refreshPINStatus()
        }
    }

    private var pinEntryScreen: some View {
        ZStack {
            Color.posSurfaceContainerLow
                .ignoresSafeArea()

            VStack(spacing: POSPINEntryView.titleToPINSpacing) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                POSPINEntryView(
                    state: model.pinEntryState,
                    onComplete: { pin in
                        await model.signIn(withPIN: pin)
                    },
                    onLockoutExpired: { model.lockoutExpired() }
                )
                .frame(height: POSPINEntryView.preferredHeight)
            }
            .frame(maxWidth: POSPINEntryView.contentWidth)
            .padding(POSPadding.xxLarge)
        }
    }

    private var unavailableScreen: some View {
        ZStack {
            Color.posSurfaceContainerLow
                .ignoresSafeArea()

            POSLockScreenUnavailableView {
                await model.refreshPINStatus()
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
#Preview("Locked - PIN entry") {
    POSLockScreenView(session: MockPOSAccessSession(isLocked: true, pinStatus: .present))
}

#Preview("Invalid PIN") {
    let model = POSLockScreenModel(
        session: MockPOSAccessSession(isLocked: true, pinStatus: .present,
                                       signInResult: .failure(.invalidPIN)),
        initialPinEntryState: .error(kind: .invalidPIN)
    )
    return POSLockScreenView(model: model)
}

#Preview("Loading staff") {
    let model = POSLockScreenModel(
        session: MockPOSAccessSession(isLocked: true, pinStatus: .unknown),
        isRefreshing: true
    )
    return POSLockScreenView(model: model)
}

#Preview("Staff unavailable") {
    let model = POSLockScreenModel(
        session: MockPOSAccessSession(isLocked: true, pinStatus: .unknown),
        isRefreshing: false
    )
    return POSLockScreenView(model: model)
}
#endif

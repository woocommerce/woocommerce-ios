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

            content
                .frame(maxWidth: POSPINEntryView.contentWidth)
                .padding(POSPadding.xxLarge)
        }
        .task {
            await model.refreshPINStatus()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.content {
        case .pinEntry:
            pinEntryContent
        case .loading:
            loadingContent
        case .unavailable:
            POSLockScreenUnavailableView {
                await model.refreshPINStatus()
            }
        }
    }

    private var pinEntryContent: some View {
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
    }

    private var loadingContent: some View {
        VStack(spacing: POSSpacing.large) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.posPrimary)

            Text(Localization.loading)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
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
        static let loading = NSLocalizedString(
            "pos.lockScreen.loading",
            value: "Loading staff...",
            comment: "Status text shown on the POS lock screen while the staff list is being fetched."
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

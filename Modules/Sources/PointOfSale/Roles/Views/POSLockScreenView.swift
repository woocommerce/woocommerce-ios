import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var model: POSLockScreenModel
    private let animatesLock: Bool
    #if DEBUG
    private var previewEnteredPIN: String?
    #endif

    init(session: POSAccessSession) {
        self._model = State(initialValue: POSLockScreenModel(session: session))
        self.animatesLock = true
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding(.horizontal, metrics.padding.xxLarge)
                    .padding(.vertical, isCompactHeight ? metrics.padding.small : metrics.padding.xxLarge)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .task { await model.observeWait() }
    }
}

private extension POSLockScreenView {
    /// Phones in landscape place the keypad beside the title so all keys stay visible without scrolling.
    var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    var keySize: CGFloat {
        if isCompactHeight {
            return Constants.compactHeightKeySize
        }
        return layoutScale == .compact ? Constants.compactKeySize : Constants.regularKeySize
    }

    /// One layout container keeps the PIN entry's identity, so rotating does not clear entered digits.
    var content: some View {
        let layout = isCompactHeight
            ? AnyLayout(HStackLayout(spacing: metrics.spacing.xxLarge))
            : AnyLayout(VStackLayout(spacing: metrics.spacing.xLarge))
        return layout {
            header
                .frame(maxWidth: isCompactHeight ? POSPINEntryView.contentWidth : nil)
            pinEntry
                .frame(width: isCompactHeight ? POSPINEntryView.lockScreenKeypadWidth(keySize: keySize, metrics: metrics) : nil)
                .frame(maxWidth: isCompactHeight ? nil : POSPINEntryView.contentWidth)
                .fixedSize(horizontal: false, vertical: isCompactHeight)
        }
    }

    var header: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            POSLockIllustration(animatesClosing: animatesLock)
            Text(Localization.title)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    var pinEntry: some View {
        let view = POSPINEntryView(state: model.pinEntryState, style: .lockScreen(keySize: keySize), onComplete: { pin in
            await model.signIn(withPIN: pin)
        })
        #if DEBUG
        if let previewEnteredPIN {
            return view.previewing(enteredPIN: previewEnteredPIN)
        }
        #endif
        return view
    }

    enum Constants {
        static let regularKeySize: CGFloat = 90
        static let compactKeySize: CGFloat = 72
        static let compactHeightKeySize: CGFloat = 60
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
    init(model: POSLockScreenModel, animatesLock: Bool = false) {
        self._model = State(initialValue: model)
        self.animatesLock = animatesLock
    }

    static func preview(_ state: POSPINEntryState, enteredPIN: String? = nil) -> POSLockScreenView {
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: Self.previewLockoutResult(for: state))
        var view = POSLockScreenView(model: POSLockScreenModel(session: session, initialPinEntryState: state))
        view.previewEnteredPIN = enteredPIN
        return view
    }

    /// Keeps the model's first lockout check from replacing a previewed wait or outage.
    private static func previewLockoutResult(for state: POSPINEntryState) -> Result<Void, POSAuthError> {
        switch state {
        case .waiting(let remainingSeconds): .failure(.rateLimited(remainingSeconds: remainingSeconds))
        case .unavailable: .failure(.unknown)
        default: .success(())
        }
    }
}

#Preview("Locking") {
    POSLockScreenView(session: MockPOSAccessSession(isLocked: true))
}

#Preview("Idle") {
    POSLockScreenView.preview(.idle)
}

#Preview("Two digits") {
    POSLockScreenView.preview(.idle, enteredPIN: "12")
}

#Preview("Incorrect PIN") {
    POSLockScreenView.preview(.error(kind: .invalidPIN))
}

#Preview("Wait") {
    POSLockScreenView.preview(.waiting(remainingSeconds: 30))
}
#endif

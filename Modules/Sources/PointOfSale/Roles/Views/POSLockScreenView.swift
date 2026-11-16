import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: POSLockScreenModel
    @State private var illustrationFrame: CGRect = .zero
    @State private var titleHeight: CGFloat = 0
    @State private var keypadHeight: CGFloat = 0
    @State private var intro = POSLockScreenIntro()
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
                content(viewportSize: geometry.size)
                    .padding(.horizontal, metrics.padding.xxLarge)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .coordinateSpace(name: Constants.coordinateSpace)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(isIntroActive)
            .onChange(of: reduceMotion) { _, reduced in
                if reduced { intro.cancel() }
            }
            .task(id: isLayoutMeasured) {
                guard isLayoutMeasured else { return }
                await intro.run(shouldAnimate: animatesLock && !reduceMotion
                                && showsIllustration(availableHeight: geometry.size.height - verticalPadding * 2))
            }
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .task { await model.observeWait() }
        .onDisappear { intro.cancel() }
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

    var verticalPadding: CGFloat {
        isCompactHeight ? metrics.padding.small : metrics.padding.xxLarge
    }

    func showsIllustration(availableHeight: CGFloat) -> Bool {
        let headerHeight = illustrationFrame.height + metrics.spacing.xLarge + titleHeight
        let contentHeight = isCompactHeight
            ? max(headerHeight, keypadHeight)
            : headerHeight + metrics.spacing.xLarge + keypadHeight
        return contentHeight <= availableHeight
    }

    /// One layout container keeps the PIN entry's identity, so rotating does not clear entered digits.
    func content(viewportSize: CGSize) -> some View {
        let layout = isCompactHeight
            ? AnyLayout(HStackLayout(spacing: metrics.spacing.xxLarge))
            : AnyLayout(VStackLayout(spacing: metrics.spacing.xLarge))
        return layout {
            header(showsIllustration: showsIllustration(availableHeight: viewportSize.height - verticalPadding * 2),
                   viewportSize: viewportSize)
                .frame(maxWidth: isCompactHeight ? POSPINEntryView.contentWidth : nil)
                .zIndex(1)
            pinEntry
                .frame(width: isCompactHeight ? POSPINEntryView.lockScreenKeypadWidth(keySize: keySize, metrics: metrics) : nil)
                .frame(maxWidth: isCompactHeight ? nil : POSPINEntryView.contentWidth)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { keypadHeight = $0 }
                .opacity(showsContent ? 1 : 0)
                .offset(y: introOffset(viewportSize: viewportSize).height)
                .allowsHitTesting(!isIntroActive)
                .accessibilityHidden(isIntroActive)
        }
    }

    func header(showsIllustration: Bool, viewportSize: CGSize) -> some View {
        VStack(spacing: metrics.spacing.none) {
            ZStack {
                // The stationary slot supplies geometry; measuring the moving icon would feed its offset back into itself.
                Color.clear
                    .frame(width: POSLockIllustration.size, height: POSLockIllustration.size)
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named(Constants.coordinateSpace)) }) {
                        illustrationFrame = $0
                    }
                POSLockIllustration(isOpen: isIntroActive && intro.phase == .appearing)
                    .offset(introOffset(viewportSize: viewportSize))
                    .opacity(!isIntroActive || isLayoutMeasured ? 1 : 0)
            }
                .padding(.bottom, metrics.spacing.xLarge)
                .opacity(showsIllustration ? 1 : 0)
                .frame(height: showsIllustration ? nil : 0)
            Text(Localization.title)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { titleHeight = $0 }
                .opacity(showsContent ? 1 : 0)
                .offset(y: introOffset(viewportSize: viewportSize).height)
                .accessibilityHidden(isIntroActive)
        }
    }

    var isLayoutMeasured: Bool {
        illustrationFrame.height > 0 && titleHeight > 0 && keypadHeight > 0
    }

    var isIntroActive: Bool {
        animatesLock && !reduceMotion && intro.phase != .finished
    }

    var showsContent: Bool {
        !isIntroActive || intro.phase == .revealing
    }

    func introOffset(viewportSize: CGSize) -> CGSize {
        guard isIntroActive, intro.phase != .revealing else { return .zero }
        return CGSize(width: viewportSize.width / 2 - illustrationFrame.midX,
                      height: viewportSize.height / 2 - illustrationFrame.midY)
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
        static let coordinateSpace = "posLockScreen"
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

import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.posLockPresenter) private var lockPresenter
    @ScaledMetric(relativeTo: .body) private var statusLineHeight = POSPINEntryView.lockScreenStatusRowHeight
    @State private var model: POSLockScreenModel
    @State private var illustrationFrame: CGRect = .zero
    @State private var titleHeight: CGFloat = 0
    @State private var keypadHeight: CGFloat = 0
    @State private var intro = POSLockScreenIntro()
    @StateObject private var recoveryDialogManager = POSModalManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()
    @State private var recoveryStep: RecoveryStep?
    @AccessibilityFocusState private var isTitleFocused: Bool
    private let animatesLock: Bool
    private let recovery: POSPINRecoveryProviding?
    #if DEBUG
    private var previewEnteredPIN: String?
    #endif

    init(session: POSAccessSession, recovery: POSPINRecoveryProviding? = nil) {
        self._model = State(initialValue: POSLockScreenModel(session: session))
        self.animatesLock = true
        self.recovery = recovery
    }

    var body: some View {
        GeometryReader { geometry in
            let configuration = layoutConfiguration(viewportSize: geometry.size)
            ScrollView {
                content(viewportSize: geometry.size, configuration: configuration)
                    .padding(.horizontal, metrics.padding.xxLarge)
                    .padding(.vertical, configuration.verticalPadding)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .coordinateSpace(name: Constants.coordinateSpace)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(isIntroActive)
            .onChange(of: reduceMotion) { _, reduced in
                if reduced { intro.cancel() }
            }
            // The intro hides the lock's content from VoiceOver, so focus moves to the title once it is readable.
            .onChange(of: isIntroActive, initial: true) { _, isActive in
                guard !isActive else { return }
                // The title rejoins the accessibility tree in this update; focus it on the next turn.
                Task { @MainActor in isTitleFocused = true }
            }
            .task(id: isLayoutMeasured) {
                guard isLayoutMeasured else { return }
                await intro.run(shouldAnimate: animatesLock && !reduceMotion
                                && configuration.showsIllustration)
            }
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .posDialog(item: recoveryDialogItem, onDismissCompleted: { _ in
            guard recoveryStep == .confirmed, let recovery else { return }
            startRecovery(using: recovery)
        }) { step in
            return if step == .failed {
                POSDialog(title: Localization.recoveryFailed,
                          message: Localization.tryAgain,
                          primaryAction: .init(title: Localization.ok, action: { recoveryStep = nil }))
            } else {
                Self.recoveryExplanation(onContinue: { recoveryStep = .confirmed }, onCancel: { recoveryStep = nil })
            }
        }
        .posRootModal()
        .environmentObject(recoveryDialogManager)
        .environmentObject(coverManager)
        .task { await model.observeWait() }
        .onDisappear {
            intro.cancel()
            if recoveryDialogManager.isPresented {
                recoveryDialogManager.dismiss()
            }
            // Lets VoiceOver move focus to the unlocked POS instead of a removed key.
            if !model.isLocked {
                AccessibilityNotification.ScreenChanged().post()
            }
        }
    }
}

private extension POSLockScreenView {
    var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    func layoutConfiguration(viewportSize: CGSize) -> POSLockScreenLayout {
        POSLockScreenLayout(viewportSize: viewportSize,
                            preferredKeySize: layoutScale == .compact ? Constants.compactKeySize : Constants.regularKeySize,
                            titleHeight: titleHeight,
                            illustrationHeight: POSLockIllustration.size,
                            // Reserve the two-line wait message so keys do not resize when feedback replaces the dots.
                            statusHeight: statusLineHeight * Constants.statusLineCount,
                            isCompactHeight: isCompactHeight, metrics: metrics)
    }

    /// One column in every orientation keeps the PIN entry's identity, so rotating does not clear entered digits.
    func content(viewportSize: CGSize, configuration: POSLockScreenLayout) -> some View {
        VStack(spacing: configuration.sectionSpacing) {
            header(showsIllustration: configuration.showsIllustration,
                   viewportSize: viewportSize)
                .zIndex(1)
            pinEntry(keySize: configuration.keySize)
                .disabled(recoveryStep != nil)
                .frame(maxWidth: POSPINEntryView.contentWidth)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { keypadHeight = $0 }
                .opacity(showsContent ? 1 : 0)
                .offset(y: introOffset(viewportSize: viewportSize).height)
                .allowsHitTesting(!isIntroActive)
                .accessibilityHidden(isIntroActive)
            if recovery != nil {
                Button { recoveryStep = .explanation } label: {
                    Text(Localization.forgotPIN)
                        .font(.posBodySmallRegular(underline: true))
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(model.isSigningIn || recoveryStep != nil)
                .accessibilityIdentifier("pos-lock-forgot-pin")
                .opacity(showsContent ? 1 : 0)
                .allowsHitTesting(!isIntroActive)
                .accessibilityHidden(isIntroActive)
            }
        }
    }

    var recoveryDialogItem: Binding<RecoveryStep?> {
        Binding(get: { recoveryStep?.presentsDialog == true ? recoveryStep : nil }, set: { item in
            if recoveryStep?.presentsDialog == true {
                recoveryStep = item
            }
        })
    }

    func startRecovery(using recovery: POSPINRecoveryProviding) {
        recoveryStep = .signIn
        let started = lockPresenter?.startRecovery { presenter in
            let outcome = await model.recoverWithFreshSignIn { siteID in
                await recovery.authenticateForPINRecovery(siteID: siteID, from: presenter)
            }
            recoveryStep = outcome == .failed && !Task.isCancelled && model.isLocked ? .failed : nil
        }
        if started != true {
            recoveryStep = .failed
        }
    }

    static func recoveryExplanation(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) -> POSDialog {
        POSDialog(title: Localization.forgotPIN,
                  message: Localization.recoveryExplanation,
                  primaryAction: .init(title: Localization.continueToSignIn,
                                       accessibilityIdentifier: "pos-pin-recovery-continue",
                                       action: onContinue),
                  secondaryAction: .init(title: Localization.cancel, action: onCancel))
    }

    enum RecoveryStep: Identifiable, Hashable {
        case explanation
        case confirmed
        case signIn
        case failed

        var id: Self { self }
        var presentsDialog: Bool { self == .explanation || self == .failed }
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
                .accessibilityFocused($isTitleFocused)
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

    func pinEntry(keySize: CGFloat) -> some View {
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
        static let statusLineCount: CGFloat = 2
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
        static let forgotPIN = NSLocalizedString(
            "pos.lockScreen.forgotPIN.button",
            value: "Forgot PIN?",
            comment: "Button on the POS lock screen that starts PIN recovery with a fresh sign-in."
        )
        static let recoveryExplanation = NSLocalizedString(
            "pos.lockScreen.forgotPIN.signInToChangePIN",
            value: "Sign in again with the account that is signed in to the app. Then choose a new admin PIN. Your current sale stays in POS.",
            comment: "Explains the result of signing in to recover POS access and change the Admin PIN."
        )
        static let continueToSignIn = NSLocalizedString(
            "pos.lockScreen.forgotPIN.continue",
            value: "Continue to sign in",
            comment: "Opens the sign-in screen from the POS PIN recovery explanation."
        )
        static let cancel = NSLocalizedString(
            "pos.lockScreen.forgotPIN.cancel",
            value: "Cancel",
            comment: "Closes the POS PIN recovery explanation."
        )
        static let recoveryFailed = NSLocalizedString(
            "pos.lockScreen.forgotPIN.failure.title",
            value: "Couldn’t unlock POS",
            comment: "Title when account sign-in does not restore POS access."
        )
        static let tryAgain = NSLocalizedString(
            "pos.lockScreen.forgotPIN.failure.message",
            value: "Try signing in again with Forgot PIN.",
            comment: "Message when account sign-in does not restore POS access."
        )
        static let ok = NSLocalizedString(
            "pos.lockScreen.forgotPIN.failure.ok",
            value: "OK",
            comment: "Dismisses the POS recovery failure message."
        )
    }
}

// MARK: - Preview

#if DEBUG
extension POSLockScreenView {
    init(model: POSLockScreenModel, animatesLock: Bool = false) {
        self._model = State(initialValue: model)
        self.animatesLock = animatesLock
        self.recovery = nil
    }

    static func preview(_ state: POSPINEntryState, enteredPIN: String? = nil) -> POSLockScreenView {
        let session = MockPOSAccessSession(isLocked: true, checkLockoutResult: Self.previewLockoutResult(for: state))
        var view = POSLockScreenView(model: POSLockScreenModel(session: session, initialPinEntryState: state))
        view.previewEnteredPIN = enteredPIN
        return view
    }

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

#Preview("Forgot PIN explanation") {
    POSDialogView(dialog: POSLockScreenView.recoveryExplanation(onContinue: {}, onCancel: {}))
}
#endif

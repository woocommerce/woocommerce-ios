import SwiftUI

struct POSAccessControlSetupView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onGetStarted: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: metrics.spacing.xLarge) {
                    PointOfSaleAssets.accessControl.decorativeImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.artworkSize.width, height: Constants.artworkSize.height)
                    VStack(spacing: metrics.spacing.small) {
                        Text(Localization.title)
                            .font(.posBodyXLargeBold)
                            .foregroundStyle(Color.posOnSurface)
                            .accessibilityAddTraits(.isHeader)
                        Text(Localization.message)
                            .font(.posBodyLargeRegular())
                            .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    Button(Localization.getStarted, action: onGetStarted)
                        .buttonStyle(POSFilledButtonStyle(size: .normal))
                        .frame(maxWidth: Constants.buttonMaxWidth)
                        .accessibilityIdentifier("pos-security-get-started")
                }
                .posContentPadding(.horizontal, metrics.padding.xxLarge)
                .posPadding(.vertical, \.medium)
                .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 2 * navigationInset))
            }
            .contentMargins(.vertical, navigationInset, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var navigationInset: CGFloat {
        // Equal insets keep the content centered in the full pane while clearing the phone's Back control.
        horizontalSizeClass == .compact ? POSHeaderLayoutConstants.minHeight + metrics.padding.medium + metrics.padding.large : 0
    }

    private enum Constants {
        static let artworkSize = CGSize(width: 140, height: 137)
        static let buttonMaxWidth: CGFloat = 612
    }

    private enum Localization {
        static let title = NSLocalizedString("pos.security.accessControl.title", value: "Set up access control",
                                             comment: "Title on POS Security before any PIN is set.")
        static let message = NSLocalizedString("pos.security.accessControl.message", value: "Use PINs to manage what your team can do in the app.",
                                               comment: "Explanation on POS Security before any PIN is set.")
        static let getStarted = NSLocalizedString("pos.security.accessControl.getStarted", value: "Get started",
                                                  comment: "Button on POS Security that starts setting the admin PIN.")
    }
}

struct POSAdminPINOnboardingView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posModalDismissAction) private var dismissModal
    @Environment(\.isPOSModalFullScreenFlow) private var isFullScreenFlow
    @State private var onboarding: POSAdminPINOnboarding
    @State private var pinStatusAndSpacingHeight: CGFloat = 0
    private let controller: POSSecuritySettingsController
    private let close: () -> Void

    init(controller: POSSecuritySettingsController, close: @escaping () -> Void) {
        self.controller = controller
        self.close = close
        self._onboarding = State(initialValue: POSAdminPINOnboarding(setup: controller.makePINSetupController(for: .admin)))
    }

    var body: some View {
        VStack(spacing: metrics.spacing.medium) {
            if !isFullScreenFlow && onboarding.step != .saving {
                header
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .posModalFlowHeaderTitle(title, alignment: .center)
        .posModalFlowBackAction(enabled: isFullScreenFlow && onboarding.canGoBack) { onboarding.goBack() }
        .posModalSizing(fillsAvailableSpace: usesAccessibilityFullScreen)
        .posModalFullScreen(usesAccessibilityFullScreen)
        .posInteractiveDismissDisabled(onboarding.step == .saving || !onboarding.canClose)
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible {
                dismissModal?()
            }
        }
        .onChange(of: onboarding.feedback) { _, feedback in
            if let feedback {
                AccessibilityNotification.Announcement(message(for: feedback)).post()
            }
        }
        .onDisappear { onboarding.discard() }
        .accessibilityIdentifier("pos-admin-pin-onboarding")
    }
}

private extension POSAdminPINOnboardingView {
    var usesAccessibilityFullScreen: Bool {
        horizontalSizeClass == .regular && dynamicTypeSize.isAccessibilitySize
    }

    var title: String {
        switch onboarding.step {
        case .choose: Localization.chooseTitle
        case .confirm: Localization.confirmTitle
        case .saving, .saved, .guidedAccessOffer: ""
        }
    }

    var header: some View {
        ZStack {
            if !title.isEmpty {
                Text(title)
                    .font(.posBodyXLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, POSHeaderLayoutConstants.compactBackButtonSize)
            }
            HStack {
                if onboarding.canGoBack {
                    POSPageHeaderBackButton(configuration: .init(state: .enabled,
                                                                 action: { onboarding.goBack() },
                                                                 accessibilityLabel: Localization.back))
                }
                Spacer()
                POSPageHeaderBackButton(configuration: .init(state: onboarding.canClose ? .enabled : .disabled,
                                                             action: closeFlow,
                                                             buttonIcon: "xmark",
                                                             accessibilityIdentifier: "pos-admin-pin-onboarding-close",
                                                             accessibilityLabel: Localization.close))
            }
        }
        .frame(minHeight: POSHeaderLayoutConstants.compactBackButtonSize)
    }

    @ViewBuilder
    var content: some View {
        switch onboarding.step {
        case .choose, .confirm:
            pinEntry
        case .saving:
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
        case .saved:
            messagePage(art: savedCheck, title: Localization.savedTitle, message: Localization.savedMessage) {
                Button(Localization.continueAction) { onboarding.continueToGuidedAccessOffer() }
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
            .transition(.opacity.animation(Constants.offerFade))
        case .guidedAccessOffer:
            messagePage(art: POSLockIllustration(), title: Localization.offerTitle, message: Localization.offerMessage) {
                // WOOMOB-4595 connects the Guided Access guide.
                Button(Localization.setUpGuidedAccess) {}
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                Button(Localization.maybeLater, action: closeFlow)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            .transition(.opacity.animation(Constants.offerFade.delay(Constants.offerFadeDuration)))
        }
    }

    var pinEntry: some View {
        GeometryReader { geometry in
            let keySize = keySize(fitting: geometry.size)
            let keypadHeight = POSPINEntryViewHelper.lockScreenKeypadSize(keySize: keySize, metrics: metrics).height
            let verticalInset = min(metrics.padding.xLarge, max(0, (geometry.size.height - keypadHeight - pinStatusAndSpacingHeight) / 2))
            ScrollViewReader { proxy in
                ScrollView {
                    POSPINEntryView(state: onboarding.pinEntryState,
                                    style: .setup(keySize: keySize, page: page, feedback: onboarding.feedback.map(message(for:))),
                                    onComplete: { pin in await onboarding.submit(pin) })
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self, of: { max(0, $0.size.height - keypadHeight) }) {
                            pinStatusAndSpacingHeight = $0
                        }
                        .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 2 * verticalInset))
                        .id(Constants.pinEntryTopID)
                }
                .contentMargins(.vertical, verticalInset, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: onboarding.pageID) { proxy.scrollTo(Constants.pinEntryTopID, anchor: .top) }
                .onChange(of: onboarding.feedback) { _, feedback in
                    if feedback != nil {
                        proxy.scrollTo(Constants.pinEntryTopID, anchor: .top)
                    }
                }
            }
        }
        .clipped()
    }

    var savedCheck: some View {
        PointOfSaleAssets.checkCircle.decorativeImage
            .resizable()
            .scaledToFit()
            .frame(width: Constants.checkSize, height: Constants.checkSize)
    }

    var page: POSPINEntryPage {
        POSPINEntryPage(id: onboarding.pageID, edge: onboarding.step == .confirm ? .trailing : .leading)
    }

    func keySize(fitting size: CGSize) -> CGFloat {
        POSPINEntryViewHelper.lockScreenKeySize(fitting: CGSize(width: size.width, height: size.height - pinStatusAndSpacingHeight),
                                               preferred: layoutScale == .compact ? Constants.compactKeySize : Constants.regularKeySize,
                                               metrics: metrics)
    }

    @ViewBuilder
    func messagePage<Art: View, Actions: View>(art: Art,
                                               title: String,
                                               message: String,
                                               @ViewBuilder actions: () -> Actions) -> some View {
        let explanation = VStack(spacing: metrics.spacing.medium) {
            art
                .padding(.bottom, metrics.padding.medium)
            Text(title)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : Constants.messageMaxWidth)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .posPadding(\.large)
        .frame(maxWidth: .infinity)
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(spacing: metrics.spacing.medium) {
                    explanation
                    actions()
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipped()
        } else {
            VStack(spacing: metrics.spacing.medium) {
                ScrollView { explanation }
                    .scrollBounceBehavior(.basedOnSize)
                    .defaultScrollAnchor(.center)
                    .clipped()
                actions()
            }
        }
    }

    func message(for feedback: POSAdminPINOnboarding.Feedback) -> String {
        switch feedback {
        case .mismatch: POSSecuritySettingsView.Localization.mismatch
        case .failure(.pinMatchesOtherRole): POSSecuritySettingsView.Localization.distinctPINs
        case .failure: POSSecuritySettingsView.Localization.storageError
        }
    }

    func closeFlow() {
        if onboarding.close() {
            close()
        }
    }

    enum Constants {
        static let pinEntryTopID = "admin-pin-entry-top"
        static let regularKeySize: CGFloat = 90
        static let compactKeySize: CGFloat = 72
        static let checkSize: CGFloat = 80
        static let messageMaxWidth: CGFloat = 470
        static let offerFadeDuration: TimeInterval = 0.3
        static let offerFade: Animation = .easeInOut(duration: offerFadeDuration)
    }

    enum Localization {
        static let chooseTitle = NSLocalizedString("pos.adminPINOnboarding.choose.title", value: "Choose your admin PIN",
                                                   comment: "Title while choosing the first admin PIN in POS.")
        static let confirmTitle = NSLocalizedString("pos.adminPINOnboarding.confirm.title", value: "Confirm your admin PIN",
                                                    comment: "Title while re-entering the first admin PIN in POS.")
        static let savedTitle = NSLocalizedString("pos.adminPINOnboarding.saved.title", value: "Your admin PIN is set",
                                                  comment: "Title after the first admin PIN is saved in POS.")
        static let savedMessage = NSLocalizedString("pos.adminPINOnboarding.saved.message",
                                                    value: "Use your admin PIN to unlock Point of Sale with full access.",
                                                    comment: "Explanation after the first admin PIN is saved in POS.")
        static let continueAction = NSLocalizedString("pos.adminPINOnboarding.saved.continue", value: "Continue",
                                                      comment: "Button after the admin PIN is saved. Shows the Guided Access offer.")
        static let offerTitle = NSLocalizedString("pos.adminPINOnboarding.guidedAccess.title", value: "Keep your device on POS",
                                                  comment: "Title of the optional Guided Access offer after admin PIN setup.")
        static let offerMessage = NSLocalizedString("pos.adminPINOnboarding.guidedAccess.message",
                                                    value: "Enable Guided Access to prevent users from switching to other apps.",
                                                    comment: "Explains the optional iOS Guided Access feature after admin PIN setup.")
        static let setUpGuidedAccess = NSLocalizedString("pos.adminPINOnboarding.guidedAccess.setUp", value: "Set up Guided Access",
                                                         comment: "Button that starts setting up iOS Guided Access.")
        static let maybeLater = NSLocalizedString("pos.adminPINOnboarding.guidedAccess.maybeLater", value: "Maybe later",
                                                  comment: "Button that skips the Guided Access offer and returns to Security.")
        static let back = NSLocalizedString("pos.adminPINOnboarding.back", value: "Back",
                                            comment: "Accessibility label of the button that returns to choosing the admin PIN.")
        static let close = NSLocalizedString("pos.adminPINOnboarding.close", value: "Close",
                                             comment: "Accessibility label of the button that closes admin PIN setup.")
    }
}

#if DEBUG
#Preview("Set up access control") {
    POSAccessControlSetupView(onGetStarted: {})
        .background(Color.posSurface)
}
#endif

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

struct POSPINSetupFlowView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posModalDismissAction) private var dismissModal
    @Environment(\.isPOSModalFullScreenFlow) private var isFullScreenFlow
    private let flow: POSPINSetupFlow
    @State private var pinContentHeightAboveKeypad: CGFloat = 0
    private let controller: POSSecuritySettingsController
    private let close: () -> Void
    private let setUpGuidedAccess: () -> Void

    init(flow: POSPINSetupFlow,
         controller: POSSecuritySettingsController,
         close: @escaping () -> Void,
         setUpGuidedAccess: @escaping () -> Void) {
        self.controller = controller
        self.close = close
        self.setUpGuidedAccess = setUpGuidedAccess
        self.flow = flow
    }

    var body: some View {
        VStack(spacing: metrics.spacing.medium) {
            if !isFullScreenFlow && flow.step != .saving {
                header
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .posModalFlowBackAction(enabled: isFullScreenFlow && flow.canGoBack) { flow.goBack() }
        .posModalSizing(fillsAvailableSpace: usesAccessibilityFullScreen)
        .posModalFullScreen(usesAccessibilityFullScreen)
        .posInteractiveDismissDisabled(flow.step == .saving || !flow.canClose)
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible {
                dismissModal?()
            }
        }
        .onChange(of: flow.feedback) { _, feedback in
            if let feedback {
                AccessibilityNotification.Announcement(message(for: feedback)).post()
            }
        }
        .onDisappear { flow.discard() }
        .accessibilityIdentifier("pos-pin-setup")
    }
}

private extension POSPINSetupFlowView {
    var usesAccessibilityFullScreen: Bool {
        horizontalSizeClass == .regular && dynamicTypeSize.isAccessibilitySize
    }

    var showsContentTitle: Bool {
        isFullScreenFlow || usesAccessibilityFullScreen
    }

    var title: String {
        switch flow.step {
        case .choose: flow.configuration.copy.chooseTitle
        case .confirm: flow.configuration.copy.confirmTitle
        case .saving, .saved, .guidedAccessOffer: ""
        }
    }

    var header: some View {
        ZStack {
            if !showsContentTitle && !title.isEmpty {
                Text(title)
                    .font(.posBodyXLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, POSHeaderLayoutConstants.compactBackButtonSize)
            }
            HStack {
                if flow.canGoBack {
                    POSPageHeaderBackButton(configuration: .init(state: .enabled,
                                                                 action: { flow.goBack() },
                                                                 accessibilityLabel: Localization.back))
                }
                Spacer()
                POSPageHeaderBackButton(configuration: .init(state: flow.canClose ? .enabled : .disabled,
                                                             action: closeFlow,
                                                             buttonIcon: "xmark",
                                                             accessibilityIdentifier: "pos-pin-setup-close",
                                                             accessibilityLabel: Localization.close))
            }
        }
        .frame(minHeight: POSHeaderLayoutConstants.compactBackButtonSize)
    }

    @ViewBuilder
    var content: some View {
        switch flow.step {
        case .choose, .confirm:
            pinEntry
        case .saving:
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
        case .saved:
            messagePage(art: savedCheck, title: flow.configuration.copy.savedTitle, message: flow.configuration.copy.savedMessage) {
                Button(flow.configuration.successAction.title) {
                    if flow.continueFromSuccess() { closeFlow() }
                }
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
            .transition(.opacity.animation(Constants.offerFade))
        case .guidedAccessOffer:
            messagePage(art: POSLockIllustration(), title: Localization.offerTitle, message: Localization.offerMessage) {
                Button(Localization.setUpGuidedAccess) {
                    if flow.close() { setUpGuidedAccess() }
                }
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
            let verticalInset = min(metrics.padding.xLarge, max(0, (geometry.size.height - keypadHeight - pinContentHeightAboveKeypad) / 2))
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: pinTitleSpacing) {
                        if showsContentTitle {
                            pinEntryTitle
                        }
                        POSPINEntryView(state: flow.pinEntryState,
                                        style: .setup(keySize: keySize, page: page,
                                                      feedback: flow.feedback.map(message(for:)),
                                                      feedbackMessages: feedbackMessages),
                                        onComplete: { pin in await flow.submit(pin) })
                    }
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self, of: { max(0, $0.size.height - keypadHeight) }) {
                            pinContentHeightAboveKeypad = $0
                        }
                        .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 2 * verticalInset))
                        .id(Constants.pinEntryTopID)
                }
                .contentMargins(.vertical, verticalInset, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: flow.pageID) { proxy.scrollTo(Constants.pinEntryTopID, anchor: .top) }
                .onChange(of: flow.feedback) { _, feedback in
                    if feedback != nil {
                        proxy.scrollTo(Constants.pinEntryTopID, anchor: .top)
                    }
                }
            }
        }
        .clipped()
    }

    var pinTitleSpacing: CGFloat {
        // Standard-size errors raise the dots; leave room for that existing movement below the title.
        dynamicTypeSize.isAccessibilitySize ? metrics.spacing.xLarge : metrics.spacing.xxLarge + metrics.spacing.large
    }

    var feedbackMessages: [String] {
        [POSPINSetupFlow.Feedback.mismatch, .failure(.pinMatchesOtherRole), .failure(.storageFailure)].map(message(for:))
    }

    var pinEntryTitle: some View {
        // Reserve both titles so wrapping cannot move the dots or keypad between steps.
        ZStack {
            Text(flow.configuration.copy.chooseTitle).hidden()
            Text(flow.configuration.copy.confirmTitle).hidden()
            Text(title)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("pos-pin-setup-title")
        }
        .font(.posBodyXLargeBold)
        .foregroundStyle(Color.posOnSurface)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .transaction { $0.animation = nil }
    }

    var savedCheck: some View {
        PointOfSaleAssets.checkCircle.decorativeImage
            .resizable()
            .scaledToFit()
            .frame(width: Constants.checkSize, height: Constants.checkSize)
    }

    var page: POSPINEntryPage {
        POSPINEntryPage(id: flow.pageID, edge: flow.step == .confirm ? .trailing : .leading)
    }

    func keySize(fitting size: CGSize) -> CGFloat {
        POSPINEntryViewHelper.lockScreenKeySize(fitting: CGSize(width: size.width, height: size.height - pinContentHeightAboveKeypad),
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

    func message(for feedback: POSPINSetupFlow.Feedback) -> String {
        switch feedback {
        case .mismatch: POSSecuritySettingsView.Localization.mismatch
        case .failure(.pinMatchesOtherRole): POSSecuritySettingsView.Localization.distinctPINs
        case .failure: POSSecuritySettingsView.Localization.storageError
        }
    }

    func closeFlow() {
        if flow.close() {
            close()
        }
    }

    enum Constants {
        static let pinEntryTopID = "pin-entry-top"
        static let regularKeySize: CGFloat = 90
        static let compactKeySize: CGFloat = 72
        static let checkSize: CGFloat = 80
        static let messageMaxWidth: CGFloat = 470
        static let offerFadeDuration: TimeInterval = 0.3
        static let offerFade: Animation = .easeInOut(duration: offerFadeDuration)
    }

    enum Localization {
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

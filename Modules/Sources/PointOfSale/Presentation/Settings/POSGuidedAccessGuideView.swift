import SwiftUI

struct POSGuidedAccessGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.isPOSModalFullScreenFlow) private var isFullScreenFlow
    private let guide: POSGuidedAccessGuide
    private let close: () -> Void

    init(guide: POSGuidedAccessGuide, close: @escaping () -> Void) {
        self.guide = guide
        self.close = close
    }

    var body: some View {
        let content = VStack(spacing: metrics.spacing.medium) {
            if !isFullScreenFlow {
                header
            }
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: metrics.spacing.medium) {
                        slideContent
                        actionButton
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ViewThatFits(in: .vertical) {
                    VStack(spacing: metrics.spacing.medium) {
                        slideContent.frame(maxHeight: .infinity)
                        actionButton
                    }
                    ScrollView {
                        VStack(spacing: metrics.spacing.medium) {
                            slideContent
                            actionButton
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        Group {
            if isFullScreenFlow || usesAccessibilityFullScreen {
                content.posModalSizing(fillsAvailableSpace: usesAccessibilityFullScreen)
            } else {
                content
                    .padding(metrics.padding.xxLarge)
                    .frame(width: min(Constants.cardSize.width, parentSize.width),
                           height: max(0, min(Constants.cardSize.height, parentSize.height - 2 * metrics.padding.medium)))
            }
        }
        .posModalFullScreen(usesAccessibilityFullScreen)
        .posModalFlowHeaderTitle(Localization.title)
        .posModalFlowBackAction(enabled: isFullScreenFlow && slide.previous != nil) { show(slide.previous) }
        .accessibilityIdentifier("pos-guided-access-guide")
    }
}

private extension POSGuidedAccessGuideView {
    var slide: POSGuidedAccessGuideSlide { guide.slide }

    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var usesAccessibilityFullScreen: Bool {
        !isCompact && dynamicTypeSize.isAccessibilitySize
    }

    var header: some View {
        ZStack {
            Text(Localization.title)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Constants.arrowSize)
            HStack {
                Spacer()
                POSPageHeaderBackButton(configuration: .init(state: .enabled,
                                                             action: close,
                                                             buttonIcon: "xmark",
                                                             accessibilityIdentifier: "pos-guided-access-guide-close",
                                                             accessibilityLabel: Localization.close))
            }
        }
        .frame(minHeight: Constants.arrowSize)
    }

    /// One illustration follows the slides, so swipes change the slide instead of paging separate views.
    var slideContent: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            // Phones have no room beside the illustration, so their arrows sit next to the page indicator.
            HStack(spacing: metrics.spacing.none) {
                if !isCompact {
                    arrow(to: slide.previous, icon: "arrow.backward", label: Localization.previous)
                    Spacer(minLength: metrics.spacing.none)
                }
                illustration
                if !isCompact {
                    Spacer(minLength: metrics.spacing.none)
                    arrow(to: slide.next, icon: "arrow.forward", label: Localization.next)
                }
            }
            HStack(spacing: metrics.spacing.medium) {
                if isCompact {
                    arrow(to: slide.previous, icon: "arrow.backward", label: Localization.previous)
                }
                pageIndicator
                if isCompact {
                    arrow(to: slide.next, icon: "arrow.forward", label: Localization.next)
                }
            }
            caption
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: Constants.swipeDistance).onEnded(swipe))
    }

    @ViewBuilder
    var illustration: some View {
        let device = Self.illustrationDevice(idiom: UIDevice.current.userInterfaceIdiom, isCompact: isCompact, parentSize: parentSize)
        let size = POSGuidedAccessIllustration.size(for: device)
        let drawing = POSGuidedAccessIllustration(slide: slide, device: device).id(device)
        if !isCompact {
            let width = max(0, min(Constants.illustrationAreaSize.width, parentSize.width - 2 * metrics.padding.xxLarge - 2 * Constants.arrowSize))
            let scale = min(1, width / size.width)
            drawing.scaleEffect(scale).frame(width: width, height: Constants.illustrationAreaSize.height * scale)
        } else if dynamicTypeSize.isAccessibilitySize {
            // The scroll view of large text sizes has no height to fit, so only the width limits the drawing.
            let scale = min(1, max(0, parentSize.width - 2 * metrics.padding.xxLarge) / size.width)
            drawing.scaleEffect(scale).frame(width: size.width * scale, height: size.height * scale)
        } else {
            GeometryReader { proxy in
                let scale = min(Constants.maximumCompactScale, proxy.size.width / size.width, proxy.size.height / size.height)
                drawing.scaleEffect(scale).frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(minHeight: Constants.minimumIllustrationHeight)
        }
    }

    var pageIndicator: some View {
        HStack(spacing: metrics.spacing.small) {
            ForEach(POSGuidedAccessGuideSlide.allCases, id: \.self) { page in
                Capsule()
                    .fill(page == slide ? Color.posOnSurfaceVariantHighest : .clear)
                    .strokeBorder(page == slide ? .clear : Color.posOutline)
                    .frame(width: page == slide ? Constants.activeDotWidth : Constants.dotSize, height: Constants.dotSize)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(String.localizedStringWithFormat(Localization.step, slide.rawValue + 1, POSGuidedAccessGuideSlide.allCases.count))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: show(slide.next)
            case .decrement: show(slide.previous)
            @unknown default: break
            }
        }
    }

    var caption: some View {
        // Reserve every caption so the layout keeps its height between slides.
        ZStack {
            ForEach(POSGuidedAccessGuideSlide.allCases, id: \.self) { page in
                Text(Self.caption(for: page))
                    .opacity(page == slide ? 1 : 0)
                    .accessibilityHidden(page != slide)
            }
        }
        .font(.posBodyMediumRegular())
        .foregroundStyle(Color.posOnSurface)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    var actionButton: some View {
        switch slide.action {
        case .openSettings:
            VStack(spacing: metrics.spacing.small) {
                Text(Localization.settingsDestination)
                    .font(.posCaptionRegular)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(Localization.openSettings, action: openSettings)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    .accessibilityIdentifier("pos-guided-access-open-settings")
            }
        case .done:
            Button(Localization.done, action: close)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .accessibilityIdentifier("pos-guided-access-done")
        }
    }

    func arrow(to target: POSGuidedAccessGuideSlide?, icon: String, label: String) -> some View {
        Button(action: { show(target) }, label: {
            Text(Image(systemName: icon))
                .font(.posButtonSymbolLarge)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.arrowSize, height: Constants.arrowSize)
                .contentShape(Rectangle())
        })
        .accessibilityLabel(label)
        .opacity(target == nil ? 0 : 1)
        .disabled(target == nil)
        .accessibilityHidden(target == nil)
    }

    func show(_ target: POSGuidedAccessGuideSlide?) {
        guard let target else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: Constants.slideDuration)) {
            guide.slide = target
        }
    }

    func swipe(_ drag: DragGesture.Value) {
        guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
        let movesForward = (drag.translation.width < 0) == (layoutDirection == .leftToRight)
        show(movesForward ? slide.next : slide.previous)
    }

    func openSettings() {
        // The public Settings URL requires manual navigation to Accessibility.
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        guide.isVisitingSettings = true
        Task {
            if await UIApplication.shared.open(url) == false {
                guide.isVisitingSettings = false
            }
        }
    }

    static func caption(for slide: POSGuidedAccessGuideSlide) -> String {
        switch slide {
        case .openSettings: Localization.openSettingsCaption
        case .turnOn: Localization.turnOnCaption
        case .start: Localization.startCaption
        }
    }

    enum Constants {
        static let cardSize = CGSize(width: 721, height: 720)
        static let illustrationAreaSize = CGSize(width: 447, height: 320)
        static let maximumCompactScale: CGFloat = 1.25
        static let minimumIllustrationHeight: CGFloat = 180
        static let arrowSize = POSHeaderLayoutConstants.compactBackButtonSize
        static let dotSize: CGFloat = 10
        static let activeDotWidth: CGFloat = 40
        static let swipeDistance: CGFloat = 24
        static let slideDuration: TimeInterval = 0.35
    }
}

extension POSGuidedAccessGuideView {
    /// A phone in compact width shows itself, in the proportions of its screen. Regular width is a tablet or an unfolded
    /// iPhone Duo, where split views show both columns, and a tablet in compact width is still a tablet.
    static func illustrationDevice(idiom: UIUserInterfaceIdiom, isCompact: Bool, parentSize: CGSize) -> POSGuidedAccessIllustration.Device {
        guard idiom == .phone, isCompact, parentSize.width > 0 else { return .pad }
        return .phone(heightRatio: parentSize.height / parentSize.width)
    }

    enum Localization {
        static let title = NSLocalizedString("pos.guidedAccessGuide.title", value: "Set up Guided Access",
                                             comment: "Title of the guide that explains how to turn on iOS Guided Access.")
        static let openSettingsCaption = NSLocalizedString("pos.guidedAccessGuide.settingsPath.caption",
                                                           value: "In Settings, go to Accessibility → Guided Access.",
                                                           comment: "First step of the Guided Access guide. Names the path in the iOS Settings app.")
        static let turnOnCaption = NSLocalizedString("pos.guidedAccessGuide.separatePasscode.caption",
                                                     value: "Turn on Guided Access and set its passcode. This is separate from your POS PIN.",
                                                     comment: "Second step of the Guided Access guide.")
        static let startCaption = NSLocalizedString("pos.guidedAccessGuide.startSession.caption",
                                                    value: "Return to POS. Triple-click the side, top, or Home button, " +
                                                           "choose Guided Access if asked, then tap Start.",
                                                    comment: "Last step of the Guided Access guide.")
        static let openSettings = NSLocalizedString("pos.guidedAccessGuide.openSettings", value: "Open Settings",
                                                    comment: "Button in the Guided Access guide that opens the iOS Settings app.")
        static let settingsDestination = NSLocalizedString("pos.guidedAccessGuide.settingsDestinationHint",
                                                            value: "Opens Settings. Go back to the main screen if needed.",
                                                            comment: "Explains that Settings may open this app's page, requiring Back navigation first.")
        static let done = NSLocalizedString("pos.guidedAccessGuide.done", value: "Done", comment: "Button that closes the Guided Access guide.")
        static let close = NSLocalizedString("pos.guidedAccessGuide.close", value: "Close",
                                             comment: "Accessibility label of the button that closes the Guided Access guide.")
        static let previous = NSLocalizedString("pos.guidedAccessGuide.previous", value: "Previous step",
                                                comment: "Accessibility label of the arrow that shows the previous step of the Guided Access guide.")
        static let next = NSLocalizedString("pos.guidedAccessGuide.next", value: "Next step",
                                            comment: "Accessibility label of the arrow that shows the next step of the Guided Access guide.")
        static let step = NSLocalizedString("pos.guidedAccessGuide.step", value: "Step %1$d of %2$d",
                                            comment: "Accessibility label of the page indicator in the Guided Access guide. " +
                                            "%1$d is the current step and %2$d is the number of steps.")
    }
}

#if DEBUG
#Preview("Guide on iPad", traits: .landscapeLeft) {
    POSGuidedAccessGuideView(guide: POSGuidedAccessGuide(), close: {})
        .background(Color.posSurfaceBright)
        .posPreviewModalParentSize()
        .environmentObject(POSModalManager())
}

#Preview("Last slide on phone, dark") {
    POSGuidedAccessGuideView(guide: POSGuidedAccessGuide(slide: .start), close: {})
        .posPreviewSmallestPhone()
        .background(Color.posSurfaceBright)
        .environmentObject(POSModalManager())
        .preferredColorScheme(.dark)
}
#endif

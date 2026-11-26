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
                        slideContent(reservingCaptionHeight: false)
                        actionButton(reservingHeight: false)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                ViewThatFits(in: .vertical) {
                    VStack(spacing: metrics.spacing.medium) {
                        slideContent(reservingCaptionHeight: true).frame(maxHeight: .infinity)
                        actionButton(reservingHeight: true)
                    }
                    ScrollView {
                        VStack(spacing: metrics.spacing.medium) {
                            slideContent(reservingCaptionHeight: false)
                            actionButton(reservingHeight: false)
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        content
            .posModalSizing(fillsAvailableSpace: usesAccessibilityFullScreen)
            .posModalFullScreen(usesAccessibilityFullScreen)
            .posModalFlowHeaderTitle(Localization.title)
            .accessibilityIdentifier("pos-guided-access-guide")
    }
}

private extension POSGuidedAccessGuideView {
    var slide: POSGuidedAccessGuideSlide {
        guide.slide
    }

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
    func slideContent(reservingCaptionHeight: Bool) -> some View {
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
            caption(reservingHeight: reservingCaptionHeight)
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
        if dynamicTypeSize.isAccessibilitySize {
            // The scroll view of large text sizes has no height to fit, so only the width limits the drawing.
            let arrowsWidth = isCompact ? 0 : 2 * Constants.arrowSize
            let availableWidth = max(0, parentSize.width - 2 * metrics.padding.xxLarge - arrowsWidth)
            let width = isCompact ? availableWidth : min(Constants.illustrationAreaSize.width, availableWidth)
            let scale = min(1, width / size.width)
            drawing.scaleEffect(scale).frame(width: size.width * scale, height: size.height * scale)
        } else {
            GeometryReader { proxy in
                let maximumScale = isCompact ? Constants.maximumCompactScale : 1
                let scale = min(maximumScale, proxy.size.width / size.width, proxy.size.height / size.height)
                drawing.scaleEffect(scale).frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(maxWidth: isCompact ? .infinity : Constants.illustrationAreaSize.width,
                   minHeight: Constants.minimumIllustrationHeight,
                   maxHeight: isCompact ? .infinity : Constants.illustrationAreaSize.height)
        }
    }

    var pageIndicator: some View {
        POSPageIndicator(pageCount: POSGuidedAccessGuideSlide.allCases.count,
                         currentPage: Binding(get: { slide.rawValue }, set: { show(POSGuidedAccessGuideSlide(rawValue: $0)) }))
    }

    func caption(reservingHeight: Bool) -> some View {
        Group {
            if reservingHeight {
                // Fixed layouts keep their height between slides; scrolling layouts need only the active text.
                ZStack {
                    ForEach(POSGuidedAccessGuideSlide.allCases, id: \.self) { page in
                        Text(Self.caption(for: page))
                            .opacity(page == slide ? 1 : 0)
                            .accessibilityHidden(page != slide)
                    }
                }
            } else {
                Text(Self.caption(for: slide))
            }
        }
        .font(.posBodyMediumRegular())
        .foregroundStyle(Color.posOnSurface)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    func actionButton(reservingHeight: Bool) -> some View {
        let showsSettingsAction = slide.action == .openSettings
        return VStack(spacing: metrics.spacing.small) {
            if reservingHeight || showsSettingsAction {
                Text(Localization.settingsDestination)
                    .font(.posCaptionRegular)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showsSettingsAction ? 1 : 0)
                    .accessibilityHidden(!showsSettingsAction)
            }
            // Fixed layouts reserve both actions so Done cannot resize the illustration above them.
            ZStack {
                if reservingHeight || showsSettingsAction {
                    Button(Localization.openSettings, action: openSettings)
                        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                        .accessibilityIdentifier("pos-guided-access-open-settings")
                        .opacity(showsSettingsAction ? 1 : 0)
                        .allowsHitTesting(showsSettingsAction)
                        .accessibilityHidden(!showsSettingsAction)
                }
                if reservingHeight || !showsSettingsAction {
                    Button(Localization.done, action: close)
                        .buttonStyle(POSFilledButtonStyle(size: .normal))
                        .accessibilityIdentifier("pos-guided-access-done")
                        .opacity(showsSettingsAction ? 0 : 1)
                        .allowsHitTesting(!showsSettingsAction)
                        .accessibilityHidden(showsSettingsAction)
                }
            }
        }
    }

    func arrow(to target: POSGuidedAccessGuideSlide?, icon: String, label: String) -> some View {
        Button(action: {
            show(target)
        }, label: {
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
        guard let target else {
            return
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: Constants.slideDuration)) {
            guide.slide = target
        }
    }

    func swipe(_ drag: DragGesture.Value) {
        guard abs(drag.translation.width) > abs(drag.translation.height) else {
            return
        }
        let movesForward = (drag.translation.width < 0) == (layoutDirection == .leftToRight)
        show(movesForward ? slide.next : slide.previous)
    }

    func openSettings() {
        // The public Settings URL requires manual navigation to Accessibility.
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }

    static func caption(for slide: POSGuidedAccessGuideSlide) -> String {
        switch slide {
        case .openSettings: Localization.openSettingsCaption
        case .turnOn: Localization.turnOnCaption
        case .start: Localization.startCaption
        }
    }

    enum Constants {
        static let illustrationAreaSize = CGSize(width: 447, height: 320)
        static let maximumCompactScale: CGFloat = 1.25
        static let minimumIllustrationHeight: CGFloat = 180
        static let arrowSize = POSHeaderLayoutConstants.compactBackButtonSize
        static let swipeDistance: CGFloat = 24
        static let slideDuration: TimeInterval = 0.35
    }
}

extension POSGuidedAccessGuideView {
    /// A phone in compact width shows itself, in the proportions of its screen. Regular width is a tablet or an unfolded
    /// iPhone Duo, where split views show both columns, and a tablet in compact width is still a tablet.
    private static func illustrationDevice(idiom: UIUserInterfaceIdiom, isCompact: Bool, parentSize: CGSize) -> POSGuidedAccessIllustration.Device {
        guard idiom == .phone, isCompact, parentSize.width > 0 else {
            return .pad
        }
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
    }
}

#if DEBUG
#Preview("Guide on iPad", traits: .landscapeLeft) {
    POSGuidedAccessGuideView(guide: POSGuidedAccessGuide(), close: {
    })
        .background(Color.posSurfaceBright)
        .posPreviewModalParentSize()
        .environmentObject(POSModalManager())
}

#Preview("Last slide on phone, dark") {
    POSGuidedAccessGuideView(guide: POSGuidedAccessGuide(slide: .start), close: {
    })
        .posPreviewSmallestPhone()
        .background(Color.posSurfaceBright)
        .environmentObject(POSModalManager())
        .preferredColorScheme(.dark)
}
#endif

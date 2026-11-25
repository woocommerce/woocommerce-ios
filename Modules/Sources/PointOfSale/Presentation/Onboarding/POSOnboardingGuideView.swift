import SwiftUI
import WooFoundation

/// Full-screen guide shown on iPhone when POS opens, until the merchant taps Enter POS.
/// It has no close button: the merchant either enters or exits POS.
struct POSOnboardingGuideView: View {
    @Environment(\.posMetrics) private var metrics
    @State private var isShowingVideo = false

    @Binding var currentStep: POSOnboardingGuideStep
    let onStartSelling: () -> Void
    let onExit: () -> Void
    let onWatchVideo: () -> Void

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            ViewThatFits(in: .vertical) {
                // Reserve every step's height, so the dots below keep their place between steps.
                ZStack(alignment: .top) {
                    ForEach(POSOnboardingGuideStep.allCases) { step in
                        POSOnboardingGuideStepView(step: step, onWatchVideo: {})
                    }
                }
                .hidden()
                .accessibilityHidden(true)
                .overlay {
                    pager(scrollsSteps: false)
                }

                // When the steps don't fit (landscape, large text), each one scrolls above the dots.
                pager(scrollsSteps: true)
                    // Matches the steps' bottom padding, so clipped content doesn't run into the dots.
                    .posPadding(.bottom, \.medium)
            }
            .layoutPriority(1)

            POSPageIndicator(pageCount: POSOnboardingGuideStep.allCases.count,
                             currentPage: currentPage,
                             accessibilityPageName: { POSOnboardingGuideStep.allCases[$0].title })
            Spacer(minLength: metrics.spacing.none)

            POSFlowButtonsView(configuration: buttonConfiguration)
                .posStatusButtonsWidth(addsHorizontalPadding: false)
                .posPhoneBottomButtonPadding()
        }
        .background(Color.posSurface.ignoresSafeArea())
        .interactiveDismissDisabled()
        .posFullScreenCover(isPresented: $isShowingVideo) {
            SafariView(url: POSConstants.URLs.pointOfSaleSaleVideo.asURL())
        }
    }

    private func pager(scrollsSteps: Bool) -> some View {
        TabView(selection: $currentStep) {
            ForEach(POSOnboardingGuideStep.allCases) { step in
                let stepView = POSOnboardingGuideStepView(step: step, onWatchVideo: watchVideo)
                Group {
                    if scrollsSteps {
                        ScrollView {
                            stepView
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .scrollIndicatorsFlash(onAppear: true)
                        // Fading the edge keeps a clipped card from reading as a strip.
                        .mask {
                            VStack(spacing: metrics.spacing.none) {
                                Color.black
                                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: metrics.padding.xLarge)
                            }
                        }
                    } else {
                        stepView
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .tag(step)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var currentPage: Binding<Int> {
        Binding(get: { currentStep.rawValue },
                set: { page in
                    // The indicator only sets pages within `pageCount`.
                    if let step = POSOnboardingGuideStep(rawValue: page) {
                        currentStep = step
                    }
                })
    }

    private func watchVideo() {
        onWatchVideo()
        isShowingVideo = true
    }

    private var buttonConfiguration: PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: .init(title: Localization.startSelling,
                                   accessibilityIdentifier: "pos-onboarding-guide-start-selling-button",
                                   action: onStartSelling),
              secondaryButton: .init(title: Localization.exit,
                                     accessibilityIdentifier: "pos-onboarding-guide-exit-button",
                                     action: onExit))
    }
}

private struct POSOnboardingGuideStepView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let step: POSOnboardingGuideStep
    let onWatchVideo: () -> Void

    private static let illustrationSize: CGFloat = 140

    var body: some View {
        // In landscape, tighter spacing lets the last step fit above the buttons on larger phones.
        VStack(spacing: verticalSizeClass == .compact ? metrics.spacing.medium : metrics.spacing.xLarge) {
            // In landscape and with accessibility text sizes, the illustration would leave little room for the text.
            if verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize {
                step.illustration.decorativeImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.illustrationSize, height: Self.illustrationSize)
            }

            VStack(spacing: metrics.spacing.small) {
                Text(step.title)
                    .font(.posBodyXLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                if let message = step.message {
                    Text(message)
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }
            .multilineTextAlignment(.center)

            if step == .howASaleWorks {
                POSOnboardingGuideSaleSteps()
                POSOnboardingGuideVideoCard(action: onWatchVideo)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        // Same column as the buttons, so the content is centred on their axis.
        .posStatusButtonsWidth()
        .posPadding(.vertical, \.medium)
    }
}

/// Add products › Check out › Get paid. With accessibility text sizes the labels don't fit side by side, so the steps stack.
private struct POSOnboardingGuideSaleSteps: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var tileSize = POSOnboardingGuideSaleStepTile.baseSize

    var body: some View {
        let stacks = dynamicTypeSize.isAccessibilitySize
        let rowLayout = stacks ? AnyLayout(VStackLayout(alignment: .leading, spacing: metrics.spacing.medium))
                               : AnyLayout(HStackLayout(alignment: .top, spacing: metrics.spacing.small))
        let itemLayout = stacks ? AnyLayout(HStackLayout(spacing: metrics.spacing.medium))
                                : AnyLayout(VStackLayout(spacing: metrics.spacing.small))
        rowLayout {
            ForEach(Array(POSOnboardingGuideStep.saleSteps.enumerated()), id: \.offset) { index, saleStep in
                if index > 0 && !stacks {
                    Image(systemName: "chevron.forward")
                        .font(.posBodySmallBold())
                        .foregroundStyle(Color.posOnSurfaceVariantLowest)
                        .frame(height: tileSize)
                        .accessibilityHidden(true)
                }
                itemLayout {
                    POSOnboardingGuideSaleStepTile(systemImage: saleStep.systemImage)
                        // Larger tiles would push the row off the screen.
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    Text(saleStep.label)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct POSOnboardingGuideSaleStepTile: View {
    static let baseSize: CGFloat = 64
    @ScaledMetric private var size = Self.baseSize

    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.posButtonSymbolLarge)
            .foregroundStyle(Color.posPrimary)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value).fill(Color.posSecondary))
            .accessibilityHidden(true)
    }
}

private struct POSOnboardingGuideVideoCard: View {
    @Environment(\.posMetrics) private var metrics

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: metrics.spacing.medium) {
                Image(systemName: "play.circle.fill")
                    .font(.posButtonSymbolLarge)
                    .foregroundStyle(Color.posPrimary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                    Text(Localization.title)
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)
                    Text(Localization.subtitle)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: metrics.spacing.none)
            }
            .posPadding(\.medium)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "pos.onboardingGuide.video.title",
            value: "Watch a sale in action",
            comment: "Title of the card on the last step of the POS onboarding guide that opens a video of a sale."
        )
        static let subtitle = NSLocalizedString(
            "pos.onboardingGuide.video.subtitle",
            value: "Short video, from cart to payment",
            comment: "Subtitle of the card on the last step of the POS onboarding guide that opens a video of a sale."
        )
    }
}

private extension POSOnboardingGuideView {
    enum Localization {
        static let startSelling = NSLocalizedString(
            "pos.onboardingGuide.enterPOSButton",
            value: "Enter POS",
            comment: "Primary button in the POS onboarding guide. Closes the guide and opens POS."
        )
        static let exit = NSLocalizedString(
            "pos.onboardingGuide.exitButton",
            value: "Exit POS",
            comment: "Secondary button in the POS onboarding guide. Leaves POS."
        )
    }
}

#if DEBUG
private struct POSOnboardingGuidePreview: View {
    @State var currentStep: POSOnboardingGuideStep

    var body: some View {
        POSOnboardingGuideView(currentStep: $currentStep, onStartSelling: {}, onExit: {}, onWatchVideo: {})
            .posPreviewSmallestPhone()
            .environmentObject(POSFullScreenCoverManager())
    }
}

#Preview("Step 1") {
    POSOnboardingGuidePreview(currentStep: .checkout)
}

#Preview("Step 3, dark") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text") {
    POSOnboardingGuidePreview(currentStep: .howASaleWorks)
        .dynamicTypeSize(.accessibility3)
}
#endif

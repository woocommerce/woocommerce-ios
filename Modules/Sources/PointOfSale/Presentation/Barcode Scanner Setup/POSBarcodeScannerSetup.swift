import SwiftUI

struct POSBarcodeScannerSetup: View {
    @Binding var isPresented: Bool
    @State private var flowManager: PointOfSaleBarcodeScannerSetupFlowManager
    @Environment(\.posModalParentSize) var parentSize
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(isPresented: Binding<Bool>, analytics: POSAnalyticsProviding) {
        self._isPresented = isPresented
        self.flowManager = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: isPresented, analytics: analytics)
    }

    /// On phone the modal is taken to full screen to avoid the cramped iPad-tuned card.
    private var isCompactWidth: Bool { horizontalSizeClass == .compact }
    private var widthRatio: CGFloat { isCompactWidth ? 1.0 : Constants.parentWidthRatio }
    private var heightRatio: CGFloat { isCompactWidth ? 1.0 : Constants.maxParentHeightRatio }

    var body: some View {
        AnimatedTransitionContainer(
            maxWidth: parentSize.width * widthRatio,
            maxHeight: parentSize.height * heightRatio,
            id: flowManager.currentStepKey
        ) {
            VStack(spacing: POSSpacing.xLarge) {
                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer()
                        currentContent
                        Spacer()
                    }
                }
                .scrollBounceBehavior(.basedOnSize, axes: [.vertical])

                // Bottom buttons
                if flowManager.buttonConfiguration.primaryButton != nil || flowManager.buttonConfiguration.secondaryButton != nil {
                    PointOfSaleFlowButtonsView(configuration: flowManager.buttonConfiguration)
                }
            }
            .posModalCloseButton(action: {
                isPresented = false
            })
            .padding(POSPadding.xLarge)
            .background(Color.posSurfaceBright)
        }
        .onAppear {
            analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
        .onDisappear {
            flowManager.onDisappear()
        }
        .maximumScreenBrightness()
        .posModalFullScreen(isCompactWidth)
    }

    // MARK: - Computed Properties
    @ViewBuilder
    private var currentContent: some View {
        switch flowManager.currentState {
        case .scannerSelection:
            PointOfSaleBarcodeScannerSetupSelectionView(options: scannerOptions) { scannerType in
                flowManager.selectScanner(scannerType)
            }
        case .setupFlow:
            if let step = flowManager.getCurrentStep() {
                AnyView(step.content)
            }
        }
    }

    private var scannerOptions: [PointOfSaleBarcodeScannerSetupFlowOption] {
        [
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.starBSH20BTitle,
                scannerType: .starBSH20B
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.tera12002DTitle,
                scannerType: .tera12002D
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.netum1228BCTitle,
                scannerType: .netum1228BC
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.otherTitle,
                scannerType: .other
            )
        ]
    }
}

// MARK: - Constants
private enum Constants {
    static var maxParentHeightRatio: CGFloat { 0.9 }
    static var parentWidthRatio: CGFloat { 0.75 }
}

// MARK: - Private Localization Extension
private extension POSBarcodeScannerSetup {
    enum Localization {
        static let starBSH20BTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.starBSH20B.title",
            value: "Star BSH-20B",
            comment: "Title for Star BSH-20B scanner option in barcode scanner setup"
        )
        static let tera12002DTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.tera12002D.title",
            value: "Tera 1200 2D",
            comment: "Title for Tera 1200 2D scanner option in barcode scanner setup"
        )
        static let netum1228BCTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.netum1228BC.title",
            value: "Netum 1228BC",
            comment: "Title for Netum 1228BC scanner option in barcode scanner setup"
        )
        static let otherTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.other.title",
            value: "Other",
            comment: "Title for other scanner option in barcode scanner setup"
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    POSBarcodeScannerSetup(isPresented: .constant(true), analytics: EmptyPOSAnalytics())
}
#endif

/// A container view that animates changes in its child content with a fade-out and fade-in transition,
/// while also smoothly animating changes in height.
///
/// - On first appear: content shows instantly (no fade).
/// - On content change: fades out old content, replaces it, then fades in new content.
/// - Handles height changes with a spring animation.
///
private struct AnimatedTransitionContainer<Content: View, ID: Equatable>: View {
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let contentID: ID
    let contentBuilder: () -> Content

    @State private var visibleContent: Content
    @State private var previousID: ID
    @State private var animatedHeight: CGFloat = 0
    @State private var isVisible: Bool = true
    @State private var hasAppeared: Bool = false

    private let animationDuration: CGFloat = 0.3

    init(
        maxWidth: CGFloat,
        maxHeight: CGFloat,
        id: ID,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.contentID = id
        self.contentBuilder = content
        self._visibleContent = State(initialValue: content())
        self._previousID = State(initialValue: id)
    }

    var body: some View {
        visibleContent
            .opacity(isVisible ? 1 : 0)
            // First layout pass: constrain content to let scrollView in content to configure itself
            .frame(width: maxWidth)
            .frame(maxHeight: maxHeight)
            .fixedSize(horizontal: false, vertical: true)
            // Measure the actual height after ScrollView has decided if it needs to scroll
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            updateSize(to: proxy.size.height)
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            updateSize(to: newSize.height)
                        }
                }
            )
            // Second layout pass: create animated viewport using measured height
            .frame(width: maxWidth)
            .frame(height: animatedHeight)
            .clipped()
            .onAppear {
                hasAppeared = true
            }
            .onChange(of: contentID) { _, newID in
                guard newID != previousID else { return }

                if hasAppeared {
                    withAnimation(.easeInOut(duration: animationDuration / 2)) {
                        isVisible = false
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 2) {
                        visibleContent = contentBuilder()
                        previousID = newID

                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isVisible = true
                        }
                    }
                } else {
                    // First load, no animation
                    visibleContent = contentBuilder()
                    previousID = newID
                    isVisible = true
                }
            }
    }

    private func updateSize(to newHeight: CGFloat) {
        guard newHeight > 0 else { return }

        withAnimation(.spring(duration: hasAppeared ? animationDuration : 0)) {
            animatedHeight = min(newHeight, maxHeight)
        }
    }
}

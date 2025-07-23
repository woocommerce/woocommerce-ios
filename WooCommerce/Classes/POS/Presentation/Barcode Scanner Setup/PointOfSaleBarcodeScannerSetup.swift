import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetup: View {
    @Binding var isPresented: Bool
    @State private var flowManager: PointOfSaleBarcodeScannerSetupFlowManager
    @Environment(\.posModalParentSize) var parentSize

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.flowManager = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: isPresented)
    }

    var body: some View {
        AnimatedTransitionContainer(
            maxWidth: parentSize.width * Constants.parentWidthRatio,
            maxHeight: parentSize.height * Constants.maxParentHeightRatio,
            id: flowManager.currentStepKey
        ) {
            VStack(spacing: POSSpacing.xxLarge) {
                ScrollView(showsIndicators: false) {
                    currentContent
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
            .padding(POSPadding.xxLarge)
            .background(Color.posSurfaceBright)
        }
        .onAppear {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
        .onDisappear {
            flowManager.onDisappear()
        }
        .maximumScreenBrightness()
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
                title: Localization.socketS720Title,
                scannerType: .socketS720
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.starBSH20BTitle,
                scannerType: .starBSH20B
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.tera12002DTitle,
                scannerType: .tera12002D
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
@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetup {
    enum Localization {
        static let socketS720Title = NSLocalizedString(
            "pos.barcodeScannerSetup.socketS720.title",
            value: "Socket S720",
            comment: "Title for Socket S720 scanner option in barcode scanner setup"
        )
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
        static let otherTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.other.title",
            value: "Other",
            comment: "Title for other scanner option in barcode scanner setup"
        )
    }
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleBarcodeScannerSetup(isPresented: .constant(true))
}

/// A container view that animates changes in its child content with a fade-out and fade-in transition,
/// while also smoothly animating changes in height.
///
/// - On first appear: content shows instantly (no fade).
/// - On content change: fades out old content, replaces it, then fades in new content.
/// - Handles height changes with a spring animation.
///
@available(iOS 17.0, *)
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
            .animation(.easeInOut(duration: animationDuration), value: isVisible)
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
                        .onChange(of: proxy.size) { newSize in
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
            .onChange(of: contentID) { newID in
                guard newID != previousID else { return }

                if hasAppeared {
                    withAnimation {
                        isVisible = false
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        visibleContent = contentBuilder()
                        previousID = newID

                        withAnimation {
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

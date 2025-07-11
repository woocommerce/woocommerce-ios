import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetup: View {
    @Binding var isPresented: Bool
    @State private var flowManager: PointOfSaleBarcodeScannerSetupFlowManager

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.flowManager = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: isPresented)
    }

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            // Header
            PointOfSaleModalHeader(isPresented: $isPresented,
                                   title: .constant(AttributedString(currentTitle)))

            VStack {
                currentContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            }
            .scrollVerticallyIfNeeded()

            // Bottom buttons
            if flowManager.buttonConfiguration.primaryButton != nil || flowManager.buttonConfiguration.secondaryButton != nil {
                PointOfSaleFlowButtonsView(configuration: flowManager.buttonConfiguration)
            }
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .containerRelativeFrame([.horizontal, .vertical]) { length, _ in
            max(length * 0.75, Constants.modalFrameMaxSmallDimension)
        }
        .onAppear {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
    }

    // MARK: - Computed Properties
    private var currentTitle: String {
        switch flowManager.currentState {
        case .scannerSelection:
            return Localization.setupHeading
        case .setupFlow:
            return flowManager.getCurrentStep()?.title ?? Localization.setupHeading
        }
    }

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
                title: Localization.tbcScannerTitle,
                scannerType: .tbcScanner
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
    static var modalFrameMaxSmallDimension: CGFloat { 616 }
}

// MARK: - Private Localization Extension
@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetup {
    enum Localization {
        //TODO: WOOMOB-792
        // Note that "pos.barcodeScannerSetup.heading" was previously sent to translation – don't reuse
        static let setupHeading = "Set up a barcode scanner"

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
        static let tbcScannerTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.tbcScanner.title",
            value: "Scanner TBC",
            comment: "Title for TBC scanner option in barcode scanner setup"
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

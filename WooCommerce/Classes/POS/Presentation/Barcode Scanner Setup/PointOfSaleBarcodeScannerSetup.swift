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
            PointOfSaleFlowButtonsView(configuration: flowManager.buttonConfiguration)
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
                subtitle: Localization.socketS720Subtitle,
                scannerType: .socketS720
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.starBSH20BTitle,
                subtitle: Localization.starBSH20BSubtitle,
                scannerType: .starBSH20B
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.tbcScannerTitle,
                subtitle: Localization.tbcScannerSubtitle,
                scannerType: .tbcScanner
            ),
            PointOfSaleBarcodeScannerSetupFlowOption(
                title: Localization.otherTitle,
                subtitle: Localization.otherSubtitle,
                scannerType: .other
            )
        ]
    }
}

// MARK: - Constants
private enum Constants {
    static var modalFrameMaxSmallDimension: CGFloat { 752 }
}

// MARK: - Private Localization Extension
@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerSetup {
    enum Localization {
        static let setupHeading = NSLocalizedString(
            "pos.barcodeScannerSetup.heading",
            value: "Barcode Scanner Setup",
            comment: "Heading for the barcode scanner setup flow in POS"
        )

        static let socketS720Title = NSLocalizedString(
            "pos.barcodeScannerSetup.socketS720.title",
            value: "Socket S720",
            comment: "Title for Socket S720 scanner option in barcode scanner setup"
        )
        static let socketS720Subtitle = NSLocalizedString(
            "pos.barcodeScannerSetup.socketS720.subtitle",
            value: "Small handheld scanner with a charging dock or stand",
            comment: "Subtitle for Socket S720 scanner option in barcode scanner setup"
        )
        static let starBSH20BTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.starBSH20B.title",
            value: "Star BSH-20B",
            comment: "Title for Star BSH-20B scanner option in barcode scanner setup"
        )
        static let starBSH20BSubtitle = NSLocalizedString(
            "pos.barcodeScannerSetup.starBSH20B.subtitle",
            value: "Ergonomic scanner with a stand",
            comment: "Subtitle for Star BSH-20B scanner option in barcode scanner setup"
        )
        static let tbcScannerTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.tbcScanner.title",
            value: "Scanner TBC",
            comment: "Title for TBC scanner option in barcode scanner setup"
        )
        static let tbcScannerSubtitle = NSLocalizedString(
            "pos.barcodeScannerSetup.tbcScanner.subtitle",
            value: "Recommended scanner",
            comment: "Subtitle for TBC scanner option in barcode scanner setup"
        )
        static let otherTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.other.title",
            value: "Other",
            comment: "Title for other scanner option in barcode scanner setup"
        )
        static let otherSubtitle = NSLocalizedString(
            "pos.barcodeScannerSetup.other.subtitle",
            value: "General scanner setup instructions",
            comment: "Subtitle for other scanner option in barcode scanner setup"
        )
    }
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleBarcodeScannerSetup(isPresented: .constant(true))
}

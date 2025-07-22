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
        .posModalCloseButton(action: {
            isPresented = false
        })
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .containerRelativeFrame([.horizontal, .vertical]) { length, _ in
            max(length * 0.75, Constants.modalFrameMaxSmallDimension)
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
    static var modalFrameMaxSmallDimension: CGFloat { 616 }
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

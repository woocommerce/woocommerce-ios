import SwiftUI

// MARK: - Data Models
struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let scannerType: PointOfSaleBarcodeScannerType
}

enum PointOfSaleBarcodeScannerType {
    case socketS720
    case starBSH20B
    case tbcScanner
    case other
}

// MARK: - Flow State
enum PointOfSaleBarcodeScannerSetupFlowState {
    case scannerSelection
    case setupFlow(PointOfSaleBarcodeScannerType)
}

// MARK: - Step Customization Protocol
@available(iOS 17.0, *)
protocol PointOfSaleBarcodeScannerStepCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
}

// MARK: - Setup Step
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetupStep {
    let title: String
    let content: any View
    let customization: PointOfSaleBarcodeScannerStepCustomization?

    init(
        title: String,
        @ViewBuilder content: () -> any View,
        customization: PointOfSaleBarcodeScannerStepCustomization? = nil
    ) {
        self.title = title
        self.content = content()
        self.customization = customization
    }
}

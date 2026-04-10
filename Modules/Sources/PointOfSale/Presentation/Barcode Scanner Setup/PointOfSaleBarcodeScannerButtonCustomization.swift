import SwiftUI

// MARK: - Button Customization Protocol
protocol PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
}

// MARK: - Transition Types
enum PointOfSaleBarcodeScannerTransitionType: Hashable {
    case next
    case retry
    case back
}

// MARK: - Setup Step
struct PointOfSaleBarcodeScannerSetupStep {
    let content: any View
    let buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization?
    let transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID]

    init(@ViewBuilder content: () -> any View,
         buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization? = nil,
         transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID] = [:]) {
        self.content = content()
        self.buttonCustomization = buttonCustomization
        self.transitions = transitions
    }
}

import SwiftUI

// MARK: - Button Customization Protocol
protocol PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
}

// MARK: - Transition Types
public enum PointOfSaleBarcodeScannerTransitionType: Hashable {
    case next
    case retry
    case back
}

// MARK: - Setup Step
struct PointOfSaleBarcodeScannerSetupStep {
    let title: String
    let content: any View
    let buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization?
    let transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID]

    init(title: String = "",
         @ViewBuilder content: () -> any View,
         buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization? = nil,
         transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerStepID] = [:]) {
        self.title = title
        self.content = content()
        self.buttonCustomization = buttonCustomization
        self.transitions = transitions
    }
}

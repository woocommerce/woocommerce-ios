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

    var name: String {
        switch self {
        case .socketS720:
            return Localization.socketS720Name
        case .starBSH20B:
            return Localization.starBsh20BName
        case .tbcScanner:
            return Localization.tbcScannerName
        case .other:
            return Localization.otherName
        }
    }
}

private extension PointOfSaleBarcodeScannerType {
    //TODO: WOOMOB-792
    enum Localization {
        static let socketS720Name = "Socket S720"
        static let starBsh20BName = "Star BSH-20B"
        static let tbcScannerName = "TBC scanner"
        static let otherName = "Other scanner"
    }
}

// MARK: - Flow State
enum PointOfSaleBarcodeScannerSetupFlowState {
    case scannerSelection
    case setupFlow(PointOfSaleBarcodeScannerType)
}

// MARK: - Button Customization Protocol
@available(iOS 17.0, *)
protocol PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
}

// MARK: - Setup Step
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetupStep {
    let title: String
    let content: any View
    let buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization?

    init(
        title: String = "",
        @ViewBuilder content: () -> any View,
        buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization? = nil
    ) {
        self.title = title
        self.content = content()
        self.buttonCustomization = buttonCustomization
    }
}

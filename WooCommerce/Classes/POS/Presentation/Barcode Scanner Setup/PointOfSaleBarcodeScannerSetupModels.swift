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

    var analyticsName: String {
        switch self {
        case .socketS720:
            return "Socket_S720"
        case .starBSH20B:
            return "Star_BSH_20B"
        case .tbcScanner:
            return "TBC"
        case .other:
            return "other"
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

// MARK: - Step Type
enum PointOfSaleBarcodeScannerSetupStepType {
    case setupBarcode
    case pairing
    case testBarcode
    case complete

    var analyticsValue: String {
        switch self {
        case .setupBarcode:
            return "setup_barcode"
        case .pairing:
            return "pairing"
        case .testBarcode:
            return "test_barcode"
        case .complete:
            return "setup_barcode"
        }
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
    let stepType: PointOfSaleBarcodeScannerSetupStepType

    init(
        title: String = "",
        stepType: PointOfSaleBarcodeScannerSetupStepType,
        @ViewBuilder content: () -> any View,
        buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization? = nil
    ) {
        self.title = title
        self.stepType = stepType
        self.content = content()
        self.buttonCustomization = buttonCustomization
    }
}

// MARK: - Test Barcodes
enum PointOfSaleBarcodeScannerTestBarcode {
    case ean13

    var barcodeAsset: PointOfSaleAssets {
        switch self {
        case .ean13:
            return .testEan13Barcode
        }
    }

    var expectedValue: String {
        switch self {
        case .ean13:
            return "1234567890128"
        }
    }
}

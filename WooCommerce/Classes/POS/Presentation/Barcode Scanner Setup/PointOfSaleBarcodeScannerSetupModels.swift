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

// MARK: - Step Identifiers
enum PointOfSaleBarcodeScannerStepID: String, CaseIterable {
    case start
    case setupBarcode1
    case setupBarcode2
    case pairing
    case test
    case complete
    case error
    case information
}

// MARK: - Button Customization Protocol
@available(iOS 17.0, *)
protocol PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration
}

// MARK: - Transition Types
enum PointOfSaleBarcodeScannerTransitionType: Hashable {
    case next
    case error
    case retry
    case back
}

// MARK: - Transition Definition
struct PointOfSaleBarcodeScannerTransition {
    let to: PointOfSaleBarcodeScannerStepID
    let type: PointOfSaleBarcodeScannerTransitionType

    init(to: PointOfSaleBarcodeScannerStepID, type: PointOfSaleBarcodeScannerTransitionType = .next) {
        self.to = to
        self.type = type
    }
}

// MARK: - Setup Step
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetupStep {
    let title: String
    let content: any View
    let buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization?
    let transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerTransition]

    init(
        title: String = "",
        @ViewBuilder content: () -> any View,
        buttonCustomization: PointOfSaleBarcodeScannerButtonCustomization? = nil,
        transitions: [PointOfSaleBarcodeScannerTransitionType: PointOfSaleBarcodeScannerTransition] = [:]) {
        self.title = title
        self.content = content()
        self.buttonCustomization = buttonCustomization
        self.transitions = transitions
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

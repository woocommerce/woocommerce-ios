import SwiftUI

// MARK: - Data Models
struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    let id = UUID()
    let title: String
    let scannerType: PointOfSaleBarcodeScannerType
}

enum PointOfSaleBarcodeScannerType {
    case socketS720
    case starBSH20B
    case tera12002D
    case other

    var name: String {
        switch self {
        case .socketS720:
            return Localization.socketS720Name
        case .starBSH20B:
            return Localization.starBsh20BName
        case .tera12002D:
            return Localization.tera12002DName
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
        case .tera12002D:
            return "Tera_1200_2D"
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
        static let tera12002DName = "Tera 1200 2D"
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
    case setupBarcodeHID
    case setupBarcodePair
    case setupInformation
    case setupProducts
    case pairing
    case test
    case testScanFailed
    case testScanTimedOut
    case complete

    var analyticsValue: String? {
        switch self {
        case .setupBarcodeHID:
            return "setup_barcode_hid"
        case .setupBarcodePair:
            return "setup_barcode_pair"
        case .setupInformation:
            return "setup_information"
        case .setupProducts:
            return "setup_products"
        case .pairing:
            return "pairing"
        case .test:
            return "test_barcode"
        case .testScanFailed:
            return "test_scan_failed"
        case .testScanTimedOut:
            return "test_scan_timed_out"
        case .complete:
            return "setup_complete"
        }
    }
}

// MARK: - Button Customization Protocol
@available(iOS 17.0, *)
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
@available(iOS 17.0, *)
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

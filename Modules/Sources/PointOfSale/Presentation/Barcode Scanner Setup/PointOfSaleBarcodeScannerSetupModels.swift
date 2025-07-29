import SwiftUI

// MARK: - Data Models
public struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    public let id = UUID()
    public let title: String
    public let scannerType: PointOfSaleBarcodeScannerType

    public init(title: String, scannerType: PointOfSaleBarcodeScannerType) {
        self.title = title
        self.scannerType = scannerType
    }
}

public enum PointOfSaleBarcodeScannerType {
    case starBSH20B
    case tera12002D
    case netum1228BC
    case other

    public var name: String {
        switch self {
        case .starBSH20B:
            return Localization.starBsh20BName
        case .tera12002D:
            return Localization.tera12002DName
        case .netum1228BC:
            return Localization.netum1228BCName
        case .other:
            return Localization.otherName
        }
    }

    public var analyticsName: String {
        switch self {
        case .starBSH20B:
            return "Star_BSH_20B"
        case .tera12002D:
            return "Tera_1200_2D"
        case .netum1228BC:
            return "Netum_1228BC"
        case .other:
            return "other"
        }
    }
}

private extension PointOfSaleBarcodeScannerType {
    enum Localization {
        static let starBsh20BName = NSLocalizedString(
            "pos.barcodeScannerSetup.scannerType.starBSH20B.name",
            value: "Star BSH-20B",
            comment: "Display name for Star BSH-20B barcode scanner model"
        )
        static let tera12002DName = NSLocalizedString(
            "pos.barcodeScannerSetup.scannerType.tera12002D.name",
            value: "Tera 1200 2D",
            comment: "Display name for Tera 1200 2D barcode scanner model"
        )
        static let netum1228BCName = NSLocalizedString(
            "pos.barcodeScannerSetup.scannerType.netum1228BC.name",
            value: "Netum 1228BC",
            comment: "Display name for Netum 1228BC barcode scanner model"
        )
        static let otherName = NSLocalizedString(
            "pos.barcodeScannerSetup.scannerType.other.name",
            value: "Other scanner",
            comment: "Display name for other/unspecified barcode scanner models"
        )
    }
}

// MARK: - Flow State
public enum PointOfSaleBarcodeScannerSetupFlowState {
    case scannerSelection
    case setupFlow(PointOfSaleBarcodeScannerType)
}

// MARK: - Step Identifiers
public enum PointOfSaleBarcodeScannerStepID: String, CaseIterable {
    case setupBarcodeHID
    case setupBarcodePair
    case setupInformation
    case setupProducts
    case pairing
    case test
    case testScanFailed
    case testScanTimedOut
    case complete

    public var analyticsValue: String? {
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

// MARK: - Test Barcodes
public enum PointOfSaleBarcodeScannerTestBarcode {
    case ean13

    public var barcodeAsset: PointOfSaleAssets {
        switch self {
        case .ean13:
            return .testEan13Barcode
        }
    }

    public var expectedValue: String {
        switch self {
        case .ean13:
            return "1234567890128"
        }
    }
}

import SwiftUI

// MARK: - Data Models
struct PointOfSaleBarcodeScannerSetupFlowOption: Identifiable {
    let id = UUID()
    let title: String
    let scannerType: PointOfSaleBarcodeScannerType
}

enum PointOfSaleBarcodeScannerType {
    case starBSH20B
    case tera12002D
    case netum1228BC
    case other

    var name: String {
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

    var analyticsName: String {
        switch self {
        case .starBSH20B:
            return "star_bsh_20b"
        case .tera12002D:
            return "tera_1200_2d"
        case .netum1228BC:
            return "netum_1228bc"
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

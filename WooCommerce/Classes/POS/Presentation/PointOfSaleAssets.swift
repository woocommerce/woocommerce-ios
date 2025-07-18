import Foundation

enum PointOfSaleAssets: CaseIterable {
    case error
    case exclamationMark
    case magnifierNotFound
    case readyForPayment
    case readerConnection
    case readerConnectionError
    case readerConnectionLowBattery
    case readerConnectionSuccess
    case readerDisconnected
    case readerLocation
    case shoppingBags
    case successCheck
    case coupons
    case gears
    case barcodeFieldScreenshot
    //TODO: WOOMOB-793 Update the imagesets for these barcodes to vector/dark mode friendly images
    case starBsh20SetupBarcode
    case tera12002DHIDBarcode
    case tera12002DPairBarcode
    case testEan13Barcode

    var imageName: String {
        switch self {
        case .error:
            "pos-error"
        case .exclamationMark:
            "pos-exclamation-mark"
        case .magnifierNotFound:
            "pos-magnifier-not-found"
        case .readyForPayment:
            "pos-ready-for-payment"
        case .readerConnection:
            "pos-reader-connection"
        case .readerConnectionError:
            "pos-reader-connection-error"
        case .readerConnectionLowBattery:
            "pos-reader-connection-battery"
        case .readerConnectionSuccess:
            "pos-reader-connection-complete"
        case .readerDisconnected:
            "pos-reader-disconnected"
        case .readerLocation:
            "location"
        case .shoppingBags:
            "shopping-bags"
        case .successCheck:
            "pos-success-check"
        case .coupons:
            "coupons"
        case .gears:
            "pos-gears"
        case .barcodeFieldScreenshot:
            "barcode-field-screenshot"
        case .starBsh20SetupBarcode:
            "star-bsh20-setup-barcode"
        case .testEan13Barcode:
            "test-ean13-barcode"
        case .tera12002DHIDBarcode:
            "tera-1200-2d-hid-barcode"
        case .tera12002DPairBarcode:
            "tera-1200-2d-pair-barcode"
        }
    }
}

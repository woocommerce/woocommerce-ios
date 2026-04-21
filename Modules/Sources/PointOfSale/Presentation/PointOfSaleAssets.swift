import Foundation
import SwiftUI

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
    case successCheck
    case gears
    case barcodeFieldScreenshot
    case starBsh20SetupBarcode
    case tera12002DHIDBarcode
    case tera12002DPairBarcode
    case netum1228BCHIDBarcode
    case netum1228BCPairBarcode
    case testEan13Barcode
    case noOrders

    var image: Image {
        Image(imageName, bundle: .module)
    }

    var decorativeImage: Image {
        Image(decorative: imageName, bundle: .module)
    }

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
        case .successCheck:
            "pos-success-check"
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
        case .netum1228BCHIDBarcode:
            "netum-1228bc-hid-barcode"
        case .netum1228BCPairBarcode:
            "netum-1228bc-pair-barcode"
        case .noOrders:
            "pos-no-orders"
        }
    }
}

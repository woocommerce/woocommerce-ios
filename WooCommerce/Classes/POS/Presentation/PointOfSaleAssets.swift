import Foundation

enum PointOfSaleAssets: CaseIterable {
    case error
    case exclamationMark
    case magnifierNotFound
    case readyForPayment
    case readerConnectionScanning
    case readerConnectionDoYouWantToConnect
    case readerConnectionConnecting
    case readerConnectionError
    case readerConnectionLowBattery
    case readerConnectionSuccess
    case readerDisconnected
    case shoppingBags
    case successCheck

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
        case .readerConnectionScanning:
            "pos-reader-connection-scanning"
        case .readerConnectionDoYouWantToConnect:
            "pos-reader-connection-do-you-want-to-connect"
        case .readerConnectionConnecting:
            "pos-reader-connection-connecting"
        case .readerConnectionError:
            "pos-reader-connection-error"
        case .readerConnectionLowBattery:
            "pos-reader-connection-battery"
        case .readerConnectionSuccess:
            "pos-reader-connection-complete"
        case .readerDisconnected:
            "pos-reader-disconnected"
        case .shoppingBags:
            "shopping-bags"
        case .successCheck:
            "pos-success-check"
        }
    }
}

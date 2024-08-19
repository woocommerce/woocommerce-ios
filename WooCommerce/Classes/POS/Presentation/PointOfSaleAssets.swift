import Foundation

enum PointOfSaleAssets: CaseIterable {
    case processingPayment
    case readyForPayment
    case cartBack
    case exit
    case getSupport
    case removeCartItem
    case readerConnectionScanning
    case readerConnectionDoYouWantToConnect
    case readerConnectionConnecting
    case readerConnectionSuccess

    var imageName: String {
        switch self {
        case .processingPayment:
            "pos-processing-payment"
        case .readyForPayment:
            "pos-ready-for-payment"
        case .cartBack:
            "pos-cart-back"
        case .exit:
            "pos-exit"
        case .getSupport:
            "pos-get-support"
        case .removeCartItem:
            "pos-remove-cart-item"
        case .readerConnectionScanning:
            "pos-reader-connection-scanning"
        case .readerConnectionDoYouWantToConnect:
            "pos-reader-connection-do-you-want-to-connect"
        case .readerConnectionConnecting:
            "pos-reader-connection-connecting"
        case .readerConnectionSuccess:
            "pos-reader-connection-complete"
        }
    }
}

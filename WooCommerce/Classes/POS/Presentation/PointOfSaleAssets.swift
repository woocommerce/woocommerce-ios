import Foundation

enum PointOfSaleAssets: CaseIterable {
    case processingPayment
    case readyForPayment
    case exit
    case getSupport
    case removeCartItem
    case dismissProductsBanner
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
        case .exit:
            "pos-exit"
        case .getSupport:
            "pos-get-support"
        case .removeCartItem:
            "pos-remove-cart-item"
        case .dismissProductsBanner:
            "pos-dismiss-products-banner"
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

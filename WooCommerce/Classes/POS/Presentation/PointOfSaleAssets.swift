import Foundation

enum PointOfSaleAssets: CaseIterable {
    case processingPayment
    case readyForPayment
    case cartBack
    case readerConnectionScanning
    case readerConnectionDoYouWantToConnect
    case readerConnectionConnecting
    case readerConnectionSuccess
    case shoppingBags

    var imageName: String {
        switch self {
        case .processingPayment:
            "pos-processing-payment"
        case .readyForPayment:
            "pos-ready-for-payment"
        case .cartBack:
            "pos-cart-back"
        case .readerConnectionScanning:
            "pos-reader-connection-scanning"
        case .readerConnectionDoYouWantToConnect:
            "pos-reader-connection-do-you-want-to-connect"
        case .readerConnectionConnecting:
            "pos-reader-connection-connecting"
        case .readerConnectionSuccess:
            "pos-reader-connection-complete"
        case .shoppingBags:
            "shopping-bags"
        }
    }
}

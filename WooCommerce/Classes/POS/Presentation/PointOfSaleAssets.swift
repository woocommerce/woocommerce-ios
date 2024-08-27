import Foundation

enum PointOfSaleAssets: CaseIterable {
    case cardReaderLowBattery
    case paymentsError
    case readyForPayment
    case readerConnectionScanning
    case readerConnectionDoYouWantToConnect
    case readerConnectionConnecting
    case readerConnectionSuccess
    case shoppingBags

    var imageName: String {
        switch self {
        case .cardReaderLowBattery:
            "card-reader-low-battery"
        case .paymentsError:
            "woo-payments-error"
        case .readyForPayment:
            "pos-ready-for-payment"
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

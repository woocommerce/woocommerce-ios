import Foundation

enum PointOfSaleAssets {
    case newTransaction
    case paymentSuccessful
    case processingPayment
    case readyForPayment
    case cartBack
    case exit
    case getSupport
    case removeCartItem
    case dismissProductsBanner

    var imageName: String {
        switch self {
        case .newTransaction:
            "pos-new-transaction-icon"
        case .paymentSuccessful:
            "pos-payment-successful"
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
        case .dismissProductsBanner:
            "pos-dismiss-products-banner"
        }
    }
}

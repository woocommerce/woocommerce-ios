import Foundation

enum POSPaymentError: Error, LocalizedError {
    case noOrder

    var errorDescription: String? {
        switch self {
        case .noOrder:
            return NSLocalizedString(
                "pointOfSale.paymentError.noOrder",
                value: "No order available for payment",
                comment: "Error when trying to collect payment without an order in the Point of Sale"
            )
        }
    }
}

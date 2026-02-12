import Foundation

enum POSPaymentError: Error, LocalizedError {
    case noOrder

    var errorDescription: String? {
        switch self {
        case .noOrder:
            return NSLocalizedString(
                "pointOfSale.paymentError.noOrder",
                value: "No order loaded yet. Start a payment before sending a receipt.",
                comment: "Error when trying to send a receipt before an order has been loaded in the Point of Sale"
            )
        }
    }
}

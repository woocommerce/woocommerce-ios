import Foundation

struct PointOfSalePaymentSuccessViewModel: Equatable {
    let title: String = Localization.title
    let message: String?

    init(formattedOrderTotal: String?, paymentMethod: PointOfSalePaymentMethod) {
        if let formattedOrderTotal {
            self.message = String(format: paymentMethod.paymentSuccessMessageFormatString, formattedOrderTotal)
        } else {
            self.message = nil
        }
    }
}

private extension PointOfSalePaymentSuccessViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.paymentSuccessful.title",
            value: "Payment successful",
            comment: "Title shown to users when payment is made successfully."
        )

        static let messageCard = NSLocalizedString(
            "pointOfSale.paymentSuccessful.message.card.1",
            value: "A card payment of %1$@ was successfully made.",
            comment: "Message shown to users when payment is made. %1$@ is a placeholder for the order " +
            " total, e.g $10.50. Please include %1$@ in your formatted string"
        )

        static let messageCash = NSLocalizedString(
            "pointOfSale.paymentSuccessful.message.cash.1",
            value: "A cash payment of %1$@ was successfully made.",
            comment: "Message shown to users when payment is made. %1$@ is a placeholder for the order " +
            " total, e.g $10.50. Please include %1$@ in your formatted string"
        )

        static let messageMarkAsPaid = NSLocalizedString(
            "pointOfSale.paymentSuccessful.message.markAsPaid.1",
            value: "A payment of %1$@ was marked as received.",
            comment: "Message shown to users when an order is marked as paid manually. %1$@ is a placeholder " +
            "for the order total, e.g $10.50. Please include %1$@ in your formatted string"
        )

        static let messageScanToPay = NSLocalizedString(
            "pointOfSale.paymentSuccessful.message.scanToPay.1",
            value: "A Scan to Pay payment of %1$@ was successfully made.",
            comment: "Message shown to users when a scan-to-pay payment is confirmed. %1$@ is a placeholder " +
            "for the order total, e.g $10.50. Please include %1$@ in your formatted string"
        )
    }
}

private extension PointOfSalePaymentMethod {
    var paymentSuccessMessageFormatString: String {
        switch self {
        case .card:
            return PointOfSalePaymentSuccessViewModel.Localization.messageCard

        case .cash:
            return PointOfSalePaymentSuccessViewModel.Localization.messageCash

        case .scanToPay:
            return PointOfSalePaymentSuccessViewModel.Localization.messageScanToPay

        case .markAsPaid:
            return PointOfSalePaymentSuccessViewModel.Localization.messageMarkAsPaid
        }
    }
}

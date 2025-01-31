import Foundation

struct PointOfSalePaymentSuccessViewModel: Equatable {
    let title: String = Localization.title
    let message: String?

    init(formattedOrderTotal: String?) {
        if let formattedOrderTotal {
            self.message = String(format: Localization.message, formattedOrderTotal)
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

        static let message = NSLocalizedString(
            "pointOfSale.paymentSuccessful.message",
            value: "A payment of %1$@ was successfully made",
            comment: "Message shown to users when payment is made. %1$@ is a placeholder for the order " +
            " total, e.g $10.50. Please include %1$@ in your formatted string"
        )
    }
}

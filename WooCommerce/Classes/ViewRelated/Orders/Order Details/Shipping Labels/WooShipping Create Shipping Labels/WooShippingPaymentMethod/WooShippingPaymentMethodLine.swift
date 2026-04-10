import Foundation
import Networking

/// Represents payment method line in the order details bottom sheet.
enum WooShippingPaymentMethodLine: Equatable {
    case add
    case card(CardPaymentMethodLineViewModel)

    struct CardPaymentMethodLineViewModel: Equatable {
        let id: Int64
        let title: String
        let isEditable: Bool
    }

    static func cardLineWithPaymentMethod(
        _ paymentMethod: ShippingLabelPaymentMethod,
        isEditable: Bool
    ) -> Self {
        let cardPaymentMethodLineViewModel = CardPaymentMethodLineViewModel(
            id: paymentMethod.paymentMethodID,
            title: paymentMethod.cardLineTitle,
            isEditable: isEditable
        )

        return .card(cardPaymentMethodLineViewModel)
    }
}

extension ShippingLabelPaymentMethod {
    var cardLineTitle: String {
        return cardType.rawValue.uppercased() + "****" + String(cardDigits.suffix(4))
    }

    var expiryString: String {
        guard let expiry else { return "" }

        let expiryString = NSLocalizedString(
            "shippingLabelPaymentMethod.expiry",
            value: "Expire %1$@",
            comment: "Label indicating the expiry date of a credit/debit card. The placeholder is the date. " +
            "Reads like: Expire 08/26"
        )
        let month = expiry.formatted(.dateTime.month(.twoDigits))
        let year = expiry.formatted(.dateTime.year(.twoDigits))
        let formatted = "\(month)/\(year)"
        return String(format: expiryString, formatted)
    }
}

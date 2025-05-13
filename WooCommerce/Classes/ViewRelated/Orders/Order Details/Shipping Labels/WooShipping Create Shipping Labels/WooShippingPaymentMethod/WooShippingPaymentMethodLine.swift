import Networking

/// Represents payment method line in the order details bottom sheet.
enum WooShippingPaymentMethodLine {
    case add
    case card(CardPaymentMethodLineViewModel)

    struct CardPaymentMethodLineViewModel {
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

private extension ShippingLabelPaymentMethod {
    var cardLineTitle: String {
        return cardType.rawValue.uppercased() + "****" + String(cardDigits.suffix(4))
    }
}

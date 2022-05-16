// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware

extension CardBrand {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> CardBrand {
        .visa
    }
}
extension CardPresentReceiptParameters {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> CardPresentReceiptParameters {
        .init(
            amount: .fake(),
            formattedAmount: .fake(),
            currency: .fake(),
            date: .fake(),
            storeName: .fake(),
            cardDetails: .fake(),
            orderID: .fake()
        )
    }
}
extension CardPresentTransactionDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> CardPresentTransactionDetails {
        .init(
            last4: .fake(),
            expMonth: .fake(),
            expYear: .fake(),
            cardholderName: .fake(),
            brand: .fake(),
            fingerprint: .fake(),
            generatedCard: .fake(),
            receipt: .fake(),
            emvAuthData: .fake()
        )
    }
}
extension Charge {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Charge {
        .init(
            id: .fake(),
            amount: .fake(),
            currency: .fake(),
            status: .fake(),
            description: .fake(),
            metadata: .fake(),
            paymentMethod: .fake()
        )
    }
}
extension ChargeStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ChargeStatus {
        .succeeded
    }
}
extension PaymentIntent {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> PaymentIntent {
        .init(
            id: .fake(),
            status: .fake(),
            created: .fake(),
            amount: .fake(),
            currency: .fake(),
            metadata: .fake(),
            charges: .fake()
        )
    }
}
extension PaymentIntentStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> PaymentIntentStatus {
        .requiresPaymentMethod
    }
}
extension PaymentMethod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> PaymentMethod {
        .card
    }
}

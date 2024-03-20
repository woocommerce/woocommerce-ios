// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware
import WooFoundation

extension Hardware.CardBrand {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.CardBrand {
        .visa
    }
}
extension Hardware.CardPresentReceiptParameters {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.CardPresentReceiptParameters {
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
extension Hardware.CardPresentTransactionDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.CardPresentTransactionDetails {
        .init(
            last4: .fake(),
            expMonth: .fake(),
            expYear: .fake(),
            cardholderName: .fake(),
            brand: .fake(),
            generatedCard: .fake(),
            receipt: .fake(),
            emvAuthData: .fake(),
            wallet: .fake(),
            network: .fake()
        )
    }
}
extension Hardware.Charge {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.Charge {
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
extension Hardware.ChargeStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.ChargeStatus {
        .succeeded
    }
}
extension Hardware.PaymentIntent {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.PaymentIntent {
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
extension Hardware.PaymentIntentStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.PaymentIntentStatus {
        .requiresPaymentMethod
    }
}
extension Hardware.PaymentMethod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Hardware.PaymentMethod {
        .card
    }
}

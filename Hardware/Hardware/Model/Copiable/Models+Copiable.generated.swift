// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import UIKit


extension CardPresentReceiptParameters {
    public func copy(
        amount: CopiableProp<UInt> = .copy,
        formattedAmount: CopiableProp<String> = .copy,
        currency: CopiableProp<String> = .copy,
        date: CopiableProp<Date> = .copy,
        storeName: NullableCopiableProp<String> = .copy,
        cardDetails: CopiableProp<CardPresentTransactionDetails> = .copy,
        orderID: NullableCopiableProp<Int64> = .copy
    ) -> CardPresentReceiptParameters {
        let amount = amount ?? self.amount
        let formattedAmount = formattedAmount ?? self.formattedAmount
        let currency = currency ?? self.currency
        let date = date ?? self.date
        let storeName = storeName ?? self.storeName
        let cardDetails = cardDetails ?? self.cardDetails
        let orderID = orderID ?? self.orderID

        return CardPresentReceiptParameters(
            amount: amount,
            formattedAmount: formattedAmount,
            currency: currency,
            date: date,
            storeName: storeName,
            cardDetails: cardDetails,
            orderID: orderID
        )
    }
}

extension Charge {
    public func copy(
        id: CopiableProp<String> = .copy,
        amount: CopiableProp<UInt> = .copy,
        currency: CopiableProp<String> = .copy,
        status: CopiableProp<ChargeStatus> = .copy,
        description: NullableCopiableProp<String> = .copy,
        metadata: NullableCopiableProp<[AnyHashable: Any]> = .copy,
        paymentMethod: NullableCopiableProp<PaymentMethod> = .copy
    ) -> Charge {
        let id = id ?? self.id
        let amount = amount ?? self.amount
        let currency = currency ?? self.currency
        let status = status ?? self.status
        let description = description ?? self.description
        let metadata = metadata ?? self.metadata
        let paymentMethod = paymentMethod ?? self.paymentMethod

        return Charge(
            id: id,
            amount: amount,
            currency: currency,
            status: status,
            description: description,
            metadata: metadata,
            paymentMethod: paymentMethod
        )
    }
}

extension PaymentIntent {
    public func copy(
        id: CopiableProp<String> = .copy,
        status: CopiableProp<PaymentIntentStatus> = .copy,
        created: CopiableProp<Date> = .copy,
        amount: CopiableProp<UInt> = .copy,
        currency: CopiableProp<String> = .copy,
        metadata: NullableCopiableProp<[String: String]> = .copy,
        charges: CopiableProp<[Charge]> = .copy
    ) -> PaymentIntent {
        let id = id ?? self.id
        let status = status ?? self.status
        let created = created ?? self.created
        let amount = amount ?? self.amount
        let currency = currency ?? self.currency
        let metadata = metadata ?? self.metadata
        let charges = charges ?? self.charges

        return PaymentIntent(
            id: id,
            status: status,
            created: created,
            amount: amount,
            currency: currency,
            metadata: metadata,
            charges: charges
        )
    }
}

// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Codegen
import UIKit


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

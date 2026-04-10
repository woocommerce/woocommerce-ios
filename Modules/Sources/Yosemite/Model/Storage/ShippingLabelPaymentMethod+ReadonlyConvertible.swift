import Foundation
import Storage

// Storage.ShippingLabelPaymentMethod: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelPaymentMethod: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelPaymentMethod with the a ReadOnly ShippingLabelPaymentMethod.
    ///
    public func update(with paymentMethod: Yosemite.ShippingLabelPaymentMethod) {
        paymentMethodID = paymentMethod.paymentMethodID
        name = paymentMethod.name
        cardType = paymentMethod.cardType.rawValue
        cardDigits = paymentMethod.cardDigits
        expiry = paymentMethod.expiry

    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelPaymentMethod {
        .init(paymentMethodID: paymentMethodID,
              name: name ?? "",
              cardType: ShippingLabelPaymentCardType(rawValue: cardType ?? "amex") ?? .amex,
              cardDigits: cardDigits ?? "",
              expiry: expiry)
    }
}

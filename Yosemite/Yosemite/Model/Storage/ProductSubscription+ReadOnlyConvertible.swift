import Foundation
import Networking
import Storage

// MARK: - Storage.ProductSubscription: ReadOnlyConvertible
//
extension Storage.ProductSubscription: ReadOnlyConvertible {

    /// Updates the Storage.ProductSubscription with the ReadOnly.
    ///
    public func update(with subscription: Yosemite.ProductSubscription) {
        length = subscription.length
        period = subscription.period.rawValue
        periodInterval = subscription.periodInterval
        price = subscription.price
        signUpFee = subscription.signUpFee
        trialLength = subscription.trialLength
        trialPeriod = subscription.trialPeriod.rawValue
        oneTimeShipping = subscription.oneTimeShipping
        paymentSyncDate = subscription.paymentSyncDate
        paymentSyncMonth = subscription.paymentSyncMonth
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductSubscription {
        return ProductSubscription(length: length ?? "0",
                                   period: SubscriptionPeriod(rawValue: period ?? "day") ?? .day,
                                   periodInterval: periodInterval ?? "",
                                   price: price ?? "",
                                   signUpFee: signUpFee ?? "",
                                   trialLength: trialLength ?? "0",
                                   trialPeriod: SubscriptionPeriod(rawValue: trialPeriod ?? "day") ?? .day,
                                   oneTimeShipping: oneTimeShipping,
                                   paymentSyncDate: paymentSyncDate ?? "0",
                                   paymentSyncMonth: paymentSyncMonth ?? "")
    }
}

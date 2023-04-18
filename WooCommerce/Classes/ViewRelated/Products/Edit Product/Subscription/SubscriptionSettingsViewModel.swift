import Foundation

/// ViewModel for `SubscriptionSettings`
///
final class SubscriptionSettingsViewModel {

    /// Description of the subscription price, billing interval, and period.
    ///
    let priceDescription: String

    /// Description of the length of time after which the subscription expires.
    ///
    let expiryDescription: String

    /// Description of the subscription signup fee.
    ///
    let signupFeeDescription: String

    /// Description of the subscription free trial period.
    ///
    let freeTrialDescription: String

    init(price: String,
         expiresAfter: String,
         signupFee: String,
         freeTrial: String) {
        self.priceDescription = price
        self.expiryDescription = expiresAfter
        self.signupFeeDescription = signupFee
        self.freeTrialDescription = freeTrial
    }
}

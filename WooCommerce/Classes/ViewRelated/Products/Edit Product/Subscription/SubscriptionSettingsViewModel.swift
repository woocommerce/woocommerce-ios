import Foundation
import Yosemite
import WooFoundation

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

    convenience init(subscription: ProductSubscription, currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        let priceDescription = Localization.priceDescription(price: subscription.price,
                                                             period: subscription.period,
                                                             periodInterval: subscription.periodInterval,
                                                             currencySettings: currencySettings)
        let expiryDescription = Localization.expiryDescription(length: subscription.length, period: subscription.period)
        let signupFeeDescription = Localization.signupFeeDescription(signupFee: subscription.signUpFee, currencySettings: currencySettings)
        let freeTrialDescription = Localization.trialDescription(trialLength: subscription.trialLength, trialPeriod: subscription.trialPeriod)

        self.init(price: priceDescription, expiresAfter: expiryDescription, signupFee: signupFeeDescription, freeTrial: freeTrialDescription)
    }
}

private extension SubscriptionSettingsViewModel {
    enum Localization {

        /// Localized string describing the subscription price, billing interval, and period.
        ///
        /// Example: "$50.00 every year" or "$10.00 every 2 weeks"
        ///
        static func priceDescription(price: String, period: SubscriptionPeriod, periodInterval: String, currencySettings: CurrencySettings) -> String {
            let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
            guard price.isNotEmpty, let formattedPrice = currencyFormatter.formatAmount(price) else {
                return NSLocalizedString("No price set", comment: "Display label when a subscription has no price.")
            }

            let billingFrequency = {
                switch periodInterval {
                case "1":
                    return period.descriptionSingular
                default:
                    return "\(periodInterval) \(period.descriptionPlural)"
                }
            }()

            let format = NSLocalizedString("%1$@ every %2$@",
                                           comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                           "Reads like: '$60.00 every 2 months'.")

            return String.localizedStringWithFormat(format, formattedPrice, billingFrequency)
        }

        /// Localized string describing when the subscription expires.
        ///
        /// Example: "Never expires" or "6 months" or "1 year"
        ///
        static func expiryDescription(length: String, period: SubscriptionPeriod) -> String {
            switch length {
            case "", "0":
                return NSLocalizedString("Never expire", comment: "Display label when a subscription never expires.")
            case "1":
                return "1 \(period.descriptionSingular)"
            default:
                return "\(length) \(period.descriptionPlural)"
            }
        }

        /// Localized string describing the subscription trial period.
        ///
        /// Example: "No trial period" or "12 months"
        ///
        static func trialDescription(trialLength: String, trialPeriod: SubscriptionPeriod) -> String {
            switch trialLength {
            case "", "0":
                return NSLocalizedString("No trial period", comment: "Display label when a subscription has no trial period.")
            case "1":
                return "1 \(trialPeriod.descriptionSingular)"
            default:
                return "\(trialLength) \(trialPeriod.descriptionPlural)"
            }
        }

        /// Localized string describing the subscription signup fee.
        ///
        /// Example: "No signup fee" or "$5.00"
        ///
        static func signupFeeDescription(signupFee: String, currencySettings: CurrencySettings) -> String {
            let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
            guard let formattedPrice = currencyFormatter.formatAmount(signupFee) else {
                return NSLocalizedString("No signup fee", comment: "Display label when a subscription has no signup fee.")
            }

            return formattedPrice
        }
    }
}

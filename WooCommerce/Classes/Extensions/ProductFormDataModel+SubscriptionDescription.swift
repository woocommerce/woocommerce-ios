import Foundation
import struct Yosemite.Product

extension ProductFormDataModel {

    /// Formats subscription period info to readable text.
    /// Returns nil if the product does not have subscription info.
    ///
    func subscriptionPeriodDescription() -> String? {
        guard let subscription = subscription else {
            return nil
        }
        let billingFrequency = {
            switch subscription.periodInterval {
            case "1":
                return subscription.period.descriptionSingular
            default:
                return "\(subscription.periodInterval) \(subscription.period.descriptionPlural)"
            }
        }()

        let subscriptionPeriodFormat = NSLocalizedString(
            "product.subscriptionPeriodFormat",
            value: "every %1$@",
            comment: "Description of the subscription price for a product, with the price " +
            "and billing frequency. Reads like: 'every 2 months'."
        )
        return String.localizedStringWithFormat(subscriptionPeriodFormat, billingFrequency)
    }
}

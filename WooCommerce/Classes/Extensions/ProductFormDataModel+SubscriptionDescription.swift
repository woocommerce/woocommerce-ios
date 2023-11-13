import Foundation
import struct Yosemite.Product

extension ProductFormDataModel {

    /// Returns the formatted subscription period info in readable text.
    /// Returns nil if the product does not have subscription info.
    ///
    var subscriptionPeriodDescription: String? {
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
            "productFormDataModel.subscriptionPeriodFormat",
            value: "every %1$@",
            comment: "Description of the subscription period for a product. " +
            "Reads like: 'every 2 months'."
        )
        return String.localizedStringWithFormat(subscriptionPeriodFormat, billingFrequency)
    }
}

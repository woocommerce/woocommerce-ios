import Foundation
import enum Yosemite.SubscriptionPeriod
import enum Yosemite.ProductType

extension ProductType {

    /// Whether this product type represents a subscription (simple or variable subscription).
    var isSubscription: Bool {
        self == .subscription || self == .variableSubscription
    }
}

extension ProductFormDataModel {

    /// Whether to treat this product as a subscription for display purposes.
    var isSubscriptionProduct: Bool {
        productType.isSubscription
    }

    /// Returns the formatted subscription period info in readable text.
    /// Returns nil if the product is not a subscription or does not have subscription info.
    ///
    var subscriptionPeriodDescription: String? {
        guard isSubscriptionProduct else {
            return nil
        }
        return subscription.map { String.formatSubscriptionPeriodDescription(period: $0.period, interval: $0.periodInterval) }
    }
}

extension String {
    static func formatSubscriptionPeriodDescription(period: SubscriptionPeriod, interval: String) -> String {
        let billingFrequency = {
            switch interval {
            case "1":
                return period.descriptionSingular
            default:
                return "\(interval) \(period.descriptionPlural)"
            }
        }()

        let subscriptionPeriodFormat = NSLocalizedString(
            "productFormDataModel.subscriptionPeriodFormat",
            value: "every %1$@",
            comment: "Description of the subscription period for a product. " +
            "Reads like: 'every 2 months'."
        )
        return localizedStringWithFormat(subscriptionPeriodFormat, billingFrequency)
    }
}

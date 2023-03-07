import Foundation
import Yosemite

extension PaymentGateway {
    /// Creates a PaymentGateway with default settings suitable for enabling Pay in Person on a store.
    /// This provides customer-facing strings to update the store's gateway.
    /// The gateway is enabled.
    static func defaultPayInPersonGateway(siteID: Int64) -> PaymentGateway {
        PaymentGateway(siteID: siteID,
                       gatewayID: Constants.cashOnDeliveryGatewayID,
                       title: Localization.cashOnDeliveryCheckoutTitle,
                       description: Localization.cashOnDeliveryCheckoutDescription,
                       enabled: true,
                       features: [.products],
                       instructions: Localization.cashOnDeliveryCheckoutInstructions)
    }

    enum Constants {
        static let cashOnDeliveryGatewayID = "cod"
    }

    private enum Localization {
        static let cashOnDeliveryCheckoutTitle = NSLocalizedString(
            "Pay in Person",
            comment: "Customer-facing title for the payment option added to the store checkout when the merchant enables " +
            "Pay in Person")

        static let cashOnDeliveryCheckoutDescription = NSLocalizedString(
            "Pay by card or another accepted payment method",
            comment: "Customer-facing description showing more details about the Pay in Person option which is added to " +
            "the store checkout when the merchant enables Pay in Person")

        static let cashOnDeliveryCheckoutInstructions = NSLocalizedString(
            "Pay by card or another accepted payment method",
            comment: "Customer-facing instructions shown on Order Thank-you pages and confirmation emails, showing more " +
            "details about the Pay in Person option added to the store checkout when the merchant enables Pay in Person")
    }
}

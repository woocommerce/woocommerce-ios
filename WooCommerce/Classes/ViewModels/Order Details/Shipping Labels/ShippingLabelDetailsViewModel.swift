import Foundation
import struct Yosemite.ShippingLabel

/// Provides UI display data for `ShippingLabelDetailsViewController`.
struct ShippingLabelDetailsViewModel {
    let originAddress: String
    let destinationAddress: String
    let packageName: String
    let carrierAndRate: String
    let paymentMethod: String

    init(shippingLabel: ShippingLabel, currencyFormatter: CurrencyFormatter) {
        self.originAddress = shippingLabel.originAddress.formattedPostalAddress ?? ""
        self.destinationAddress = shippingLabel.destinationAddress.formattedPostalAddress ?? ""
        self.packageName = shippingLabel.packageName
        self.carrierAndRate = {
            let serviceName = shippingLabel.serviceName
            let rate = currencyFormatter.formatAmount(Decimal(shippingLabel.rate), with: shippingLabel.currency)
            return [serviceName, rate].compactMap { $0 }.joined(separator: "\n")
        }()
        self.paymentMethod = Localization.creditCardPaymentMethod
    }
}

private extension ShippingLabelDetailsViewModel {
    enum Localization {
        static let creditCardPaymentMethod = NSLocalizedString("Credit card", comment: "Credit card payment method for shipping label.")
    }
}

import Contacts
import Foundation
import struct Yosemite.ShippingLabel
import struct Yosemite.ShippingLabelAddress

/// Provides UI display data for `ShippingLabelDetailsViewController`.
struct ShippingLabelDetailsViewModel {
    let originAddress: String
    let destinationAddress: String
    let packageName: String
    let carrierAndRate: String
    let paymentMethod: String

    init(shippingLabel: ShippingLabel, currencyFormatter: CurrencyFormatter) {
        self.originAddress = shippingLabel.originAddress.nameAndFormattedAddress
        self.destinationAddress = shippingLabel.destinationAddress.nameAndFormattedAddress
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

private extension ShippingLabelAddress {
    var nameAndFormattedAddress: String {
        [name, formattedAddress].compactMap { $0 }.joined(separator: "\n")
    }

    /// Returns the postal address, formatted and ready for display.
    var formattedAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)
    }

    var postalAddress: CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = [address1, address2].joined(separator: " ")
        address.city = city
        address.state = state
        address.postalCode = postcode
        address.country = country
        address.isoCountryCode = country
        return address
    }
}

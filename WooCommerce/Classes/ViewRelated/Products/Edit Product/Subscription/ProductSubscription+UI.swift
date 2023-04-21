import Yosemite
import WooFoundation

extension ProductSubscription {

    /// Localized string describing when the subscription expires.
    ///
    /// Example: "Never expires" or "6 months" or "1 year"
    ///
    var expiryDescription: String {
        switch self.length {
        case "", "0":
            return Localization.neverExpire
        case "1":
            return "1 \(self.period.descriptionSingular)"
        default:
            return "\(self.length) \(self.period.descriptionPlural)"
        }
    }

    /// Localized string describing the subscription trial period.
    ///
    /// Example: "No trial period" or "12 months"
    ///
    var trialDescription: String {
        switch self.trialLength {
        case "", "0":
            return Localization.noTrial
        case "1":
            return "1 \(self.trialPeriod.descriptionSingular)"
        default:
            return "\(self.trialLength) \(self.trialPeriod.descriptionPlural)"
        }
    }

    /// Localized string describing the subscription price, billing interval, and period.
    ///
    /// Example: "$50.00 every year" or "$10.00 every 2 weeks"
    ///
    func priceDescription(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        guard self.price.isNotEmpty, let formattedPrice = currencyFormatter.formatAmount(self.price) else {
            return Localization.noPrice
        }

        let billingFrequency = {
            switch self.periodInterval {
            case "1":
                return self.period.descriptionSingular
            default:
                return "\(self.periodInterval) \(self.period.descriptionPlural)"
            }
        }()

        return String.localizedStringWithFormat(Localization.priceFormat, formattedPrice, billingFrequency)
    }

    /// Localized string describing the subscription signup fee.
    ///
    /// Example: "No signup fee" or "$5.00"
    ///
    func signupFeeDescription(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        guard let formattedPrice = currencyFormatter.formatAmount(self.signUpFee) else {
            return Localization.noSignupFee
        }

        return formattedPrice
    }
}

private extension ProductSubscription {
    enum Localization {
        static let priceFormat = NSLocalizedString("%1$@ every %2$@",
                                                   comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                                   "Reads like: '$60.00 every 2 months'.")
        static let noPrice = NSLocalizedString("No price set", comment: "Display label when a subscription has no price.")
        static let neverExpire = NSLocalizedString("Never expire", comment: "Display label when a subscription never expires.")
        static let noSignupFee = NSLocalizedString("No signup fee", comment: "Display label when a subscription has no signup fee.")
        static let noTrial = NSLocalizedString("No trial period", comment: "Display label when a subscription has no trial period.")
    }
}

extension SubscriptionPeriod {
    /// Returns the localized singular text version of the Enum
    ///
    var descriptionSingular: String {
        switch self {
        case .day:
            return NSLocalizedString("day", comment: "Display label for a product's subscription period when it is a single day.")
        case .week:
            return NSLocalizedString("week", comment: "Display label for a product's subscription period when it is a single week.")
        case .month:
            return NSLocalizedString("month", comment: "Display label for a product's subscription period when it is a single month.")
        case .year:
            return NSLocalizedString("year", comment: "Display label for a product's subscription period when it is a single year.")
        }
    }

    /// Returns the localized plural text version of the Enum
    ///
    var descriptionPlural: String {
        switch self {
        case .day:
            return NSLocalizedString("days", comment: "Display label for a product's subscription period, e.g. '7 days'.")
        case .week:
            return NSLocalizedString("weeks", comment: "Display label for a product's subscription period, e.g. '4 weeks'.")
        case .month:
            return NSLocalizedString("months", comment: "Display label for a product's subscription period, e.g. '12 months'.")
        case .year:
            return NSLocalizedString("years", comment: "Display label for a product's subscription period, e.g. '2 years'.")
        }
    }
}

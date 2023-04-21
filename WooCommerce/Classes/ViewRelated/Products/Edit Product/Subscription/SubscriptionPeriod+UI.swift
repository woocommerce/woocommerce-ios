import Yosemite
import WooFoundation

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

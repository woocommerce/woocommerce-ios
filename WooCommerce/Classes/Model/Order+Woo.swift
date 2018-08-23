import Foundation
import Yosemite


// MARK: - Order Helper Methods
//
extension Order {

    /// Returns the Currency Symbol associated with the current order.
    ///
    var currencySymbol: String {
        let components = [NSLocale.Key.currencyCode.rawValue: currency]
        let identifier = NSLocale.localeIdentifier(fromComponents: components)

        return NSLocale(localeIdentifier: identifier).currencySymbol
    }

    /// Translates a Section Identifier into a Human-Readable String.
    ///
    static func descriptionForSectionIdentifier(_ identifier: String) -> String {
        guard let age = Age(rawValue: identifier) else {
            return String()
        }

        return age.description
    }
}

enum Age: String {
    case months     = "0"
    case weeks      = "2"
    case days       = "4"
    case yesterday  = "5"
    case today      = "6"

    var description: String {
        switch self {
        case .months:
            return NSLocalizedString("Older than a Month", comment: "Notifications Months Section Header")
        case .weeks:
            return NSLocalizedString("Older than a Week", comment: "Notifications Weeks Section Header")
        case .days:
            return NSLocalizedString("Older than 2 days", comment: "Notifications +2 Days Section Header")
        case .yesterday:
            return NSLocalizedString("Yesterday", comment: "Notifications Yesterday Section Header")
        case .today:
            return NSLocalizedString("Today", comment: "Notifications Today Section Header")
        }
    }
}

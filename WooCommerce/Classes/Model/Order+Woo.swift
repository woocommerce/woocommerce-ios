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
        guard let section = Sections(rawValue: identifier) else {
            return String()
        }

        return section.description
    }

    // MARK: - Private Helpers
    fileprivate enum Sections: String {
        case Months     = "0"
        case Weeks      = "2"
        case Days       = "4"
        case Yesterday  = "5"
        case Today      = "6"

        var description: String {
            switch self {
            case .Months:
                return NSLocalizedString("Older than a Month", comment: "Notifications Months Section Header")
            case .Weeks:
                return NSLocalizedString("Older than a Week", comment: "Notifications Weeks Section Header")
            case .Days:
                return NSLocalizedString("Older than 2 days", comment: "Notifications +2 Days Section Header")
            case .Yesterday:
                return NSLocalizedString("Yesterday", comment: "Notifications Yesterday Section Header")
            case .Today:
                return NSLocalizedString("Today", comment: "Notifications Today Section Header")
            }
        }
    }
}

import Foundation


/// Enum used to represent the age of Order / Notification entities.
///
enum Age: String {
    case months     = "0"
    case weeks      = "2"
    case days       = "4"
    case yesterday  = "5"
    case today      = "6"

    var description: String {
        switch self {
        case .months:       return NSLocalizedString("Older than a Month", comment: "Months Section Header")
        case .weeks:        return NSLocalizedString("Older than a Week", comment: "Weeks Section Header")
        case .days:         return NSLocalizedString("Older than 2 days", comment: "+2 Days Section Header")
        case .yesterday:    return NSLocalizedString("Yesterday", comment: "Yesterday Section Header")
        case .today:        return NSLocalizedString("Today", comment: "Today Section Header")
        }
    }
}


// MARK: - Convenience Methods Initializers
//
extension Age {

    /// Returns the Age entity that best describes a given timespan.
    ///
    static func from(startDate: Date, toDate: Date) -> Age {
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let dateComponents = Calendar.current.dateComponents(components, from: startDate, to: toDate)

        // Months
        if let month = dateComponents.month, month >= 1 {
            return .months
        }

        // Weeks
        if let week = dateComponents.weekOfYear, week >= 1 {
            return .weeks
        }

        // Days
        if let day = dateComponents.day, day > 1 {
            return .days
        }

        if let day = dateComponents.day, day == 1 {
            return .yesterday
        }

        return .today
    }
}

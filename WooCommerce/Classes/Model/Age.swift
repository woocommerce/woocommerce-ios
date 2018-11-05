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


// MARK: - Helper Initializers
//
extension Age {

    /// Initializes the Age Entity, based on a set of DateComponents
    ///
    init(dateComponents: DateComponents) {
        // Months
        if let month = dateComponents.month, month >= 1 {
            self = .months
        // Weeks
        } else if let week = dateComponents.weekOfYear, week >= 1 {
            self = .weeks
        // Days
        } else if let day = dateComponents.day, day > 1 {
            self = .days
        } else if let day = dateComponents.day, day == 1 {
            self = .yesterday
        } else {
            self = .today
        }
    }
}

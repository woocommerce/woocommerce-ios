import Foundation


/// Enum used to represent the age of Product Reviews.
///
enum ReviewAge: String {
    case last24Hours = "0"
    case last7Days   = "1"
    case theRest     = "2"

    var description: String {
        switch self {
        case .last24Hours:  return NSLocalizedString("Last 24 hours", comment: "Last 24 hours section header")
        case .last7Days:    return NSLocalizedString("Last 7 days", comment: "Last 7 days section header")
        case .theRest:      return NSLocalizedString("Older than 7 days", comment: "+7 Days Section Header")
        }
    }
}


// MARK: - Convenience Methods Initializers
//
extension ReviewAge {

    /// Returns the Age entity that best describes a given timespan.
    ///
    static func from(startDate: Date, toDate: Date) -> ReviewAge {
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let dateComponents = Calendar.current.dateComponents(components, from: startDate, to: toDate)

        // Months
        if let month = dateComponents.month, month >= 1 {
            return .theRest
        }

        // Weeks
        if let week = dateComponents.weekOfYear, week >= 1 {
            return .theRest
        }

        // Days
        if let day = dateComponents.day,
            let week = dateComponents.weekOfYear,
            day > 1,
            week <= 1 {
            return .last7Days
        }

        if let day = dateComponents.day, day == 1 {
            return .last24Hours
        }

        return .last24Hours
    }
}

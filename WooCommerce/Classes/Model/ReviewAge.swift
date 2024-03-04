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
        let timeDifference = toDate.timeIntervalSince(startDate)
        let oneDayInSeconds: TimeInterval = 86_400

        if timeDifference <= oneDayInSeconds { // 24hrs
            return .last24Hours
        } else if timeDifference <= oneDayInSeconds * 7 { // 7 days
            return .last7Days
        } else {
            return .theRest
        }
    }
}

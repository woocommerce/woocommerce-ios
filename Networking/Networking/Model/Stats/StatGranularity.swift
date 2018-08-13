import Foundation


/// Represents data granularity for stats (e.g. day, week, month, year)
///
public enum StatGranularity: String, Decodable {
    case day
    case week
    case month
    case year
}

// MARK: - StringConvertible Conformance
//
extension StatGranularity: CustomStringConvertible {

    /// Returns a user-freindly, localized string describing the stat granularity
    ///
    public var description: String {
        switch self {
        case .day:
            return NSLocalizedString("Day", comment: "Order statistics unit - a single day")
        case .week:
            return NSLocalizedString("Week", comment: "Order statistics unit - a single week")
        case .month:
            return NSLocalizedString("Month", comment: "Order statistics unit - a single week")
        case .year:
            return NSLocalizedString("Year", comment: "Order statistics unit - a single year")
        }
    }
}


import Foundation


/// Represents data granularity for stats (e.g. day, week, month, year)
///
public enum StatGranularity: String, Decodable {
    case day
    case week
    case month
    case year

    public var pluralizedString: String {
        switch self {
        case .day:
            return NSLocalizedString("Days", comment: "Plural of 'day' — a statistical unit")
        case .week:
            return NSLocalizedString("Weeks", comment: "Plural of 'week' — a statistical unit")
        case .month:
            return NSLocalizedString("Months", comment: "Plural of 'month' — a statistical unit")
        case .year:
            return NSLocalizedString("Years", comment: "Plural of 'year' — a statistical unit")
        }
    }

    public var accessibilityIdentifier: String {
        return "granularity-\(self.rawValue)"
    }
}

// MARK: - StringConvertible Conformance
//
extension StatGranularity: CustomStringConvertible {

    /// Returns a user-freindly, localized string describing the stat granularity
    ///
    public var description: String {
        switch self {
        case .day:
            return NSLocalizedString("Day", comment: "Statistical unit - a single day")
        case .week:
            return NSLocalizedString("Week", comment: "Statistical unit - a single week")
        case .month:
            return NSLocalizedString("Month", comment: "Statistical unit - a single week")
        case .year:
            return NSLocalizedString("Year", comment: "Statistical unit - a single year")
        }
    }
}

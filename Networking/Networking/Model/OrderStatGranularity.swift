import Foundation


/// Represents the data granularity for a specific `OrderStats` instance (e.g. day, week, month, year)
///
public enum OrderStatGranularity: Decodable {
    case day
    case week
    case month
    case year
}


// MARK: - RawRepresentable Conformance
//
extension OrderStatGranularity: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.week:
            self = .week
        case Keys.month:
            self = .month
        case Keys.year:
            self = .year
        default:
            self = .day
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .day:      return Keys.day
        case .week:     return Keys.week
        case .month:    return Keys.month
        case .year:     return Keys.year
        }
    }
}


// MARK: - StringConvertible Conformance
//
extension OrderStatGranularity: CustomStringConvertible {

    /// Returns a string describing the current OrderStatus Instance
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


// MARK: - Constants!
//
private extension OrderStatGranularity {

    /// Enum containing the 'Known' OrderStatGranularity Keys
    ///
    private enum Keys {
        static let day      = "day"
        static let week     = "week"
        static let month    = "month"
        static let year     = "year"
    }
}

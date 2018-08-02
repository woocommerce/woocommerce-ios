import Foundation


/// Represents the data granularity for a specific `OrderStats` instance (e.g. day, week, month, year)
///
public enum OrderStatGranularity: String, Decodable {
    case day
    case week
    case month
    case year
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


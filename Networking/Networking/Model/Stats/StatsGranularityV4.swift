import Foundation

/// Represents data granularity for stats (e.g. day, week, month, year)
///
public enum StatsGranularityV4: String, Decodable {
    case hourly
    case daily
    case weekly
    case monthly
    case yearly

//    public var pluralizedString: String {
//        switch self {
//        case .hourly:
//            return NSLocalizedString("Today", comment: "Today — a statistical unit")
//        case .daily:
//            return NSLocalizedString("This Week", comment: "Plural of 'day' — a statistical unit")
//        case .week:
//            return NSLocalizedString("Weeks", comment: "Plural of 'week' — a statistical unit")
//        case .month:
//            return NSLocalizedString("Months", comment: "Plural of 'month' — a statistical unit")
//        case .year:
//            return NSLocalizedString("Years", comment: "Plural of 'year' — a statistical unit")
//        }
//    }

}

//// MARK: - StringConvertible Conformance
////
//extension StatGranularity: CustomStringConvertible {
//
//    /// Returns a user-freindly, localized string describing the stat granularity
//    ///
//    public var description: String {
//        switch self {
//        case .day:
//            return NSLocalizedString("Day", comment: "Statistical unit - a single day")
//        case .week:
//            return NSLocalizedString("Week", comment: "Statistical unit - a single week")
//        case .month:
//            return NSLocalizedString("Month", comment: "Statistical unit - a single week")
//        case .year:
//            return NSLocalizedString("Year", comment: "Statistical unit - a single year")
//        }
//    }
//}

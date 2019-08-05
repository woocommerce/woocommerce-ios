import Yosemite

extension StatsGranularityV4 {
    var tabTitle: String {
        switch self {
        case .hourly:
            return NSLocalizedString("Today", comment: "Tab selector title that shows the statistics of today")
        case .daily:
            return NSLocalizedString("This Week", comment: "Tab selector title that shows the statistics of this week")
        case .weekly:
            return NSLocalizedString("This Month", comment: "Tab selector title that shows the statistics of this month")
        case .monthly:
            return NSLocalizedString("This Year", comment: "Tab selector title that shows the statistics of this year")
        default:
            fatalError("This case is not supported: \(self.rawValue)")
        }
    }

//    private func numberOfSeconds(numberOfIntervals: Int) -> TimeInterval {
//        switch self {
//        case .hourly:
//            return 3600 * Double(numberOfIntervals)
//        case .daily:
//            return 86400 * Double(numberOfIntervals)
//        case .weekly:
//            return 86400 * 7 * Double(numberOfIntervals)
//        case .monthly:
//            return 86400 * 7
//        default:
//            fatalError("This case is not supported: \(self.rawValue)")
//        }
//    }
}

enum StatsTimeRangeV4 {
    case today
    case thisWeek
    case thisMonth
    case thisYear
}

extension StatsTimeRangeV4 {
    var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .hourly
        case .thisWeek:
            return .daily
        case .thisMonth:
            return .daily
        case .thisYear:
            return .monthly
        }
    }

    // TODO-jc: more calculation later
    var intervalQuantity: Int {
        switch self {
        case .today:
            return 24
        case .thisWeek:
            return 7
        case .thisMonth:
            return 31
        case .thisYear:
            return 12
        }
    }

    func earliestDate(latestDate: Date) -> Date {
        let numberOfSeconds: TimeInterval
        let numberOfIntervals = intervalQuantity
        switch intervalGranularity {
        case .hourly:
            numberOfSeconds = 3600 * Double(numberOfIntervals)
        case .daily:
            numberOfSeconds = 86400 * Double(numberOfIntervals)
        case .weekly:
            numberOfSeconds = 86400 * 7 * Double(numberOfIntervals)
        case .monthly:
            numberOfSeconds = 86400 * 7 * 30 * Double(numberOfIntervals)
        default:
            fatalError("This case is not supported: \(intervalGranularity.rawValue)")
        }
        return latestDate.addingTimeInterval(-numberOfSeconds)
    }
}

import Foundation

/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
/// - custom: Data for a custom range.
public enum StatsTimeRangeV4 {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case custom(from: Date, to: Date)
}

extension StatsTimeRangeV4: RawRepresentable, Hashable {

    public init?(rawValue: String) {
        switch rawValue {
        case Value.today:
            self = .today
        case Value.thisWeek:
            self = .thisWeek
        case Value.thisMonth:
            self = .thisMonth
        case Value.thisYear:
            self = .thisYear
        default:
            guard rawValue.starts(with: Value.custom) else {
                return nil
            }

            let splits = rawValue.split(separator: "_")

            guard let from = splits[safe: 1],
                  let to = splits[safe: 2] else {
                return nil
            }

            let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
            guard let fromDate = dateFormatter.date(from: String(from)),
                  let toDate = dateFormatter.date(from: String(to)) else {
                return nil
            }

            self = .custom(from: fromDate, to: toDate)
        }
    }

    public var rawValue: String {
        switch self {
        case .today: return Value.today
        case .thisWeek: return Value.thisWeek
        case .thisMonth: return Value.thisMonth
        case .thisYear: return Value.thisYear
        case .custom(let from, let to):
            let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
            return [Value.custom,
                    dateFormatter.string(from: from),
                    dateFormatter.string(from: to)].joined(separator: "_")
        }
    }

    private enum Value {
        static let today = "today"
        static let thisWeek = "thisWeek"
        static let thisMonth = "thisMonth"
        static let thisYear = "thisYear"
        static let custom = "custom"
    }
}

extension StatsTimeRangeV4 {
    /// Represents the period unit of the store stats using Stats v4 API given a time range.
    public var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .hourly
        case .thisWeek:
            return .daily
        case .thisMonth:
            return .daily
        case .thisYear:
            return .monthly
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, toDate: to) else {
                return .hourly
            }
            switch differenceInDays {
            case .lessThan1:
                return .hourly
            case .from1To28:
                return .daily
            case .from29To90:
                return .weekly
            case .from91to365:
                return .monthly
            case .greaterThanOrEqualTo365:
                return .quarterly
            }
        }
    }

    /// Represents the period unit of the site visit stats given a time range.
    public var siteVisitStatsGranularity: StatGranularity {
        switch self {
        case .today, .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, toDate: to) else {
                return .hour
            }
            switch differenceInDays {
            case .lessThan1:
                return .hour
            case .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91to365:
                return .month
            case .greaterThanOrEqualTo365:
                return .quarter
            }
        }
    }

    /// Represents the period unit of the top earners stats given a time range.
    public var topEarnerStatsGranularity: StatGranularity {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .week
        case .thisMonth:
            return .month
        case .thisYear:
            return .year
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, toDate: to) else {
                return .hour
            }
            switch differenceInDays {
            case .lessThan1:
                return .hour
            case .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91to365:
                return .month
            case .greaterThanOrEqualTo365:
                return .quarter
            }
        }
    }

    /// Represents the period unit of the summary stats given a time range.
    public var summaryStatsGranularity: StatGranularity {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .week
        case .thisMonth:
            return .month
        case .thisYear:
            return .year
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, toDate: to) else {
                return .hour
            }
            switch differenceInDays {
            case .lessThan1:
                return .hour
            case .from1To28:
                return .day
            case .from29To90:
                return .week
            case .from91to365:
                return .month
            case .greaterThanOrEqualTo365:
                return .quarter
            }
        }
    }

    /// The number of intervals for site visit stats to fetch given a time range.
    /// The interval unit is in `siteVisitStatsGranularity`.
    func siteVisitStatsQuantity(date: Date, siteTimezone: TimeZone) -> Int {
        switch self {
        case .today:
            return 1
        case .thisWeek:
            return 7
        case .thisMonth:
            var calendar = Calendar.current
            calendar.timeZone = siteTimezone
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .thisYear:
            return 12
        case .custom(let from, let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, toDate: to) else {
                return 1
            }
            // TODO: 11935 Calculate interval units
            return 1
        }
    }
}

private extension StatsTimeRangeV4 {
    enum DifferenceInDays {
        case greaterThanOrEqualTo365
        case from91to365
        case from29To90
        case from1To28
        case lessThan1
    }

    static func differenceInDays(startDate: Date, toDate: Date) -> DifferenceInDays? {
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let dateComponents = Calendar.current.dateComponents(components, from: startDate, to: toDate)

        guard let day = dateComponents.day else {
            return nil
        }

        switch day {
        case 325...Int.max:
            return .greaterThanOrEqualTo365
        case 91...365:
            return .from91to365
        case 29...90:
            return .from29To90
        case 1...28:
            return .from1To28
        case 0:
            return .lessThan1
        default:
            return nil
        }
    }
}

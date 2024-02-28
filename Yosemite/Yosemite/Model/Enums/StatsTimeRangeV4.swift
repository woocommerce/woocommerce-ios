import Foundation

/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
/// - custom: Data for a custom date range.
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
            guard let dates = CustomRangeFormatter.dates(from: rawValue) else {
                return nil
            }

            self = .custom(from: dates.from, to: dates.to)
        }
    }

    public var rawValue: String {
        switch self {
        case .today: return Value.today
        case .thisWeek: return Value.thisWeek
        case .thisMonth: return Value.thisMonth
        case .thisYear: return Value.thisYear
        case .custom(let from, let to):
            return CustomRangeFormatter.rangeFrom(from: from, to: to)
        }
    }

    public var isCustomTimeRange: Bool {
        switch self {
        case .today, .thisWeek, .thisMonth, .thisYear:
            false
        case .custom:
            true
        }
    }

    private enum CustomRangeFormatter {
        static private let dateFormatter = DateFormatter.Defaults.yearMonthDayDateFormatter
        static private let separator = "_"

        static func rangeFrom(from: Date, to: Date) -> String {
            [Value.custom,
             dateFormatter.string(from: from),
             dateFormatter.string(from: to)].joined(separator: separator)
        }

        static func dates(from rawValue: String) -> (from: Date, to: Date)? {
            guard rawValue.starts(with: Value.custom) else {
                return nil
            }

            let splits = rawValue.split(separator: separator)

            guard let from = splits[safe: 1],
                  let to = splits[safe: 2] else {
                return nil
            }

            guard let fromDate = dateFormatter.date(from: String(from)),
                  let toDate = dateFormatter.date(from: String(to)) else {
                return nil
            }

            return (from: fromDate, to: toDate)
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
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
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
            case .greaterThan365:
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
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
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
            case .greaterThan365:
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
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
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
            case .greaterThan365:
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
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
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
            case .greaterThan365:
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
        case let .custom(startDate, endDate):
            let calendar = Calendar.current
            let quantity: Int? = {
                switch siteVisitStatsGranularity {
                case .hour:
                    calendar.dateComponents([.hour], from: startDate, to: endDate).hour
                case .day, .week:
                    calendar.dateComponents([.day], from: startDate, to: endDate).day
                case .month, .quarter:
                    calendar.dateComponents([.month], from: startDate, to: endDate).month
                case .year:
                    calendar.dateComponents([.year], from: startDate, to: endDate).year
                }
            }()
            return quantity ?? 7
        }
    }
}

private extension StatsTimeRangeV4 {
    enum DifferenceInDays {
        case greaterThan365
        case from91to365
        case from29To90
        case from1To28
        case lessThan1
    }

    /// Based on WooCommerce Core
    ///
    /// https://github.com/woocommerce/woocommerce/blob/e863c02551e94d928d3873131ff2f4ab61d0ff66/packages/js/date/src/index.ts#L626
    ///
    /// More details at pe5sF9-2ri-p2
    ///
    static func differenceInDays(startDate: Date, endDate: Date) -> DifferenceInDays? {
        let dateComponents = Calendar.current.dateComponents([.day], from: startDate, to: endDate)

        guard let day = dateComponents.day else {
            return nil
        }

        switch day {
        case 366...Int.max:
            return .greaterThan365
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

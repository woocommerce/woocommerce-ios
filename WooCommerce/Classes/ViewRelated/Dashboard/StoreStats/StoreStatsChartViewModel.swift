import Foundation
import Yosemite
import WooFoundation

/// A struct for data to be displayed on a Swift chart.
///
struct StoreStatsChartData: Identifiable {
    var id: String { UUID().uuidString }

    let date: Date
    let revenue: Double
}

/// View model for `StoreStatsChart`
///
final class StoreStatsChartViewModel: ObservableObject {

    var intervals: [StoreStatsChartData]
    private var timeRange: StatsTimeRangeV4
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter

    init(intervals: [StoreStatsChartData],
         timeRange: StatsTimeRangeV4,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.intervals = intervals
        self.timeRange = timeRange
        self.currencySettings = currencySettings
        self.currencyFormatter = currencyFormatter
    }
}

// MARK: - Chart details
//
extension StoreStatsChartViewModel {
    var hasRevenue: Bool {
        intervals.map { $0.revenue }.contains { $0 != 0 }
    }

    var xAxisStride: Calendar.Component {
        switch timeRange {
        case .today:
            return .hour
        case .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        case .custom(from: let from, to: let to):
            guard let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return .hour
            }
            switch differenceInDays {
            case .sameDay:
                return .hour
            case .from1To28, .from29To90:
                return .day
            case .from91daysTo3Years:
                return .month
            case .greaterThan3Years:
                return .year
            }
        }
    }

    var xAxisStrideCount: Int {
        switch timeRange {
        case .today:
            return 5
        case .thisWeek:
            return 1
        case .thisMonth:
            return 5
        case .thisYear:
            return 3
        case let .custom(start, end):
            let difference: Int = {
                var calendar = Calendar.current
                calendar.timeZone = .siteTimezone
                switch xAxisStride {
                case .year:
                    return calendar.dateComponents([.year], from: start, to: end).year ?? 0
                case .month:
                    return calendar.dateComponents([.month], from: start, to: end).month ?? 0
                case .day:
                    return calendar.dateComponents([.day], from: start, to: end).day ?? 0
                case .hour:
                    return 24 // only same day range has hour strides, so default to 24 hours.
                default:
                    return 0
                }
            }()
            return difference <= Constants.maximumItemsForXAxis ? 1 : difference / Constants.maximumItemsForXAxis
        }
    }

    func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch timeRange {
        case .today:
            return .dateTime.hour()
        case .thisWeek, .thisMonth:
            if date == intervals.first?.date {
                return .dateTime.month(.abbreviated).day(.defaultDigits)
            }
            return .dateTime.day(.defaultDigits)
        case .thisYear:
            return .dateTime.month(.abbreviated)
        case let .custom(start, end):
            switch timeRange.intervalGranularity {
            case .hourly:
                return .dateTime.hour()
            case .daily, .weekly:
                var calendar = Calendar.current
                calendar.timeZone = .siteTimezone
                let sameMonth = start.isSameMonth(as: end) && start.isSameYear(as: end)
                if date == intervals.first?.date || !sameMonth {
                    return .dateTime.month(.abbreviated).day(.defaultDigits)
                }
                return .dateTime.day(.defaultDigits)
            case .monthly:
                return .dateTime.month(.abbreviated)
            case .yearly:
                return .dateTime.year()
            }
        }
    }

    var yAxisStride: Double {
        let minValue = intervals.map { $0.revenue }.min() ?? 0
        let maxValue = intervals.map { $0.revenue }.max() ?? 0
        return (abs(minValue) + abs(maxValue)) / 2
    }

    func yAxisLabel(for revenue: Double) -> String {
        if revenue == 0.0 {
            // Do not show the "0" label on the Y axis
            return ""
        } else {
            let currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
            return currencyFormatter
                .formatCurrency(using: revenue.humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: true),
                                currencyPosition: currencySettings.currencyPosition,
                                currencySymbol: currencySymbol,
                                isNegative: revenue.sign == .minus)
        }
    }
}

private extension StoreStatsChartViewModel {
    enum Constants {
        static let maximumItemsForXAxis = 4
    }
}

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
            return 7
        case .thisMonth:
            return 6
        case .thisYear:
            return 4
        case .custom(from: let from, to: let to):
            return 5
        }
    }

    func xAxisLabelFormatStyle(for date: Date) -> Date.FormatStyle {
        switch timeRange {
        case .today:
            return .dateTime.hour()
        case .thisWeek, .thisMonth:
            if date == intervals.first?.date {
                return .dateTime.month(.abbreviated).day(.twoDigits)
            }
            return .dateTime.day(.twoDigits)
        case .thisYear:
            return .dateTime.month(.abbreviated)
        case .custom(from: let from, to: let to):
            switch timeRange.intervalGranularity {
            case .daily:
                return .dateTime.hour()
            case .hourly, .weekly:
                if date == intervals.first?.date {
                    return .dateTime.month(.abbreviated).day(.twoDigits)
                }
                return .dateTime.day(.twoDigits)
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
        return (minValue + maxValue) / 2
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

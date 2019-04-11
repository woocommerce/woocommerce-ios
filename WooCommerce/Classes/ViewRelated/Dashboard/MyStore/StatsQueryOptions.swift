import Foundation
import Yosemite

struct StatsQueryOptions {
    enum Period {
        case latest
        case range(from: Date, to: Date)
    }

    let queryID: String
    let granularity: StatGranularity
    let period: Period

    var latestDateToInclude: Date {
        switch period {
        case .latest:
            return Date()
        case .range(_, let to):
            return to
        }
    }

    var quantity: Int {
        switch period {
        case .latest:
            return quantity(for: granularity)
        case .range(let fromDate, let toDate):
            return quantity(for: granularity, from: fromDate, to: toDate)
        }
    }
}

private extension StatsQueryOptions {
    func quantity(for granularity: StatGranularity) -> Int {
        switch granularity {
        case .day:
            return Constants.quantityDefaultForDay
        case .week:
            return Constants.quantityDefaultForWeek
        case .month:
            return Constants.quantityDefaultForMonth
        case .year:
            return Constants.quantityDefaultForYear
        }
    }

    func quantity(for granularity: StatGranularity, from: Date, to: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)

        var calendarComponent: Calendar.Component
        switch granularity {
        case .day:
            calendarComponent = .day
        case .week:
            calendarComponent = .weekOfYear
        case .month:
            calendarComponent = .month
        case .year:
            calendarComponent = .year
        }

        let components = calendar.dateComponents([calendarComponent, .nanosecond], from: from, to: to)
        let value = components.value(for: calendarComponent) ?? 0
        let nanoseconds = components.nanosecond ?? 0

        // Add one more unit if there's a rest
        return value + (nanoseconds > 0 ? 1 : 0)
    }
}

// MARK: - Constants!
//
private extension StatsQueryOptions {
    enum Constants {
        static let quantityDefaultForDay = 30
        static let quantityDefaultForWeek = 13
        static let quantityDefaultForMonth = 12
        static let quantityDefaultForYear = 5
    }
}

import Foundation

public extension Date {
    // MARK: Day

    /// Returns self's start of day in the given time zone.
    func startOfDay(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        return calendar.startOfDay(for: self)
    }

    /// Returns self's end of day in the given time zone.
    func endOfDay(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)

        let startOfNextDay: Date = {
            var components = DateComponents()
            components.day = 1
            guard let nextDay = calendar.date(byAdding: components, to: startOfDay(timezone: timezone)) else {
                logErrorAndExit("The next day cannot be calculated for \(self) with time zone \(timezone)")
            }
            return nextDay.startOfDay(timezone: timezone)
        }()

        let endOfToday: Date = {
            var components = DateComponents()
            components.second = -1
            guard let date = calendar.date(byAdding: components, to: startOfNextDay) else {
                logErrorAndExit("The end of today cannot be calculated from the start of tomorrow \(startOfNextDay) with time zone \(timezone)")
            }
            return date
        }()
        return endOfToday
    }

    // MARK: Week

    /// Returns self's start of week in the given time zone.
    func startOfWeek(timezone: TimeZone, locale: Locale = .current) -> Date? {
        let calendar = createCalendar(timezone: timezone, locale: locale)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)
    }

    /// Returns self's start of week in the given time zone from a supplied calendar.
    func startOfWeek(timezone: TimeZone, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)
    }

    /// Returns self's end of week in the given time zone.
    func endOfWeek(timezone: TimeZone, locale: Locale = .current) -> Date? {
        guard let weekStartDate = startOfWeek(timezone: timezone, locale: locale) else {
            return nil
        }

        let calendar = createCalendar(timezone: timezone, locale: locale)

        guard let nextWeekStartDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartDate) else {
            return nil
        }
        return Date(timeIntervalSince1970: nextWeekStartDate.timeIntervalSince1970 - 1)
    }

    /// Returns self's end of week in the given time zone.
    func endOfWeek(timezone: TimeZone, calendar: Calendar) -> Date? {
        guard let weekStartDate = startOfWeek(timezone: timezone, calendar: calendar) else {
            return nil
        }

        guard let nextWeekStartDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartDate) else {
            return nil
        }
        return Date(timeIntervalSince1970: nextWeekStartDate.timeIntervalSince1970 - 1)
    }

    // MARK: Month

    /// Returns self's start of month in the given time zone.
    func startOfMonth(timezone: TimeZone) -> Date? {
        let calendar = createCalendar(timezone: timezone)
        let components = calendar.dateComponents([.year, .month], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)
    }

    /// Returns self's end of month in the given time zone.
    func endOfMonth(timezone: TimeZone) -> Date? {
        guard let startOfMonth = startOfMonth(timezone: timezone) else {
            return nil
        }

        let calendar = createCalendar(timezone: timezone)
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfMonth)
    }

    // MARK: Quarter

    /// Returns self's start of quarter in the given time zone.
    func startOfQuarter(timezone: TimeZone, calendar: Calendar) -> Date? {
        guard let startOfMonth = startOfMonth(timezone: timezone) else {
            return nil
        }

        var components = calendar.dateComponents([.month, .year], from: startOfMonth)
        switch components.month {
        case 1, 2, 3:
            components.month = 1
        case 4, 5, 6:
            components.month = 4
        case 7, 8, 9:
            components.month = 7
        case 10, 11, 12:
            components.month = 10
        default:
            return nil
        }

        return calendar.date(from: components)
    }

    /// Returns self's end of quarter in the given time zone.
    func endOfQuarter(timezone: TimeZone, calendar: Calendar) -> Date? {
        guard let startOfQuarter = startOfQuarter(timezone: timezone, calendar: calendar) else {
            return nil
        }

        var oneMonthUnit = DateComponents()
        oneMonthUnit.month = 3
        oneMonthUnit.second = -1
        return calendar.date(byAdding: oneMonthUnit, to: startOfQuarter)
    }

    // MARK: Year

    /// Returns self's start of year in the given time zone.
    func startOfYear(timezone: TimeZone) -> Date? {
        let calendar = createCalendar(timezone: timezone)
        let components = calendar.dateComponents([.year], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)
    }

    /// Returns self's end of year in the given time zone.
    func endOfYear(timezone: TimeZone) -> Date? {
        guard let startOfYear = startOfYear(timezone: timezone) else {
            return nil
        }

        let calendar = createCalendar(timezone: timezone)
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfYear)
    }

    private func createCalendar(timezone: TimeZone, locale: Locale = .current) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        calendar.locale = locale
        return calendar
    }
}

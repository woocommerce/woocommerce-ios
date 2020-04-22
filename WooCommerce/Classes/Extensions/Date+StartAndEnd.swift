import Foundation

extension Date {
    // MARK: Day

    /// Returns self's start of day in the given time zone.
    func startOfDay(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        return calendar.startOfDay(for: self)
    }

    /// Returns self's end of day in the given time zone.
    func endOfDay(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(timezone: timezone))!
    }

    // MARK: Week

    /// Returns self's start of week in the given time zone.
    func startOfWeek(timezone: TimeZone, locale: Locale = .current) -> Date {
        let calendar = createCalendar(timezone: timezone, locale: locale)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)!
    }

    /// Returns self's end of week in the given time zone.
    func endOfWeek(timezone: TimeZone, locale: Locale = .current) -> Date {
        let calendar = createCalendar(timezone: timezone, locale: locale)
        let weekStartDate = startOfWeek(timezone: timezone, locale: locale)
        let nextWeekStartDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartDate)!
        return Date(timeIntervalSince1970: nextWeekStartDate.timeIntervalSince1970 - 1)
    }

    // MARK: Month

    /// Returns self's start of month in the given time zone.
    func startOfMonth(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        let components = calendar.dateComponents([.year, .month], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)!
    }

    /// Returns self's end of month in the given time zone.
    func endOfMonth(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfMonth(timezone: timezone))!
    }

    // MARK: Year

    /// Returns self's start of year in the given time zone.
    func startOfYear(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        let components = calendar.dateComponents([.year], from: startOfDay(timezone: timezone))
        return calendar.date(from: components)!
    }

    /// Returns self's end of year in the given time zone.
    func endOfYear(timezone: TimeZone) -> Date {
        let calendar = createCalendar(timezone: timezone)
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfYear(timezone: timezone))!
    }

    private func createCalendar(timezone: TimeZone, locale: Locale = .current) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        calendar.locale = locale
        return calendar
    }
}

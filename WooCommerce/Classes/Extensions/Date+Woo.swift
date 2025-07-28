import Foundation


// MARK: - Date Extensions
//
extension Date {

    /// Returns the String Representation of the receiver, with the specified Date + Time Styles applied.
    /// The string returned will be localised in the device's current locale.
    ///
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale.current
        formatter.timeZone = timeZone

        return formatter.string(from: self)
    }

    /// Same as `toString(dateStyle:timeStyle:)` but in the site time zone.
    /// The string returned will be localized in the device's current locale.
    ///
    func toStringInSiteTimeZone(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, locale: Locale = .current) -> String {
        toString(dateStyle: dateStyle, timeStyle: timeStyle, timeZone: .siteTimezone, locale: locale)
    }

    /// Returns a localized string used for describe a date range string based on two dates. E.g.
    ///
    /// receiver: 2021-01-01
    /// other: 2022-12-31
    /// returns: Jan 1, 2021 - Dec 31, 2022
    ///
    /// receiver: 2021-01-01
    /// other: 2021-01-31
    /// returns: Jan 1 - 31, 2022
    ///
    /// receiver: 2021-01-01
    /// other: 2022-01-01
    /// returns: Jan 1, 2021 - Jan 1, 2022
    ///
    /// receiver: 2022-01-1
    /// other: nil
    /// returns: Jan 1, 2022
    ///
    func formatAsRange(with other: Date? = nil, timezone: TimeZone, calendar: Calendar) -> String {
        guard let other else {
            return DateFormatter.Stats.createDayMonthYearFormatter(timezone: timezone).string(from: self)
        }

        let formattedStart: String
        if self.isSameYear(as: other, using: calendar) {
            formattedStart = DateFormatter.Stats.createDayMonthFormatter(timezone: timezone).string(from: self)
        } else {
            formattedStart = DateFormatter.Stats.createDayMonthYearFormatter(timezone: timezone).string(from: self)
        }

        let formattedEnd: String
        if self.isSameMonth(as: other, using: calendar) {
            formattedEnd = DateFormatter.Stats.createDayYearFormatter(timezone: timezone).string(from: other)
        } else {
            formattedEnd = DateFormatter.Stats.createDayMonthYearFormatter(timezone: timezone).string(from: other)
        }

        return "\(formattedStart) – \(formattedEnd)"
    }

    /// Returns the next midnight starting from `self`.
    ///
    /// For example, if `self` is 2020-01-03 00:41:09, the returned value will be 2020-01-04 00:00:00.
    ///
    /// Returns `nil` if `self` (Date) could not be calculated for some reason. ¯\_(ツ)_/¯
    ///
    func nextMidnight(using calendar: Calendar = .current) -> Date? {
        guard let tomorrowWithTime = calendar.date(byAdding: .day, value: 1, to: self) else {
            return nil
        }

        let components = DateComponents(
            calendar: calendar,
            year: calendar.component(.year, from: tomorrowWithTime),
            month: calendar.component(.month, from: tomorrowWithTime),
            day: calendar.component(.day, from: tomorrowWithTime),
            hour: 0,
            minute: 0,
            second: 0
        )

        return calendar.date(from: components)
    }

    /// Returns `self` plus the given `days` and `seconds` arguments.
    ///
    /// This is generally used for testing. Feel free to add more arguments if needed.
    ///
    func adding(days: Int = 0, seconds: Int = 0, using calendar: Calendar = .current) -> Date? {
        let components = DateComponents(
            calendar: calendar,
            day: days,
            second: seconds
        )

        return calendar.date(byAdding: components, to: self)
    }

    /// Returns `true` if `self` is in the same year as `other`.
    ///
    func isSameYear(as otherDate: Date, using calendar: Calendar = .current) -> Bool {
        guard let selfYear = calendar.dateComponents([.year], from: self).year,
            let otherYear = calendar.dateComponents([.year], from: otherDate).year else {
                return false
        }

        return selfYear == otherYear
    }

    /// Returns `true` if `self` is in the same month as `other`.
    ///
    func isSameMonth(as otherDate: Date, using calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: otherDate, toGranularity: .month)
    }

    /// Returns `true` if `self` is in the same day as `other`.
    ///
    func isSameDay(as other: Date, using calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}

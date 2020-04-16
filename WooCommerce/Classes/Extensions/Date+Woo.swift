import Foundation


// MARK: - Date Extensions
//
extension Date {

    /// Returns the String Representation of the receiver, with the specified Date + Time Styles applied.
    /// The string returned will be localised in the device's current locale.
    ///
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale.current
        formatter.timeZone = timeZone

        return formatter.string(from: self)
    }

    /// Returns a localized update string relative to the receiver if it's within one day of now *or*
    /// a medium datestyle + short timestyle string otherwise.
    ///
    /// *Note:* if the receiver is a future date, "Updated moments ago" will be returned
    ///
    /// - Example: Updated moments ago
    /// - Example: Updated 55 minutes ago
    /// - Example: Updated 1 hour ago
    /// - Example: Updated 14 hours ago
    /// - Example: Updated on Jan 28, 2019 at 5:17 PM
    ///
    var relativelyFormattedUpdateString: String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.year, .month, .weekOfYear, .day, .hour, .minute, .second],
            from: self,
            to: now
        )

        guard let years = components.year, years < 1,
            let months = components.month, months < 1,
            let weeks = components.weekOfYear, weeks < 1,
            let days = components.day, days < 1 else {
                let longFormDate = self.toString(dateStyle: .medium, timeStyle: .short)
                return String.localizedStringWithFormat(Strings.longFormUpdateStatement, longFormDate)
        }

        if let hours = components.hour, hours > 0 {
            return String.pluralize(hours, singular: Strings.singularHourUpdateStatment, plural: Strings.pluralHourUpdateStatment)
        }

        // We only display the minutes update string when we have a time interval greater than 2 minutes...otherwise default to the present deictic expression
        if let minutes = components.minute, minutes > 1 {
            return String.pluralize(minutes, singular: Strings.singularMinuteUpdateStatment, plural: Strings.pluralMinuteUpdateStatment)
        }

        return Strings.presentDeicticExpression
    }

    /// Gets today's date and returns tomorrow's date, starting at midnight.
    ///
    static func tomorrow() -> Date? {
        var dayComponent = DateComponents()
        dayComponent.day = 1
        let calendar = Calendar.current
        let today = Date()

        return calendar.date(byAdding: dayComponent, to: today)
    }

    /// Returns the next midnight starting from `self`.
    ///
    /// For example, if `self` is 2020-01-03 00:41:09, the returned value will be 2020-01-04 00:00:00.
    ///
    /// Returns `nil` if `self` (Date) could not be calculated for some reason. ¯\_(ツ)_/¯
    ///
    func nextMidnight() -> Date? {
        let calendar = Calendar.current

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

    /// Returns `self` plus the given `days`.
    ///
    func adding(days: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: days, to: self)
    }

    /// Returns `true` if `self` is in the same year as `other`.
    ///
    func isSameYear(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        guard let selfYear = calendar.dateComponents([.year], from: self).year,
            let otherYear = calendar.dateComponents([.year], from: otherDate).year else {
                return false
        }

        return selfYear == otherYear
    }
}


// MARK: - Constants!
//
private extension Date {

    enum Strings {
        static let presentDeicticExpression = NSLocalizedString(
            "Updated moments ago",
            comment: "Deictic expression for a data update that occurred in the very recent past - similar to 'Updated just now'"
        )
        static let singularMinuteUpdateStatment = NSLocalizedString(
            "Updated %ld minute ago",
            comment: "Singular of 'minute' — date and time string that represents the time interval since last data update when exactly 1 minute ago. " +
            "Usage example: Updated 1 minute ago"
        )
        static let pluralMinuteUpdateStatment = NSLocalizedString(
            "Updated %ld minutes ago",
            comment: "Plural of 'minute' — date and time string that represents the time interval since last data update when greater than 1 minute ago. " +
            "Usage example: Updated 55 minutes ago"
        )
        static let singularHourUpdateStatment = NSLocalizedString(
            "Updated %ld hour ago",
            comment: "Singular of 'hour' — date and time string that represents the time interval since last data update when exactly 1 hour ago. " +
            "Usage example: Updated 1 hour ago"
        )
        static let pluralHourUpdateStatment = NSLocalizedString(
            "Updated %ld hours ago",
            comment: "Plural of 'hour' — date and time string that represents the time interval since last data update when greater than 1 hour ago. " +
            "Usage example: Updated 14 hours ago"
        )
        static let longFormUpdateStatement = NSLocalizedString(
            "Updated on %@",
            comment: "A specific date and time string which represents when the data was last updated. Usage example: Updated on Jan 22, 2019 3:31PM"
        )
    }
}

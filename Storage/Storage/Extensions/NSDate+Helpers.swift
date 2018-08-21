import Foundation

extension Date {
    /// Returns a NSDate instance with only its Year / Month / Weekday / Day set. Removes the time!
    ///
    public func normalizedDate() -> Date {

        var calendar        = Calendar.current
        calendar.timeZone   = TimeZone.autoupdatingCurrent

        let flags: NSCalendar.Unit = [.day, .weekOfYear, .month, .year]

        let components      = (calendar as NSCalendar).components(flags, from: self)

        var normalized      = DateComponents()
        normalized.year     = components.year
        normalized.month    = components.month
        normalized.weekday  = components.weekday
        normalized.day      = components.day

        return calendar.date(from: normalized) ?? self
    }
}

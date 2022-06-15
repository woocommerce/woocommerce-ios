
import Foundation

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)

    }
    func startOfWeek() -> Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
}

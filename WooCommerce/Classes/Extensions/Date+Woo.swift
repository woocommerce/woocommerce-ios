import Foundation


// MARK: - Date Extensions
//
extension Date {

    /// Returns the String Representation of the receiver, with the specified Date + Time Styles applied.
    ///
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        return formatter.string(from: self)
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
}

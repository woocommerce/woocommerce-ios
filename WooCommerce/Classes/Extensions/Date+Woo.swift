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
}

import Foundation
import Yosemite


/// Encapsulates Storage.Note Interface Helpers: Used for Time Grouping
///
extension StorageNote {

    /// Returns a Section Identifier that can be sorted. Note that this string is not human readable, and
    /// you should convert the `rawValue` into an Age entity (and snap the `description` field).
    ///
    @objc func normalizedAgeAsString() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        let startDate = timestampAsDate.normalizedDate()
        let toDate = Date().normalizedDate()
        let age = Age.from(startDate: startDate, toDate: toDate)

        return age.rawValue
    }

    /// Returns the Timestamp as a Date instance. If parsing fails, this method returns now()
    ///
    private var timestampAsDate: Date {
        guard let timestamp = timestamp, let parsed = DateFormatter.Defaults.iso8601.date(from: timestamp) else {
            return Date()
        }

        return parsed
    }
}

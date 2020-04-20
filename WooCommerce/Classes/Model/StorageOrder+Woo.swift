import Foundation
import WordPressShared
import Yosemite


/// Encapsulates Storage.Order Interface Helpers: Used for Time Grouping
///
extension StorageOrder {

    /// Returns a Section Identifier that can be sorted. Note that this string is not human readable, and
    /// you should convert the `rawValue` into an Age entity (and snap the `description` field).
    ///
    /// This is used to group the sections in `OrdersViewModel`.
    ///
    @objc func normalizedAgeAsString() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        guard let startDate = dateCreated?.normalizedDate() else {
            return ""
        }

        let toDate = Date().normalizedDate()
        let age = Age.from(startDate: startDate, toDate: toDate)

        return age.rawValue
    }
}

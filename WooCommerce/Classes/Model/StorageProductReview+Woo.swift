import Foundation
import Yosemite

/// Encapsulates Storage.ProductReview Interface Helpers: Used for Time Grouping
//
extension StorageProductReview {
    /// Returns a Section Identifier that can be sorted. Note that this string is not human readable, and
    /// you should convert the `rawValue` into an Age entity (and snap the `description` field).
    ///
    @objc func normalizedAgeAsString() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        guard let startDate = dateCreated?.normalizedDate() else {
            return ""
        }

        let toDate = Date().normalizedDate()
        let age = ReviewAge.from(startDate: startDate, toDate: toDate)

        return age.rawValue
    }
}

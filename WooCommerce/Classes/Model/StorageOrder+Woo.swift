import Foundation
import WordPressShared
import Yosemite

extension StorageOrder {
    /// Returns a Section Identifier that can be sorted. Note that this string is not human readable, and
    /// you should use the *descriptionForSectionIdentifier* method as well!.
    ///
    @objc func normalizedAgeAsString() -> String {
        // Normalize Dates: Time must not be considered. Just the raw dates
        guard let fromDate = dateCreated?.normalizedDate() else {
            return ""
        }

        let toDate = Date().normalizedDate()

        // Analyze the Delta-Components
        let calendar = Calendar.current
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let dateComponents = calendar.dateComponents(components, from: fromDate, to: toDate)
        let identifier: Age

        // Months
        if let month = dateComponents.month, month >= 1 {
            identifier = .months
            // Weeks
        } else if let week = dateComponents.weekOfYear, week >= 1 {
            identifier = .weeks
            // Days
        } else if let day = dateComponents.day, day > 1 {
            identifier = .days
        } else if let day = dateComponents.day, day == 1 {
            identifier = .yesterday
        } else {
            identifier = .today
        }

        return identifier.rawValue
    }
}

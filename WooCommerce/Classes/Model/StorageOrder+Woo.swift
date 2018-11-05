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

        // Analyze the Delta-Components
        let components = [.day, .weekOfYear, .month] as Set<Calendar.Component>
        let toDate = Date().normalizedDate()
        let dateComponents = Calendar.current.dateComponents(components, from: fromDate, to: toDate)

        return Age(dateComponents: dateComponents).rawValue
    }
}

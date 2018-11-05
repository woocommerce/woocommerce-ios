import Foundation
import Yosemite


// MARK: - Order Helper Methods
//
extension Order {
    /// Translates a Section Identifier into a Human-Readable String.
    ///
    static func descriptionForSectionIdentifier(_ identifier: String) -> String {
        guard let age = Age(rawValue: identifier) else {
            return String()
        }

        return age.description
    }
}

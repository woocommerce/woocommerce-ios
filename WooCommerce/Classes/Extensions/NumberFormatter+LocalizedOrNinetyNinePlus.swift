
import Foundation

extension NumberFormatter {
    /// Returns `number` as a localized string or “99+” if it is greater than `99`.
    ///
    static func localizedOrNinetyNinePlus(_ number: Int) -> String {
        if number > 99 {
            return Constants.ninetyNinePlus
        } else {
            return localizedString(from: NSNumber(value: number), number: .none)
        }
    }

    private enum Constants {
        static let ninetyNinePlus = NSLocalizedString(
            "99+",
            comment: "This text appears as a label to indicate when a count or number exceeds 99, commonly used in badges, notifications, or counters to show '99+' instead of displaying the exact number." +
                "there are more than 99 items in a tab, like Orders."
        )
    }
}

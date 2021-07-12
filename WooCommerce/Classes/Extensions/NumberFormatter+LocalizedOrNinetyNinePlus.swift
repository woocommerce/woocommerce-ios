
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
            comment: "Please limit to 3 characters if possible. This is used if " +
                "there are more than 99 items in a tab, like Orders."
        )
    }
}


import Foundation

extension NumberFormatter {
    /// Returns `number` as a localized string or “99+” if it is greater than `99`.
    ///
    static func localizedUpToNinetyNine(_ number: Int) -> String {
        if number > 99 {
            return Constants.ninetyNinePlus
        } else {
            return localizedString(from: NSNumber(value: number), number: .none)
        }
    }

    private enum Constants {
        static let ninetyNinePlus = NSLocalizedString(
            "99+",
            comment: "Shown when there are more than 99 items of something (e.g. Processing Orders)."
        )
    }
}

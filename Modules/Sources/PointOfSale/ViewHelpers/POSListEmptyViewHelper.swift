import Foundation

struct POSListEmptyViewHelper {
    /// Whether the empty state shows its illustration.
    ///
    /// The full-size keyboard hides it by default to leave room for the text. A screen can opt in to keep it
    /// on compact width and regular height (phone portrait, or a narrow iPad window that POS lays out like a phone),
    /// where the keyboard is always up while searching and there is still room above it.
    static func showsIcon(isAccessibilitySize: Bool,
                          isFullSizeKeyboardVisible: Bool,
                          showsIconAboveKeyboardOnPhone: Bool,
                          isCompactWidthAndRegularHeight: Bool) -> Bool {
        guard !isAccessibilitySize else {
            return false
        }
        guard isFullSizeKeyboardVisible else {
            return true
        }
        return showsIconAboveKeyboardOnPhone && isCompactWidthAndRegularHeight
    }
}

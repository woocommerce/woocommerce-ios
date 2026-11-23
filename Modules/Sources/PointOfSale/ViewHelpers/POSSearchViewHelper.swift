import Foundation

struct POSSearchViewHelper {
    /// Whether selecting a search result should hide the search keyboard.
    ///
    /// On compact layout the keyboard covers the Cart button, and screens opened from a result
    /// take over the whole screen while the search field behind them keeps the keyboard up.
    /// On regular layout the cart and the detail pane stay visible next to the results.
    static func dismissesKeyboardOnResultSelection(isCompactLayout: Bool) -> Bool {
        isCompactLayout
    }
}

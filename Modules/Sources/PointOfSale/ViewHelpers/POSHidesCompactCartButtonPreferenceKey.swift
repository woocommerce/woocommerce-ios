import SwiftUI

/// Lets the item list ask the POS dashboard to hide the phone cart button while it shows
/// a screen with its own primary button, see `ItemListViewHelper.hidesCompactCartButton`.
struct POSHidesCompactCartButtonPreferenceKey: PreferenceKey {
    static let defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

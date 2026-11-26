import SwiftUI

struct POSHidesCompactCartButtonPreferenceKey: PreferenceKey {
    static let defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Asks the dashboard to hide the compact Cart button while this view is on screen,
    /// because the view already shows its own primary button.
    func posHidesCompactCartButton(_ hides: Bool = true) -> some View {
        preference(key: POSHidesCompactCartButtonPreferenceKey.self, value: hides)
    }
}

import SwiftUI

/// Preference key used by deep child views (e.g. the pushed custom amount form)
/// to ask the POS dashboard to hide its floating control overlay.
///
/// The reducer takes the OR of nested values so any view in the hierarchy that
/// requests hiding wins; siblings that don't set the preference don't override
/// a sibling's request.
struct POSHidesFloatingControlPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Asks the POS dashboard to hide its floating control overlay (the `…` menu and
    /// the card reader connection chip) while this view is on screen.
    func posHidesFloatingControl(_ hides: Bool = true) -> some View {
        preference(key: POSHidesFloatingControlPreferenceKey.self, value: hides)
    }
}

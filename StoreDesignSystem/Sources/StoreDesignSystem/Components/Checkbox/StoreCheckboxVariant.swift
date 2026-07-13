import SwiftUI

/// The visual tone of a ``StoreCheckbox``.
///
/// - Note: A closed type holding only the enabled accent color; the disabled presentation is derived
///   uniformly by ``StoreCheckboxStyle`` from the state-layer rule, so it isn't duplicated per tone.
public struct StoreCheckboxVariant {
    let accent: Color

    private init(accent: Color) {
        self.accent = accent
    }

    /// Default — primary accent.
    public static let `default` = StoreCheckboxVariant(accent: .storePrimary)

    /// Error — for a checkbox in a validation-failure state.
    public static let error = StoreCheckboxVariant(accent: .storeAlertRed)
}

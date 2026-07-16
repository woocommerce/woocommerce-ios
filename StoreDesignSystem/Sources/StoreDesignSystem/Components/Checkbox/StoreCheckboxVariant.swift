import SwiftUI

/// The visual tone of a ``StoreCheckbox``.
///
/// - Note: A closed type holding the enabled accent and its `on`-color (the mark tint); the disabled
///   presentation is derived uniformly by ``StoreCheckboxStyle`` from the state-layer rule, so it
///   isn't duplicated per tone.
public struct StoreCheckboxVariant {
    let accent: Color
    let onColor: Color

    private init(accent: Color, onColor: Color) {
        self.accent = accent
        self.onColor = onColor
    }

    /// Default — primary accent.
    public static let `default` = StoreCheckboxVariant(accent: .storePrimary, onColor: .storeOnPrimary)

    /// Error — for a checkbox in a validation-failure state.
    public static let error = StoreCheckboxVariant(accent: .storeError, onColor: .storeOnError)
}

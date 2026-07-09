import SwiftUI

/// The visual variant of a ``StoreButton``. A closed type holding only the enabled color
/// roles; the disabled presentation is derived uniformly by ``StoreButtonStyle`` from the
/// Figma state-layer rule, so it isn't duplicated per variant.
public struct StoreButtonVariant {
    /// The enabled-state color roles. `background` and `border` are optional: `nil` means
    /// the variant has no fill / no border.
    struct Appearance {
        let background: Color?
        let foreground: Color
        let border: Color?
    }

    let enabled: Appearance

    private init(enabled: Appearance) {
        self.enabled = enabled
    }

    /// Filled — solid primary background. The main action; use once per screen.
    public static let filled = StoreButtonVariant(
        enabled: Appearance(background: .storePrimary, foreground: .storeOnPrimary, border: nil)
    )

    /// Tonal — subtle secondary-container background, for alternative actions.
    public static let tonal = StoreButtonVariant(
        enabled: Appearance(background: .storeSecondaryContainer, foreground: .storeOnSecondaryContainer, border: nil)
    )

    /// Outlined — bordered with a transparent background, for low-emphasis actions.
    public static let outlined = StoreButtonVariant(
        enabled: Appearance(background: nil, foreground: .storeOnSecondaryContainer, border: .storeSecondaryContainer)
    )
}

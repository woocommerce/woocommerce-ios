import SwiftUI

/// The color-coded tone of a ``StoreIconContainer``.
///
/// - Note: A closed type holding the background and foreground color roles per tone. The tones map
///   to the Woo palette ramps, matching the Android `WooIconContainerTone`.
public struct StoreIconContainerTone {
    struct Appearance {
        let background: Color
        let foreground: Color
    }

    let appearance: Appearance

    private init(appearance: Appearance) {
        self.appearance = appearance
    }

    public static let purple = StoreIconContainerTone(
        appearance: Appearance(background: .storePalettePurple0, foreground: .storePalettePurple40)
    )

    public static let sandstone = StoreIconContainerTone(
        appearance: Appearance(background: .storePaletteSandstone10, foreground: .storePaletteSandstone60)
    )

    public static let blue = StoreIconContainerTone(
        appearance: Appearance(background: .storePaletteBlue20, foreground: .storePaletteBlue60)
    )

    public static let green = StoreIconContainerTone(
        appearance: Appearance(background: .storePaletteGreen20, foreground: .storePaletteGreen60)
    )

    public static let orange = StoreIconContainerTone(
        appearance: Appearance(background: .storePaletteOrange20, foreground: .storePaletteOrange60)
    )

    public static let pink = StoreIconContainerTone(
        appearance: Appearance(background: .storePalettePink20, foreground: .storePalettePink60)
    )

    public static let darkPurple = StoreIconContainerTone(
        appearance: Appearance(background: .storePalettePurple40, foreground: .storePalettePurple5)
    )
}

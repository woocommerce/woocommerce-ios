import SwiftUI

/// The color-coded tone of a ``StoreBadge``.
///
/// - Note: A closed type holding the color roles per tone; `background` and `border` are optional
///   (`nil` means no fill / no border). Caution and Warning map to their like-named container
///   tokens, matching the Android `WooBadge`.
public struct StoreBadgeTone {
    struct Appearance {
        let background: Color?
        let foreground: Color
        let border: Color?

        init(background: Color?, foreground: Color, border: Color? = nil) {
            self.background = background
            self.foreground = foreground
            self.border = border
        }
    }

    let appearance: Appearance

    private init(appearance: Appearance) {
        self.appearance = appearance
    }

    public static let error = StoreBadgeTone(
        appearance: Appearance(background: .storeErrorContainer, foreground: .storeOnErrorContainer)
    )

    public static let caution = StoreBadgeTone(
        appearance: Appearance(background: .storeCautionContainer, foreground: .storeOnCautionContainer)
    )

    public static let warning = StoreBadgeTone(
        appearance: Appearance(background: .storeWarningContainer, foreground: .storeOnWarningContainer)
    )

    public static let success = StoreBadgeTone(
        appearance: Appearance(background: .storeSuccessContainer, foreground: .storeOnSuccessContainer)
    )

    public static let info = StoreBadgeTone(
        appearance: Appearance(background: .storeInfoContainer, foreground: .storeOnInfoContainer)
    )

    public static let neutral = StoreBadgeTone(
        appearance: Appearance(background: .storeNeutralContainer, foreground: .storeOnNeutralContainer)
    )

    public static let neutralOutlined = StoreBadgeTone(
        appearance: Appearance(background: nil, foreground: .storeOnSurface, border: .storeStateLayerOnSurfaceOpacity10)
    )
}

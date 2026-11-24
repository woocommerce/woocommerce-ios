import SwiftUI

/// The tone of a ``StoreNoticeBanner``.
///
/// - Note: A closed type holding the color roles for one tone. `background` and `border` are
///   optional (`nil` means no fill / no border); only the neutral-outlined tone is bordered.
public struct StoreNoticeBannerTone: Sendable {
    /// The tone's color roles. `background` and `border` are optional: `nil` means no fill / no border.
    struct Appearance {
        let background: Color?
        let foreground: Color
        let border: Color?
        let actionBackground: Color
        let actionForeground: Color

        init(background: Color?,
             foreground: Color,
             border: Color? = nil,
             actionBackground: Color,
             actionForeground: Color) {
            self.background = background
            self.foreground = foreground
            self.border = border
            self.actionBackground = actionBackground
            self.actionForeground = actionForeground
        }
    }

    let appearance: Appearance

    private init(appearance: Appearance) {
        self.appearance = appearance
    }

    public static let error = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeErrorContainer,
                               foreground: .storeOnErrorContainer,
                               actionBackground: .storeAlertRed,
                               actionForeground: .storeOnAlertRed)
    )

    public static let caution = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeCautionContainer,
                               foreground: .storeOnCautionContainer,
                               actionBackground: .storeAlertOrange,
                               actionForeground: .storeOnAlertOrange)
    )

    public static let warning = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeWarningContainer,
                               foreground: .storeOnWarningContainer,
                               actionBackground: .storeAlertOrange,
                               actionForeground: .storeOnAlertOrange)
    )

    public static let success = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeSuccessContainer,
                               foreground: .storeOnSuccessContainer,
                               actionBackground: .storeAlertGreen,
                               actionForeground: .storeOnAlertGreen)
    )

    public static let info = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeInfoContainer,
                               foreground: .storeOnInfoContainer,
                               actionBackground: .storeAlertBlue,
                               actionForeground: .storeOnAlertBlue)
    )

    public static let neutral = StoreNoticeBannerTone(
        appearance: Appearance(background: .storeNeutralContainer,
                               foreground: .storeOnNeutralContainer,
                               actionBackground: .storePrimary,
                               actionForeground: .storeOnPrimary)
    )

    public static let neutralOutlined = StoreNoticeBannerTone(
        appearance: Appearance(background: nil,
                               foreground: .storeOnNeutralContainer,
                               border: .storeNeutralContainer,
                               actionBackground: .storePrimary,
                               actionForeground: .storeOnPrimary)
    )
}

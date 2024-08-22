import SwiftUI

extension Color {

    // MARK: - Background

    /* POS Background colors are defined in a similar philosophy as system background colors:
     *
     * The first color is intended to be the main background, farthest back.
     * Secondary and tertiary colors are layered on top of the main background, when needed.
     */

    static var posPrimaryBackground: Color {
        Color(
            UIColor(
                light: UIColor(red: 246.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0),
                dark: UIColor(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0, alpha: 1.0)
            )
        )
    }

    static var posSecondaryBackground: Color {
        Color(
            UIColor(
                light: .white,
                dark: .tertiarySystemBackground
            )
        )
    }

    static var posTertiaryBackground: Color {
        Color(
            UIColor(
                light: UIColor(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0, alpha: 1.0),
                dark: .tertiarySystemBackground
            )
        )
    }

    // MARK: - Text

    static var posPrimaryText: Color {
        return Color.primary
    }

    static var toolbarBackground: Color {
        Color(uiColor: .systemBackground)
    }

    static var primaryTint: Color {
        Color(uiColor: .wooCommercePurple(.shade60))
    }

    /// Colors from hi-fi m: p91TBi-bot-p2
    ///
    static var posPrimaryTexti3: Color {
        Color(red: 39.0 / 255.0, green: 27.0 / 255.0, blue: 61.0 / 255.0)
    }

    static var posSecondaryTexti3: Color {
        Color(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, opacity: 0.6)
    }

    static var posSecondaryTextInverted: Color {
        return Color(UIColor(
            light: .secondaryLabel.color(for: .init(userInterfaceStyle: .dark)),
            dark: .secondaryLabel.color(for: .init(userInterfaceStyle: .light)))
        )
    }

    static var posTertiaryTexti3: Color {
        Color(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, opacity: 0.3)
    }

    static var posIconGrayi3: Color {
        return Color.gray
    }

    static var posTotalsSeparator: Color {
        Color(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 200.0 / 255.0)
    }

    static var posPrimaryButtonBackground: Color {
        Color(uiColor: .wooCommercePurple(.shade50))
    }

    static var posSecondaryButtonTint: Color {
        Color(uiColor: .wooCommercePurple(.shade50))
    }

    static var posSecondaryButtonBackground: Color {
        Color(uiColor: .systemBackground)
    }
}

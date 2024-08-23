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
                dark: UIColor(red: 58.0 / 255.0, green: 58.0 / 255.0, blue: 60.0 / 255.0, alpha: 1.0)
            )
        )
    }

    // MARK: - Text

    static var posPrimaryText: Color {
        return Color.primary
    }

    static var posSecondaryText: Color {
        return Self.posGray.opacity(0.6)
    }

    static var posTertiaryText: Color {
        return Self.posGray.opacity(0.3)
    }

    private static var posGray: Color {
        return Color(
            UIColor(
                light: .init(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 1.0),
                dark: .init(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
            )
        )
    }

    // MARK: - Buttons

    static var posPrimaryButtonBackground: Color {
        return Color(
            UIColor(
                light: .withColorStudio(.wooCommercePurple, shade: .shade50),
                dark: .withColorStudio(.wooCommercePurple, shade: .shade30)
            )
        )
    }

    static var posTotalsSeparator: Color {
        Color(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 200.0 / 255.0)
    }

    static var posSecondaryButtonBackground: Color {
        Color(uiColor: .systemBackground)
    }
}

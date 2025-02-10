import SwiftUI

extension Color {

    static var posAccent: Color {
        return Color(
            UIColor(
                light: .withColorStudio(.wooCommercePurple, shade: .shade40),
                dark: .withColorStudio(.wooCommercePurple, shade: .shade30)
            )
        )
    }

    // MARK: - Background

    /* POS Background colors are defined in a similar philosophy as system background colors:
     *
     * The first color is intended to be the main background, farthest back.
     * Secondary and tertiary colors are layered on top of the main background, when needed.
     */

    // An ugly duckling; intended for use for borders where the bordered view has
    // `.posSecondaryBackground` in light mode, even though it's on another `.posSecondaryBackground` view. Does not adapt
    static var posCartItemOutline: Color {
        Color(
            UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 222.0/255.0, alpha: 1.0)
        )
    }

    // MARK: - Text

    private static var posGray: Color {
        return Color(
            UIColor(
                light: UIColor(.posLightGray),
                dark: UIColor(.posDarkGray)
            )
        )
    }
}

// MARK: - Non-adaptive colors

extension Color {
    private static var posLightGray: Color {
        return .init(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0)
    }

    static var posDarkGray: Color {
        return .init(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0)
    }
}

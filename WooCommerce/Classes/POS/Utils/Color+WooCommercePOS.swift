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

    // MARK: - Text

    private static var posGray: Color {
        return Color(
            UIColor(
                light: UIColor(.posLightGray),
                dark: UIColor(.posDarkGray)
            )
        )
    }

    // MARK: - Buttons

    static var posPrimaryButtonBackground: Color = .posAccent

    static var posSecondaryButtonForeground: Color = .posAccent

    static var posTextButtonForeground: Color = .posAccent

    static var posTextButtonForegroundPressed: Color {
        return Color(
            UIColor(
                light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                dark: .withColorStudio(.wooCommercePurple, shade: .shade40)
            )
        )
    }

    static var posTextButtonDisabled: Color {
        return .posGray
    }

    static var posBackgroundButtonDisabled: Color {
        return .init(red: 195.0 / 255.0, green: 196.0 / 255.0, blue: 199.0 / 255.0)
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

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

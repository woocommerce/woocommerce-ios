import SwiftUI

extension Color {

    /// Primary POS background color
    ///
    static var primaryBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    /// Secondary POS background color
    ///
    static var secondaryBackground: Color {
        return Color(red: 89.0 / 255.0, green: 181.0 / 255.0, blue: 227.0 / 255.0)
    }

    /// Tertiary POS background color
    ///
    static var tertiaryBackground: Color {
        return Color(red: 142.0 / 255.0, green: 208.0 / 255.0, blue: 240.0 / 255.0)
    }

    /// POS color: Light Blue
    ///
    static var lightBlue: Color {
        return Color(red: 202.0 / 255.0, green: 237.0 / 255.0, blue: 255.0 / 255.0)
    }

    /// Default POS text color
    ///
    static var primaryText: Color {
        return Color.primary
    }

    static var toolbarBackground: Color {
        Color(uiColor: .systemBackground)
    }

    static var wooAmberShade40: Color {
        Color(red: 255.0 / 255.0, green: 166.0 / 255.0, blue: 14.0 / 255.0)
    }

    static var wooAmberShade80: Color {
        Color(red: 123.0 / 255.0, green: 7.0 / 255.0, blue: 0.0 / 255.0)
    }

    static var totalsTitleColor: Color {
        Color(red: 127.0 / 255.0, green: 84.0 / 255.0, blue: 179.0 / 255.0)
    }
}

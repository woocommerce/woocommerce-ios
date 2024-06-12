import SwiftUI

extension Color {

    /// Primary POS background color
    ///
    static var primaryBackground: Color {
        return Color(red: 24.0 / 255.0, green: 24.0 / 255.0, blue: 24.0 / 255.0)
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
}

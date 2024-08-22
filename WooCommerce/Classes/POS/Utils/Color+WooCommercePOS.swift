import SwiftUI

extension Color {

    /// Secondary POS background color
    ///
    static var secondaryBackground: Color {
        return Color(red: 89.0 / 255.0, green: 181.0 / 255.0, blue: 227.0 / 255.0)
    }

    /// Default POS text color
    ///
    static var primaryText: Color {
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

    static var posBackgroundGreyi3: Color {
        Color(red: 246.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0)
    }

    static var posBackgroundWhitei3: Color {
        Color.white
    }

    static var posBackgroundEmptyWhitei3: Color {
        Color(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 250.0 / 255.0)
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

import UIKit

// MARK: - Base colors.
extension UIColor {
    /// Accent. Pink-50 (< iOS 13 and Light Mode) and Pink-30 (Dark Mode)
    ///
    static var accent: UIColor {
        return UIColor(light: muriel(color: .pink, .shade50),
                        dark: muriel(color: .pink, .shade30))
    }

    /// Accent Dark. Pink-70 (< iOS 13 and Light Mode) and Pink-50 (Dark Mode)
    ///
    static var accentDark: UIColor {
        return UIColor(light: muriel(color: .pink, .shade70),
                        dark: muriel(color: .pink, .shade50))
    }

    /// Brand. WooCommercePurple-60 (all versions of iOS, Light and Dark Mode)
    ///
    static var brand = UIColor.muriel(color: .brand)

    /// Error. Red-50 (< iOS 13 and Light Mode) and Red-30 (Dark Mode)
    ///
    static var error: UIColor {
        return UIColor(light: muriel(color: .red, .shade50),
                        dark: muriel(color: .red, .shade30))
    }

    /// Error Dark. Red-70 (< iOS 13 and Light Mode) and Red-50 (Dark Mode)
    ///
    static var errorDark: UIColor {
        return UIColor(light: muriel(color: .red, .shade70),
                        dark: muriel(color: .red, .shade50))
    }

    /// Primary. WooCommercePurple-60 (< iOS 13 and Light Mode) and WooCommercePurple-30 (Dark Mode)
    ///
    static var primary: UIColor {
        return UIColor(light: muriel(color: .wooCommercePurple, .shade60),
                        dark: muriel(color: .wooCommercePurple, .shade30))
    }

    /// Primary Dark. WooCommercePurple-80 (< iOS 13 and Light Mode) and WooCommercePurple-50 (Dark Mode)
    ///
    static var primaryDark: UIColor {
        return UIColor(light: muriel(color: .wooCommercePurple, .shade80),
                        dark: muriel(color: .wooCommercePurple, .shade50))
    }

    /// Success. Green-50 (< iOS 13 and Light Mode) and Green-30 (Dark Mode)
    ///
    static var success: UIColor {
        return UIColor(light: muriel(color: .green, .shade50),
                        dark: muriel(color: .green, .shade30))
    }

    /// Warning. Yellow-50 (< iOS 13 and Light Mode) and Yellow-30 (Dark Mode)
    ///
    static var warning: UIColor {
        return UIColor(light: muriel(color: .yellow, .shade50),
                        dark: muriel(color: .yellow, .shade30))
    }

    /// Blue. Blue-50 (< iOS 13 and Light Mode) and Blue-30 (Dark Mode)
    ///
    static var blue: UIColor {
        return UIColor(light: muriel(color: .blue, .shade50),
                        dark: muriel(color: .blue, .shade30))
    }

    /// Orange. Orange-50 (< iOS 13 and Light Mode) and Orange-30 (Dark Mode)
    ///
    static var orange: UIColor {
        return UIColor(light: muriel(color: .orange, .shade50),
                        dark: muriel(color: .orange, .shade30))
    }
}


// MARK: - Text Colors.
extension UIColor {
    /// Text. Gray-80 (< iOS 13) and `UIColor.label` (> iOS 13)
    ///
    static var text: UIColor {
        if #available(iOS 13, *) {
            return .label
        }

        return .gray(.shade80)
    }

    /// Text Subtle. Gray-50 (< iOS 13) and `UIColor.secondaryLabel` (> iOS 13)
    ///
    static var textSubtle: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return .gray(.shade50)
    }

    /// Text Tertiary. Gray-20 (< iOS 13) and `UIColor.tertiaryLabel` (> iOS 13)
    ///
    static var textTertiary: UIColor {
        if #available(iOS 13, *) {
            return .tertiaryLabel
        }

        return .gray(.shade20)
    }

    /// Text Quaternary. Gray-10 (< iOS 13) and `UIColor.quaternaryLabel` (> iOS 13)
    ///
    static var textQuaternary: UIColor {
        if #available(iOS 13, *) {
            return .quaternaryLabel
        }

        return .gray(.shade10)
    }

    /// Text Inverted. White(< iOS 13 and Light Mode) and Gray-90 (Dark Mode)
    ///
    static var textInverted: UIColor {
        return UIColor(light: UIColor(hexString: "FFFFFF"),
                       dark: muriel(color: .gray, .shade90))
    }

    /// Text Placeholder. Gray-30 (< iOS 13) and `UIColor.placeholderText` (> iOS 13)
    ///
    static var textPlaceholder: UIColor {
        if #available(iOS 13, *) {
            return .placeholderText
        }

        return .gray(.shade30)
    }
}


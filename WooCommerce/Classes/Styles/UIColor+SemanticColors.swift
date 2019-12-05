import UIKit

// MARK: - Base colors.
extension UIColor {
    /// Accent. Pink-50 (< iOS 13 and Light Mode) and Pink-30 (Dark Mode)
    ///
    static var accent: UIColor {
        return UIColor(light: .withColorStudio(.pink, shade: .shade50),
                       dark: .withColorStudio(.pink, shade: .shade30))
    }

    /// Accent Dark. Pink-70 (< iOS 13 and Light Mode) and Pink-50 (Dark Mode)
    ///
    static var accentDark: UIColor {
        return UIColor(light: .withColorStudio(.pink, shade: .shade70),
                       dark: .withColorStudio(.pink, shade: .shade50))
    }

    /// Brand. WooCommercePurple-60 (all versions of iOS, Light and Dark Mode)
    ///
    static var brand = UIColor.withColorStudio(.brand)

    /// Error. Red-50 (< iOS 13 and Light Mode) and Red-30 (Dark Mode)
    ///
    static var error: UIColor {
        return UIColor(light: .withColorStudio(.red, shade: .shade50),
                        dark: withColorStudio(.red, shade: .shade30))
    }

    /// Error Dark. Red-70 (< iOS 13 and Light Mode) and Red-50 (Dark Mode)
    ///
    static var errorDark: UIColor {
        return UIColor(light: .withColorStudio(.red, shade: .shade70),
                       dark: .withColorStudio(.red, shade: .shade50))
    }

    /// Primary. WooCommercePurple-60 (< iOS 13 and Light Mode) and WooCommercePurple-30 (Dark Mode)
    ///
    static var primary: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
    }

    /// Primary Dark. WooCommercePurple-80 (< iOS 13 and Light Mode) and WooCommercePurple-50 (Dark Mode)
    ///
    static var primaryDark: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade80),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade50))
    }

    /// Success. Green-50 (< iOS 13 and Light Mode) and Green-30 (Dark Mode)
    ///
    static var success: UIColor {
        return UIColor(light: .withColorStudio(.green, shade: .shade50),
                       dark: .withColorStudio(.green, shade: .shade30))
    }

    /// Warning. Yellow-50 (< iOS 13 and Light Mode) and Yellow-30 (Dark Mode)
    ///
    static var warning: UIColor {
        return UIColor(light: .withColorStudio(.yellow, shade: .shade50),
                       dark: .withColorStudio(.yellow, shade: .shade30))
    }

    /// Blue. Blue-50 (< iOS 13 and Light Mode) and Blue-30 (Dark Mode)
    ///
    static var blue: UIColor {
        return UIColor(light: .withColorStudio(.blue, shade: .shade50),
                       dark: .withColorStudio(.blue, shade: .shade30))
    }

    /// Orange. Orange-50 (< iOS 13 and Light Mode) and Orange-30 (Dark Mode)
    ///
    static var orange: UIColor {
        return UIColor(light: .withColorStudio(.orange, shade: .shade50),
                       dark: .withColorStudio(.orange, shade: .shade30))
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
        return UIColor(light: .white,
                       dark: .withColorStudio(.gray, shade: .shade90))
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


// MARK: - UI elements.
extension UIColor {
    /// Basic Background. White (< iOS 13) and `UIColor.systemBackground` (> iOS 13)
    ///
    static var basicBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }

        return .white
    }

    /// App Bar. WooCommercePurple-60 (< iOS 13 and Light Mode) and `UIColor.systemThickMaterial` (Dark Mode)
    ///
    static var appBar: UIColor {
        if #available(iOS 13, *) {
            return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                           dark: .systemBackground)
        }


        return .withColorStudio(.wooCommercePurple, shade: .shade60)
    }

    /// Tab Unselected. Gray-20 (< iOS 13 and Light Mode) and Gray-60 (Dark Mode)
    ///
    static var tabUnselected: UIColor {
        return UIColor(light: .withColorStudio(.gray, shade: .shade20),
                       dark: .withColorStudio(.gray, shade: .shade60))
    }

    /// Divider. Gray-10 (< iOS 13) and `UIColor.separator` (> iOS 13)
    ///
    static var divider: UIColor {
        if #available(iOS 13, *) {
            return .separator
        }

        return .withColorStudio(.gray, shade: .shade10)
    }

    /// Primary Button Background. Resolves to `accent`
    ///
    static var primaryButtonBackground = accent

    /// Primary Button Title.
    ///
    static var primaryButtonTitle: UIColor {
        return .white
    }

    /// Primary Button Highlighted Background.
    ///
    static var primaryButtonDownBackground = accentDark

    /// Primary Button Highlighted Border.
    ///
    static var primaryButtonDownBorder = UIColor.clear

    /// Primary Button Border. Resolves to `accent`
    ///
    static var primaryButtonBorder = accent

    /// Secondary Button Background.
    ///
    static var secondaryButtonBackground: UIColor {
        return UIColor(light: .white,
                       dark: .systemColor(.systemGray5))
    }

    /// Secondary Button Title.
    ///
    static var secondaryButtonTitle: UIColor {
        return .systemColor(.label)
    }

    /// Secondary Button Border.
    ///
    static var secondaryButtonBorder: UIColor {
        return .systemColor(.systemGray3)
    }

    /// Secondary Button Highlighted Background.
    ///
    static var secondaryButtonDownBackground: UIColor {
        return .systemColor(.systemGray3)
    }

    /// Secondary Button Highlighted Border.
    ///
    static var secondaryButtonDownBorder: UIColor {
        return .systemColor(.systemGray3)
    }

    /// Button Disabled Background.
    ///
    static var buttonDisabledBackground: UIColor {
        return .clear
    }

    /// Button Disabled Title.
    ///
    static var buttonDisabledTitle: UIColor {
        return .systemColor(.quaternaryLabel)
    }

    /// Button Disabled Border.
    ///
    static var buttonDisabledBorder: UIColor {
        return .systemColor(.systemGray3)
    }

    /// Filter Bar Selected. `primary` (< iOS 13 and Light Mode) and `UIColor.label` (Dark Mode)
    ///
    static var filterBarSelected: UIColor {
        if #available(iOS 13, *) {
            return UIColor(light: .primary,
                           dark: .label)
        }


        return .primary
    }

    /// Filter Bar Background. `white` (< iOS 13 and Light Mode) and Gray-90 (Dark Mode)
    ///
    static var filterBarBackground: UIColor {
        return UIColor(light: .white,
                       dark: .withColorStudio(.gray, shade: .shade90))
    }

    /// Ghost cell animation end color. `Gray-5` (Light Mode) and Gray-10 (Dark Mode)
    ///
    static var ghostCellAnimationEndColor: UIColor {
        return UIColor(light: .systemColor(.systemGray6),
                       dark: .systemColor(.systemGray5))
    }
}


// MARK: - Table Views.
extension UIColor {
    /// List Icon. Gray-20 (< iOS 13) and `UIColor.secondaryLabel` (> iOS 13)
    ///
    static var listIcon: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return .withColorStudio(.gray, shade: .shade20)
    }

    /// List Small Icon. Gray-20 (< iOS 13) and `UIColor.systemGray` (> iOS 13)
    ///
    static var listSmallIcon: UIColor {
        if #available(iOS 13, *) {
            return .systemGray
        }

        return .withColorStudio(.gray, shade: .shade20)
    }

    /// List BackGround. Gray-0 (< iOS 13) and `UIColor.systemGroupedBackground` (> iOS 13)
    ///
    static var listBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemGroupedBackground
        }

        return .withColorStudio(.gray, shade: .shade0)
    }

    /// List ForeGround. `UIColor.white` (< iOS 13) and `UIColor.secondarySystemGroupedBackground` (> iOS 13)
    ///
    static var listForeground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        }

        return .white
    }

    /// List ForeGround Unread. Blue-0 (< iOS 13) and `UIColor.tertiarySystemGroupedBackground` (> iOS 13)
    ///
    static var listForegroundUnread: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemGroupedBackground
        }

        return .withColorStudio(.blue, shade: .shade0)
    }
}


// MARK: - Grays
extension UIColor {
    /// Muriel gray palette
    /// - Parameter shade: a MurielColorShade of the desired shade of gray
    class func gray(_ shade: ColorStudioShade) -> UIColor {
        return .withColorStudio(.gray, shade: shade)
    }

    /// Muriel neutral colors, which invert in dark mode
    /// - Parameter shade: a MurielColorShade of the desired neutral shade
    static var neutral: UIColor {
        return neutral(.shade50)
    }
    class func neutral(_ shade: ColorStudioShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: .withColorStudio(.gray, shade: .shade0), dark: .withColorStudio(.gray, shade: .shade100))
            case .shade5:
                return UIColor(light: .withColorStudio(.gray, shade: .shade5), dark: .withColorStudio(.gray, shade: .shade90))
            case .shade10:
                return UIColor(light: .withColorStudio(.gray, shade: .shade10), dark: .withColorStudio(.gray, shade: .shade80))
            case .shade20:
                return UIColor(light: .withColorStudio(.gray, shade: .shade20), dark: .withColorStudio(.gray, shade: .shade70))
            case .shade30:
                return UIColor(light: .withColorStudio(.gray, shade: .shade30), dark: .withColorStudio(.gray, shade: .shade60))
            case .shade40:
                return UIColor(light: .withColorStudio(.gray, shade: .shade40), dark: .withColorStudio(.gray, shade: .shade50))
            case .shade50:
                return UIColor(light: .withColorStudio(.gray, shade: .shade50), dark: .withColorStudio(.gray, shade: .shade40))
            case .shade60:
                return UIColor(light: .withColorStudio(.gray, shade: .shade60), dark: .withColorStudio(.gray, shade: .shade30))
            case .shade70:
                return UIColor(light: .withColorStudio(.gray, shade: .shade70), dark: .withColorStudio(.gray, shade: .shade20))
            case .shade80:
                return UIColor(light: .withColorStudio(.gray, shade: .shade80), dark: .withColorStudio(.gray, shade: .shade10))
            case .shade90:
                return UIColor(light: .withColorStudio(.gray, shade: .shade90), dark: .withColorStudio(.gray, shade: .shade5))
            case .shade100:
                return UIColor(light: .withColorStudio(.gray, shade: .shade100), dark: .withColorStudio(.gray, shade: .shade0))
        }
    }
}

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

    /// Primary. WooCommercePurple-60 (< iOS 13 and Light Mode) and WooCommercePurple-30 (Dark Mode)
    ///
    static var primary: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
    }

    /// Warning. Orange-30 (< iOS 13 and Light Mode) and Orange-50 (Dark Mode)
    ///
    static var warning: UIColor {
        return UIColor(light: .withColorStudio(.orange, shade: .shade30),
                       dark: .withColorStudio(.orange, shade: .shade50))
    }

    /// Warning. Orange-5 (< iOS 13 and Light Mode) and Orange-90 (Dark Mode)
    ///
    static var warningBackground: UIColor {
        return UIColor(light: .withColorStudio(.orange, shade: .shade5),
                       dark: .withColorStudio(.orange, shade: .shade90))
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
    /// Text link. Pink-50
    ///
    static var textLink: UIColor {
        return .accent
    }

    /// Text.
    ///
    static var text: UIColor {
        return .label
    }

    /// Text Subtle.
    ///
    static var textSubtle: UIColor {
        return .secondaryLabel
    }

    /// Text Tertiary.
    ///
    static var textTertiary: UIColor {
        return .tertiaryLabel
    }

    /// Text Quaternary.
    ///
    static var textQuaternary: UIColor {
        return .quaternaryLabel
    }

    /// Text Inverted.
    ///
    static var textInverted: UIColor {
        return UIColor(light: .white,
                       dark: .withColorStudio(.gray, shade: .shade90))
    }

    /// Text Placeholder.
    static var textPlaceholder: UIColor {
        return .placeholderText
    }

    /// Cancel Action Text Color.
    ///
    static var modalCancelAction: UIColor {
        return UIColor(light: .accent,
                       dark: .systemColor(.label))
    }

    /// Text.
    ///
    static var textBrand: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
        dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
    }
}


// MARK: - Image Colors.
extension UIColor {
    /// Placeholder image tint color.
    ///
    static var placeholderImage: UIColor {
        return .gray(.shade20)
    }
}

// MARK: - UI elements.
extension UIColor {
    /// Basic Background.
    ///
    static var basicBackground: UIColor {
        return .systemBackground
    }

    /// App Navigation Bar.
    ///
    static var appBar: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                       dark: .systemColor(.secondarySystemGroupedBackground))
    }

    /// App Tab Bar.
    ///
    static var appTabBar: UIColor {
        return UIColor(light: .basicBackground,
        dark: .systemColor(.secondarySystemGroupedBackground))
    }

    /// Divider.
    ///
    static var divider: UIColor {
        return .separator
    }

    /// Primary Button Background. Resolves to `accent`
    ///
    static var primaryButtonBackground = accent

    /// Primary Button Title.
    ///
    static var primaryButtonTitle: UIColor {
        return .white
    }

    /// Primary Button Border.
    ///
    static var primaryButtonBorder = UIColor.clear

    /// Primary Button Highlighted Background.
    ///
    static var primaryButtonDownBackground = accentDark

    /// Primary Button Highlighted Border.
    ///
    static var primaryButtonDownBorder = accentDark

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

    /// Switch disabled color.
    ///
    static var switchDisabledColor: UIColor {
        return .systemColor(.systemGray3)
    }

    /// Ghost cell animation end color. `Gray-5` (Light Mode) and Gray-10 (Dark Mode)
    ///
    static var ghostCellAnimationEndColor: UIColor {
        return UIColor(light: .systemColor(.systemGray6),
                       dark: .systemColor(.systemGray5))
    }

    /// Rating star filled color.
    ///
    static var ratingStarFilled: UIColor {
        return UIColor(light: .withColorStudio(.yellow, shade: .shade30),
                       dark: .withColorStudio(.yellow, shade: .shade50))
    }

    /// Rating star empty color.
    ///
    static var ratingStarEmpty: UIColor {
        return .systemColor(.systemGray4)
    }
}

// MARK: - UI elements.
extension UIColor {
    /// Stats chart data bar color.
    ///
    static var chartDataBar: UIColor {
        return .accent
    }

    /// Stats chart data bar highlighted color.
    ///
    static var chartDataBarHighlighted: UIColor {
        return UIColor(light: .withColorStudio(.pink, shade: .shade70),
                       dark: .withColorStudio(.pink, shade: .shade10))
    }
}

// MARK: - Borders.
extension UIColor {
    /// Default border color.
    ///
    static var border: UIColor {
        return .systemColor(.systemGray4)
    }
}


// MARK: - Table Views.
extension UIColor {
    /// List Icon.
    ///
    static var listIcon: UIColor {
        return .secondaryLabel
    }

    /// List Small Icon.
    ///
    static var listSmallIcon: UIColor {
        return .systemGray
    }

    /// List BackGround.
    ///
    static var listBackground: UIColor {
        return .systemGroupedBackground
    }

    /// List ForeGround.
    ///
    static var listForeground: UIColor {
        return .secondarySystemGroupedBackground
    }
}


// MARK: - Login.
extension UIColor {
    class var alertHeaderImageBackgroundColor: UIColor {
        return UIColor(light: .systemColor(.systemGray6),
                       dark: .systemColor(.systemGray5))
    }

    /// The background color of the authentication prologue bottom area & button container.
    ///
    static var authPrologueBottomBackgroundColor: UIColor {
        return .withColorStudio(.brand, shade: .shade80)
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

// MARK: - Woo Purples
extension UIColor {
    class func wooCommercePurple(_ shade: ColorStudioShade) -> UIColor {
        switch shade {
        case .shade0:
            return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade0), dark: .withColorStudio(.wooCommercePurple, shade: .shade100))
            case .shade5:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade5), dark: .withColorStudio(.wooCommercePurple, shade: .shade90))
            case .shade10:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade10), dark: .withColorStudio(.wooCommercePurple, shade: .shade80))
            case .shade20:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade20), dark: .withColorStudio(.wooCommercePurple, shade: .shade70))
            case .shade30:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade30), dark: .withColorStudio(.wooCommercePurple, shade: .shade60))
            case .shade40:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade40), dark: .withColorStudio(.wooCommercePurple, shade: .shade50))
            case .shade50:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50), dark: .withColorStudio(.wooCommercePurple, shade: .shade40))
            case .shade60:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60), dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
            case .shade70:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade70), dark: .withColorStudio(.wooCommercePurple, shade: .shade20))
            case .shade80:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade80), dark: .withColorStudio(.wooCommercePurple, shade: .shade10))
            case .shade90:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade90), dark: .withColorStudio(.wooCommercePurple, shade: .shade5))
            case .shade100:
                return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade100), dark: .withColorStudio(.wooCommercePurple, shade: .shade0))
        }
    }
}

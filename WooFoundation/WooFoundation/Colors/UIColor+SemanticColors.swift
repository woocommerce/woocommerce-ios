import UIKit

// MARK: - Base colors.
public extension UIColor {
    /// Accent. Purple-50 (Light Mode) and Purple-30 (Dark Mode)
    ///
    static var accent: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
    }

    /// Accent Dark. Purple-70 (Light Mode) and Purple-50 (Dark Mode)
    ///
    static var accentDark: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade80),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade50))
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

    /// Info. Celadon-40 (< iOS 13 and Light Mode) and Green-50 (Dark Mode)
    ///
    static var info: UIColor {
        return UIColor(light: .withColorStudio(.celadon, shade: .shade40),
                       dark: .withColorStudio(.green, shade: .shade50))
    }

    /// Info. Celadon-5 (< iOS 13 and Light Mode) and Green-80 (Dark Mode)
    ///
    static var infoBackground: UIColor {
        return UIColor(light: .withColorStudio(.celadon, shade: .shade5),
                       dark: .withColorStudio(.green, shade: .shade80))
    }

    /// Blue. Blue-50 (< iOS 13 and Light Mode) and Blue-30 (Dark Mode)
    ///
    static var wooBlue: UIColor {
        return UIColor(light: .withColorStudio(.blue, shade: .shade50),
                       dark: .withColorStudio(.blue, shade: .shade30))
    }

    /// Orange. Orange-50 (< iOS 13 and Light Mode) and Orange-30 (Dark Mode)
    ///
    static var wooOrange: UIColor {
        return UIColor(light: .withColorStudio(.orange, shade: .shade50),
                       dark: .withColorStudio(.orange, shade: .shade30))
    }
}


// MARK: - Text Colors.
public extension UIColor {
    /// Text link. Purple-50
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

    /// Text Warning.
    ///
    static var textWarning: UIColor {
        return UIColor(light: .withColorStudio(.orange, shade: .shade50),
                dark: .withColorStudio(.orange, shade: .shade30))
    }
}


// MARK: - Image Colors.
public extension UIColor {
    /// Placeholder image tint color.
    ///
    static var placeholderImage: UIColor {
        return .gray(.shade20)
    }
}

// MARK: - UI elements.
public extension UIColor {
    /// Basic Background.
    ///
    static var basicBackground: UIColor {
        return .systemBackground
    }

    /// App Navigation Bar.
    ///
    static var appBar: UIColor {
        UIColor(light: .white, dark: .black)
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

    /// Primary Button Background.
    ///
    static var primaryButtonBackground: UIColor {
        return UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                       dark: .withColorStudio(.wooCommercePurple, shade: .shade50))
    }

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

    /// Selectable Secondary Button Title.
    ///
    static var selectableSecondaryButtonTitle: UIColor {
        .text
    }

    /// Selectable Secondary Button Background.
    ///
    static var selectableSecondaryButtonBackground: UIColor {
        .init(light: .white,
              dark: .tertiarySystemBackground)
    }

    /// Selectable Secondary Button Border.
    ///
    static var selectableSecondaryButtonBorder: UIColor {
        .init(light: .systemColor(.systemGray3),
              dark: .clear)
    }

    /// Selectable Secondary Button Selected Background.
    ///
    static var selectableSecondaryButtonSelectedBackground: UIColor {
        .init(light: .withColorStudio(.wooCommercePurple, shade: .shade0),
              dark: .tertiarySystemBackground)
    }

    /// Selectable Secondary Button Selected Border.
    ///
    static var selectableSecondaryButtonSelectedBorder: UIColor {
        .init(light: .withColorStudio(.wooCommercePurple, shade: .shade50),
              dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
    }

    /// Secondary Light Button Background.
    ///
    static var secondaryLightButtonBackground: UIColor = .white

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

    /// Ghost cell animation end color. `Gray-6` (Light Mode) and `Gray-4` (Dark Mode)
    ///
    static var ghostCellAnimationEndColor: UIColor {
        return UIColor(light: .systemColor(.systemGray6),
                       dark: .systemColor(.systemGray4))
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

    /// Domain sale price color.
    ///
    static var domainSalePrice: UIColor {
        return UIColor(light: .withColorStudio(.yellow, shade: .shade50),
                       dark: .withColorStudio(.yellow, shade: .shade30))
    }

    /// Domain credit pricing color.
    ///
    static var domainCreditPricing: UIColor {
        return UIColor(light: .withColorStudio(.green, shade: .shade50),
                       dark: .withColorStudio(.green, shade: .shade30))
    }

    /// Color for loading indicators within navigation bars
    ///
    static var navigationBarLoadingIndicator: UIColor {
        .systemGray
    }

    /// SearchBar background color.
    ///
    static var searchBarBackground: UIColor {
        .secondarySystemFill
    }

    /// Fill color for the software update progress animation.
    ///
    static var softwareUpdateProgressFill: UIColor {
        return UIColor(red: 0.498, green: 0.329, blue: 0.702, alpha: 1)
    }

    /// Jetpack benefits banner background color.
    ///
    static var jetpackBenefitsBackground: UIColor {
        UIColor(red: 11.0/255, green: 38.0/255, blue: 33.0/255, alpha: 1)
    }

    /// Jetpack logo color.
    ///
    static var jetpackGreen: UIColor {
        .withColorStudio(.jetpackGreen, shade: .shade20)
    }

    /// Free Trial Banner Background.
    ///
    static var bannerBackground: UIColor {
        .init(light: .withColorStudio(.wooCommercePurple, shade: .shade0),
              dark: .withColorStudio(.wooCommercePurple, shade: .shade90))
    }
}

// MARK: - UI elements.
public extension UIColor {
    /// Stats chart data bar color.
    ///
    static var chartDataBar: UIColor {
        return .accent
    }

    /// Stats highlighted color (chart data bar and text color).
    ///
    static var statsHighlighted: UIColor {
        return UIColor(light: .withColorStudio(.pink, shade: .shade50),
                       dark: .withColorStudio(.pink, shade: .shade30))
    }

    /// Popover background color.
    ///
    static var popoverBackground: UIColor {
        return UIColor(light: .systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                       dark: .wooCommercePurple(.shade70))
    }
}

// MARK: - Borders.
public extension UIColor {
    /// Default border color.
    ///
    static var border: UIColor {
        return .systemColor(.systemGray4)
    }
}


// MARK: - Table Views.
public extension UIColor {
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
        return UIColor(light: .gray(.shade0), dark: .black)
    }

    /// List selected Background.
    ///
    static var listSelectedBackground: UIColor {
        return UIColor(light: UIColor.wooCommercePurple(.shade0), dark: UIColor.wooCommercePurple(.shade10))
    }

    /// List foreground.
    /// - Parameter modal: Whether the view is presented modally. When `true`, returns a darker background in dark mode, for better contrast.
    static func listForeground(modal: Bool) -> UIColor {
        if modal {
            return UIColor(light: .secondarySystemGroupedBackground,
                           dark: .systemGroupedBackground)
        } else {
            return .secondarySystemGroupedBackground
        }
    }

    /// Products tab list cell selected background color
    ///
    static var productsCellSelectedBackgroundColor: UIColor {
        return UIColor.wooCommercePurple(.shade0)
    }
}


// MARK: - Login.
public extension UIColor {
    class var alertHeaderImageBackgroundColor: UIColor {
        return UIColor(light: .systemColor(.systemGray6),
                       dark: .systemColor(.systemGray5))
    }

    /// The background color of the authentication prologue bottom area & button container.
    ///
    static var authPrologueBottomBackgroundColor: UIColor {
        return UIColor(light: .gray(.shade0),
                       dark: .gray(.shade90))
    }
}


// MARK: - Grays
public extension UIColor {
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
public extension UIColor {
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

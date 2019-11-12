import UIKit

// MARK: - Semantic colors.
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

    /// The most basic background: white in light mode, black in dark mode
    static var basicBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return .white
    }

    /// Default text color: high contrast
    static var defaultTextColor: UIColor {
        if #available(iOS 13, *) {
            return .label
        }

        return UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    }

    static var secondaryTextColor: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 60.0/255.0, alpha: 1.0)
    }

    static var highlightTextColor: UIColor {
        return UIColor(light: muriel(color: .blue, .shade50) ,
                        dark: muriel(color: .blue, .shade30))
    }

    static var announcementDotColor: UIColor {
        return UIColor(light: muriel(color: .red, .shade50),
                       dark: muriel(color: .red, .shade50))
    }


    /// Muriel/iOS navigation color
    static var appBar = UIColor.brand

    // MARK: - Table Views

    /// Color for table foregrounds (cells, etc)
    static var listForeground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        }

        return .white
    }

    /// Color for table backgrounds (cells, etc)
    static var listBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemGroupedBackground
        }

        return muriel(color: .gray, .shade0)
    }

    /// For icons that are present in a table view, or similar list
    static var listIcon: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }

        return .neutral(.shade20)
    }

    /// For icons that are present in a toolbar or similar view
    static var toolbarInactive: UIColor {
        if #available(iOS 13, *) {
               return .secondaryLabel
           }

        return .neutral(.shade30)
    }

    /// Note: these values are intended to match the iOS defaults
    static var tabUnselected: UIColor =  UIColor(light: UIColor(hexString: "999999"), dark: UIColor(hexString: "757575"))

}


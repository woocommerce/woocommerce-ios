import UIKit


// MARK: - Style defines the basic API of a Woo Skin.
//
protocol Style {

    /// Fonts
    ///
    var actionButtonTitleFont: UIFont { get }
    var alternativeLoginsTitleFont: UIFont { get }
    var chartLabelFont: UIFont { get }
    var subheadlineFont: UIFont { get }

    /// Colors
    ///
    var buttonPrimaryColor: UIColor { get }
    var buttonPrimaryHighlightedColor: UIColor { get }
    var buttonPrimaryTitleColor: UIColor { get }
    var buttonSecondaryColor: UIColor { get }
    var buttonSecondaryHighlightedColor: UIColor { get }
    var buttonSecondaryTitleColor: UIColor { get }
    var buttonDisabledColor: UIColor { get }
    var buttonDisabledHighlightedColor: UIColor { get }
    var buttonDisabledTitleColor: UIColor { get }
    var cellSeparatorColor: UIColor { get }
    var defaultTextColor: UIColor { get }
    var destructiveActionColor: UIColor { get }
    var sectionBackgroundColor: UIColor { get }
    var sectionTitleColor: UIColor { get }
    var statusDangerColor: UIColor { get }
    var statusDangerBoldColor: UIColor { get }
    var statusNotIdentifiedColor: UIColor { get }
    var statusNotIdentifiedBoldColor: UIColor { get }
    var statusPrimaryColor: UIColor { get }
    var statusPrimaryBoldColor: UIColor { get }
    var statusSuccessColor: UIColor { get }
    var statusSuccessBoldColor: UIColor { get }
    var tableViewBackgroundColor: UIColor { get }
    var goldStarColor: UIColor { get }
    var wooCommerceBrandColor: UIColor { get }
    var wooAccent: UIColor { get }
    var wooGreyLight: UIColor { get }
    var wooGreyMid: UIColor { get }
    var wooGreyTextMin: UIColor { get }
    var wooGreyBorder: UIColor { get }
    var wooSecondary: UIColor { get }
    var wooWhite: UIColor { get }

    /// NavBar
    ///
    var navBarImage: UIImage { get }

    /// StatusBar
    ///
    var statusBarDark: UIStatusBarStyle { get }
    var statusBarLight: UIStatusBarStyle { get }
}


// MARK: - WooCommerce's Default Style
//
class DefaultStyle: Style {

    /// Fonts!
    ///
    let actionButtonTitleFont           = UIFont.font(forStyle: .headline, weight: .semibold)
    let alternativeLoginsTitleFont      = UIFont.font(forStyle: .subheadline, weight: .semibold)
    let subheadlineFont                 = UIFont.font(forStyle: .subheadline, weight: .regular)
    let chartLabelFont                  = UIFont.font(forStyle: .caption2, weight: .ultraLight)

    /// Colors!
    ///
    let buttonPrimaryColor              = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
    let buttonPrimaryHighlightedColor   = UIColor(red: 0x6E/255.0, green: 0x29/255.0, blue: 0x67/255.0, alpha: 0xFF/255.0)
    let buttonPrimaryTitleColor         = HandbookColors.wooWhite
    let buttonSecondaryColor            = HandbookColors.wooWhite
    let buttonSecondaryHighlightedColor = HandbookColors.wooGreyMid
    let buttonSecondaryTitleColor       = HandbookColors.wooGreyMid
    let buttonDisabledColor             = HandbookColors.wooWhite
    let buttonDisabledHighlightedColor  = UIColor(red: 233.0/255.0, green: 239.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    let buttonDisabledTitleColor        = UIColor(red: 233.0/255.0, green: 239.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    let cellSeparatorColor              = HandbookColors.wooGreyBorder
    let defaultTextColor                = HandbookColors.wooSecondary
    let destructiveActionColor          = UIColor(red: 197.0/255.0, green: 60.0/255.0, blue: 53.0/255.0, alpha: 1.0)
    let sectionBackgroundColor          = HandbookColors.wooGreyLight
    let sectionTitleColor               = HandbookColors.wooSecondary
    let tableViewBackgroundColor        = HandbookColors.wooGreyLight
    let goldStarColor                   = UIColor(red: 238.0/255.0, green: 180.0/255.0, blue: 34.0/255.0, alpha: 1.0)

    let statusDangerColor               = HandbookColors.statusRedDimmed
    let statusDangerBoldColor           = HandbookColors.statusRed
    let statusNotIdentifiedColor        = HandbookColors.wooGreyLight
    let statusNotIdentifiedBoldColor    = HandbookColors.wooGreyBorder
    let statusPrimaryColor              = HandbookColors.statusBlueDimmed
    let statusPrimaryBoldColor          = HandbookColors.statusBlue
    let statusSuccessColor              = HandbookColors.statusGreenDimmed
    let statusSuccessBoldColor          = HandbookColors.statusGreen

    let wooCommerceBrandColor           = HandbookColors.wooPrimary
    let wooSecondary                    = HandbookColors.wooSecondary
    let wooAccent                       = HandbookColors.wooAccent
    let wooGreyLight                    = HandbookColors.wooGreyLight
    let wooGreyBorder                   = HandbookColors.wooGreyBorder
    let wooGreyMid                      = HandbookColors.wooGreyMid
    let wooGreyTextMin                  = HandbookColors.wooGreyTextMin
    let wooWhite                        = HandbookColors.wooWhite

    /// NavBar
    ///
    let navBarImage                     = UIImage(named: "woo-logo")!

    /// StatusBar
    ///
    let statusBarDark                   = UIStatusBarStyle.default
    let statusBarLight                  = UIStatusBarStyle.lightContent
}


// MARK: - Handbook colors!
//
private extension DefaultStyle {

    /// Colors as defined in the Woo Mobile Design Handbook
    ///
    enum HandbookColors {
        static let statusRedDimmed       = UIColor(red: 255.0/255.0, green: 230.0/255.0, blue: 229.0/255.0, alpha: 1.0)
        static let statusRed             = UIColor(red: 255.0/255.0, green: 197.0/255.0, blue: 195.0/255.0, alpha: 1.0)
        static let statusBlueDimmed      = UIColor(red: 244.0/255.0, green: 249.0/255.0, blue: 251.0/255.0, alpha: 1.0)
        static let statusBlue            = UIColor(red: 188.0/255.0, green: 222.0/255.0, blue: 238.0/255.0, alpha: 1.0)
        static let statusGreenDimmed     = UIColor(red: 239.00/255.0, green: 249.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        static let statusGreen           = UIColor(red: 201.0/255.0, green: 233.0/255.0, blue: 169.0/255.0, alpha: 1.0)

        static let wooPrimary            = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0)
        static let wooSecondary          = UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        static let wooAccent             = UIColor(red: 113.0/255.0, green: 176.0/255.0, blue: 47.0/255.0, alpha: 1.0)
        static let wooGreyLight          = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        static let wooGreyBorder         = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        static let wooWhite              = UIColor.white
        static let wooGreyMid            = UIColor(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0, alpha: 1.0)
        static let wooGreyTextMin        = UIColor(red: 89.0/255.0, green: 89.0/255.0, blue: 89.0/255.0, alpha: 1.0)
    }
}


// MARK: - StyleManager's Notifications
//
extension NSNotification.Name {
    static let StyleManagerDidUpdateActive = NSNotification.Name(rawValue: "StyleManagerDidUpdateActive")
}


// MARK: - StyleManager: Our "Active Style" Container!
//
class StyleManager {

    private static var active: Style = DefaultStyle() {
        didSet {
            NotificationCenter.default.post(name: .StyleManagerDidUpdateActive, object: self)
        }
    }

    // MARK: - Fonts

    static var actionButtonTitleFont: UIFont {
        return active.actionButtonTitleFont
    }

    static var alternativeLoginsTitleFont: UIFont {
        return active.alternativeLoginsTitleFont
    }

    static var chartLabelFont: UIFont {
        return active.chartLabelFont
    }

    static var subheadlineFont: UIFont {
        return active.subheadlineFont
    }

    // MARK: - Colors

    static var buttonPrimaryColor: UIColor {
        return active.buttonPrimaryColor
    }

    static var buttonPrimaryHighlightedColor: UIColor {
        return active.buttonPrimaryHighlightedColor
    }

    static var buttonPrimaryTitleColor: UIColor {
        return active.buttonPrimaryTitleColor
    }

    static var buttonSecondaryColor: UIColor {
        return active.buttonSecondaryColor
    }

    static var buttonSecondaryHighlightedColor: UIColor {
        return active.buttonSecondaryHighlightedColor
    }

    static var buttonSecondaryTitleColor: UIColor {
        return active.buttonSecondaryTitleColor
    }

    static var buttonDisabledColor: UIColor {
        return active.buttonDisabledColor
    }

    static var buttonDisabledHighlightedColor: UIColor {
        return active.buttonDisabledHighlightedColor
    }

    static var buttonDisabledTitleColor: UIColor {
        return active.buttonDisabledTitleColor
    }

    static var cellSeparatorColor: UIColor {
        return active.cellSeparatorColor
    }

    static var defaultTextColor: UIColor {
        return active.defaultTextColor
    }

    static var destructiveActionColor: UIColor {
        return active.destructiveActionColor
    }

    static var sectionBackgroundColor: UIColor {
        return active.sectionBackgroundColor
    }

    static var sectionTitleColor: UIColor {
        return active.sectionTitleColor
    }

    static var statusDangerColor: UIColor {
        return active.statusDangerColor
    }

    static var statusDangerBoldColor: UIColor {
        return active.statusDangerBoldColor
    }

    static var statusNotIdentifiedColor: UIColor {
        return active.statusNotIdentifiedColor
    }

    static var statusNotIdentifiedBoldColor: UIColor {
        return active.statusNotIdentifiedBoldColor
    }

    static var statusPrimaryColor: UIColor {
        return active.statusPrimaryColor
    }

    static var statusPrimaryBoldColor: UIColor {
        return active.statusPrimaryBoldColor
    }

    static var statusSuccessColor: UIColor {
        return active.statusSuccessColor
    }

    static var statusSuccessBoldColor: UIColor {
        return active.statusSuccessBoldColor
    }

    static var goldStarColor: UIColor {
        return active.goldStarColor
    }

    static var tableViewBackgroundColor: UIColor {
        return active.tableViewBackgroundColor
    }

    static var wooCommerceBrandColor: UIColor {
        return active.wooCommerceBrandColor
    }

    static var wooSecondary: UIColor {
        return active.wooSecondary
    }

    static var wooAccent: UIColor {
        return active.wooAccent
    }

    static var wooGreyLight: UIColor {
        return active.wooGreyLight
    }

    static var wooGreyBorder: UIColor {
        return active.wooGreyBorder
    }

    static var wooGreyMid: UIColor {
        return active.wooGreyMid
    }

    static var wooGreyTextMin: UIColor {
        return active.wooGreyTextMin
    }

    static var wooWhite: UIColor {
        return active.wooWhite
    }

    // MARK: - NavBar

    static var navBarImage: UIImage {
        return active.navBarImage
    }

    // MARK: - StatusBar

    static var statusBarDark: UIStatusBarStyle {
        return active.statusBarDark
    }

    static var statusBarLight: UIStatusBarStyle {
        return active.statusBarLight
    }
}

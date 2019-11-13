import UIKit


// MARK: - Style defines the basic API of a Woo Skin.
//
protocol Style {

    /// Fonts
    ///
    static var maxFontSize: CGFloat { get }
    var actionButtonTitleFont: UIFont { get }
    var alternativeLoginsTitleFont: UIFont { get }
    var badgeFont: UIFont { get }
    var chartLabelFont: UIFont { get }
    var headlineSemiBold: UIFont { get }
    var subheadlineFont: UIFont { get }
    var subheadlineBoldFont: UIFont { get }
    var thinCaptionFont: UIFont { get }
    var footerLabelFont: UIFont { get }

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
    var highlightTextColor: UIColor { get }

    var goldStarColor: UIColor { get }
    var grayStarColor: UIColor { get }
    var yellowStarColor: UIColor { get }

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
    var statusWarningColor: UIColor { get }
    var tableViewBackgroundColor: UIColor { get }
    var tableViewCellSelectionStyle: UIColor { get }
    var noticeIconColor: UIColor { get }

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

    /// Announcement
    ///
    var announcementDotColor: UIColor { get }
}


// MARK: - WooCommerce's Default Style
//
class DefaultStyle: Style {

    /// Fonts!
    ///
    static let maxFontSize              = CGFloat(28.0)
    let actionButtonTitleFont           = UIFont.font(forStyle: .headline, weight: .semibold)
    let alternativeLoginsTitleFont      = UIFont.font(forStyle: .subheadline, weight: .semibold)
    let badgeFont                       = DefaultStyle.fontForTextStyle(.caption2,
                                                                        weight: .regular,
                                                                        maximumPointSize: 12.0)
    let headlineSemiBold                = DefaultStyle.fontForTextStyle(.headline,
                                                                        weight: .semibold,
                                                                        maximumPointSize: DefaultStyle.maxFontSize)
    let subheadlineFont                 = UIFont.font(forStyle: .subheadline, weight: .regular)
    let subheadlineBoldFont             = DefaultStyle.fontForTextStyle(.subheadline,
                                                                        weight: .bold,
                                                                        maximumPointSize: DefaultStyle.maxFontSize)
    let chartLabelFont                  = UIFont.font(forStyle: .caption2, weight: .regular)
    let thinCaptionFont                 = DefaultStyle.fontForTextStyle(.caption1,
                                                                        weight: .thin,
                                                                        maximumPointSize: DefaultStyle.maxFontSize)
    let footerLabelFont                 = DefaultStyle.fontForTextStyle(.footnote,
                                                                        weight: .regular,
                                                                        maximumPointSize: DefaultStyle.maxFontSize)

    /// Colors!
    ///
    let buttonPrimaryColor              = HandbookColors.wooPrimary
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
    let highlightTextColor              = HandbookColors.murielBlue50
    let sectionBackgroundColor          = HandbookColors.wooGreyLight
    let sectionTitleColor               = HandbookColors.wooSecondary
    let tableViewBackgroundColor        = HandbookColors.wooGreyLight
    let tableViewCellSelectionStyle     = UIColor(red: 209.0/255.0, green: 209/255.0, blue: 213/255.0, alpha: 1.0)
    let noticeIconColor                 = HandbookColors.orange50

    let statusDangerColor               = HandbookColors.statusRedDimmed
    let statusDangerBoldColor           = HandbookColors.statusRed
    let statusNotIdentifiedColor        = HandbookColors.wooGreyLight
    let statusNotIdentifiedBoldColor    = HandbookColors.wooGreyBorder
    let statusPrimaryColor              = HandbookColors.statusBlueDimmed
    let statusPrimaryBoldColor          = HandbookColors.statusBlue
    let statusSuccessColor              = HandbookColors.statusGreenDimmed
    let statusSuccessBoldColor          = HandbookColors.statusGreen
    let statusWarningColor              = HandbookColors.statusYellowDimmed

    let wooCommerceBrandColor           = HandbookColors.wooPrimary
    let wooSecondary                    = HandbookColors.wooSecondary
    let wooAccent                       = HandbookColors.wooAccent
    let wooGreyLight                    = HandbookColors.wooGreyLight
    let wooGreyBorder                   = HandbookColors.wooGreyBorder
    let wooGreyMid                      = HandbookColors.wooGreyMid
    let wooGreyTextMin                  = HandbookColors.wooGreyTextMin
    let wooWhite                        = HandbookColors.wooWhite

    /// Stars
    ///
    let goldStarColor                   = HandbookColors.goldStarColor
    let grayStarColor                   = HandbookColors.grayStarColor
    let yellowStarColor                 = HandbookColors.murielYellow30

    /// NavBar
    ///
    let navBarImage                     = UIImage.wooLogoImage()!

    /// StatusBar
    ///
    let statusBarDark                   = UIStatusBarStyle.default
    let statusBarLight                  = UIStatusBarStyle.lightContent

    /// Announcement
    ///
    let announcementDotColor            = HandbookColors.murielRed50
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
        static let statusYellowDimmed    = UIColor(red: 0.97, green: 0.88, blue: 0.68, alpha: 1.0)

        static let wooPrimary            = UIColor(red: 0x96/255.0, green: 0x58/255.0, blue: 0x8A/255.0, alpha: 0xFF/255.0) // woo purple
        static let wooSecondary          = UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        static let wooAccent             = UIColor(red: 113.0/255.0, green: 176.0/255.0, blue: 47.0/255.0, alpha: 1.0)

        // multiple grays
        static let wooGreyLight          = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        static let wooGreyBorder         = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        static let wooWhite              = UIColor.white
        static let wooGreyMid            = UIColor(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0, alpha: 1.0)
        static let wooGreyTextMin        = UIColor(red: 89.0/255.0, green: 89.0/255.0, blue: 89.0/255.0, alpha: 1.0)

        static let goldStarColor         = UIColor(red: 238.0/255.0, green: 180.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        static let grayStarColor         = UIColor(red: 89.0/255.0, green: 89.0/255.0, blue: 89.0/255.0, alpha: 1.0)

        // Muriel theme in https://color-studio.blog/
        static let murielRed50                 = UIColor(red: 0.84, green: 0.21, blue: 0.22, alpha: 1)
        static let murielYellow30        = UIColor(red: 0.86, green: 0.68, blue: 0.09, alpha: 1.0)
        static let murielBlue50          = UIColor(red: 0.13, green: 0.44, blue: 0.69, alpha: 1.0)
        static let orange50              = UIColor(red: 0.70, green: 0.38, blue: 0.00, alpha: 1.0)
    }
}


private extension DefaultStyle {

    class func fontForTextStyle(_ style: UIFont.TextStyle, weight: UIFont.Weight, maximumPointSize: CGFloat = maxFontSize) -> UIFont {
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        if #available(iOS 11, *) {
            var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            fontDescriptor = fontDescriptor.addingAttributes([.traits: traits])
            let fontToGetSize = UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
            return UIFontMetrics(forTextStyle: style).scaledFont(for: fontToGetSize, maximumPointSize: maximumPointSize)
        }

        var scaledFontDescriptor = fontDescriptor(style, maximumPointSize: maximumPointSize)
        scaledFontDescriptor = scaledFontDescriptor.addingAttributes([.traits: traits])
        return UIFont(descriptor: scaledFontDescriptor, size: CGFloat(0.0))
    }


    private class func fontDescriptor(_ style: UIFont.TextStyle, maximumPointSize: CGFloat = maxFontSize) -> UIFontDescriptor {
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let fontToGetSize = UIFont(descriptor: fontDescriptor, size: CGFloat(0.0))
        let scaledFontSize = CGFloat.minimum(fontToGetSize.pointSize, maximumPointSize)
        return fontDescriptor.withSize(scaledFontSize)
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

    static var badgeFont: UIFont {
        return active.badgeFont
    }

    static var chartLabelFont: UIFont {
        return active.chartLabelFont
    }

    static var headlineSemiBold: UIFont {
        return active.headlineSemiBold
    }

    static var subheadlineFont: UIFont {
        return active.subheadlineFont
    }

    static var subheadlineBoldFont: UIFont {
        return active.subheadlineBoldFont
    }

    static var thinCaptionFont: UIFont {
        return active.thinCaptionFont
    }

    static var footerLabelFont: UIFont {
        return active.footerLabelFont
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

    static var noticeIconColor: UIColor {
        return active.noticeIconColor
    }

    static var highlightTextColor: UIColor {
        return active.highlightTextColor
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

    static var statusWarningColor: UIColor {
        return active.statusWarningColor
    }

    static var goldStarColor: UIColor {
        return active.goldStarColor
    }

    static var yellowStarColor: UIColor {
        return active.yellowStarColor
    }

    static var tableViewBackgroundColor: UIColor {
        return active.tableViewBackgroundColor
    }

    static var tableViewCellSelectionStyle: UIColor {
        return active.tableViewCellSelectionStyle
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

    static var grayStarColor: UIColor {
        return active.grayStarColor
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

    // MARK: - Announcement

    static var announcementDotColor: UIColor {
        return active.announcementDotColor
    }
}

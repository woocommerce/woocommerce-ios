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



    /// NavBar
    ///
    let navBarImage                     = UIImage.wooLogoImage()!

    /// StatusBar
    ///
    let statusBarDark                   = UIStatusBarStyle.default
    let statusBarLight                  = UIStatusBarStyle.lightContent
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

import UIKit

// MARK: - StyleManager: Our Style Container!
//
final class StyleManager {
    private static let maxFontSize = CGFloat(28.0)

    // MARK: - Fonts
    static var actionButtonTitleFont: UIFont {
        return .font(forStyle: .headline, weight: .semibold)
    }

    static var statsFont: UIFont {
        return .font(forStyle: .title3, weight: .semibold, maxFontSize: 36.0)
    }

    static var statsTitleFont: UIFont {
        return .font(forStyle: .caption2, weight: .regular, maxFontSize: maxFontSize)
    }

    static var chartLabelFont: UIFont {
        // Dashboard chart needs from a slighly smaller maximum font to be able to fit it when using the biggest accessibility font.
        return .font(forStyle: .caption2, weight: .regular, maxFontSize: 20.0)
    }

    static var headlineSemiBold: UIFont {
        return .font(forStyle: .headline, weight: .semibold, maxFontSize: maxFontSize)
    }

    static var subheadlineFont: UIFont {
        return .font(forStyle: .subheadline, weight: .regular)
    }

    static var subheadlineSemiBoldFont: UIFont {
        return .font(forStyle: .subheadline, weight: .semibold)
    }

    static var subheadlineBoldFont: UIFont {
        return .font(forStyle: .subheadline, weight: .bold, maxFontSize: maxFontSize)
    }

    static var thinCaptionFont: UIFont {
        return .font(forStyle: .caption1, weight: .thin, maxFontSize: maxFontSize)
    }

    static var footerLabelFont: UIFont {
        return .font(forStyle: .footnote, weight: .regular, maxFontSize: maxFontSize)

    }

    // MARK: - NavBar
    static var navBarImage: UIImage {
        return UIImage.wooLogoImage()!
    }

    // MARK: - StatusBar
    static var statusBarLight: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

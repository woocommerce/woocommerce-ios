import UIKit

// MARK: - StyleManager: Our Style Container!
//
final class StyleManager {
    private static let maxFontSize = CGFloat(28.0)


    // MARK: - Fonts
    static var actionButtonTitleFont: UIFont {
        return .font(forStyle: .headline, weight: .semibold)
    }

    static var alternativeLoginsTitleFont: UIFont {
        return .font(forStyle: .subheadline, weight: .semibold)
    }

    static var badgeFont: UIFont {
        return self.fontForTextStyle(.caption2,
        weight: .regular,
        maximumPointSize: 12.0)
    }

    static var chartLabelFont: UIFont {
        return .font(forStyle: .caption2, weight: .regular)
    }

    static var headlineSemiBold: UIFont {
        return self.fontForTextStyle(.headline,
        weight: .semibold,
        maximumPointSize: maxFontSize)
    }

    static var subheadlineFont: UIFont {
        return .font(forStyle: .subheadline, weight: .regular)
    }

    static var subheadlineBoldFont: UIFont {
        return self.fontForTextStyle(.subheadline,
        weight: .bold,
        maximumPointSize: maxFontSize)
    }

    static var thinCaptionFont: UIFont {
        return self.fontForTextStyle(.caption1,
        weight: .thin,
        maximumPointSize: maxFontSize)
    }

    static var footerLabelFont: UIFont {
        return self.fontForTextStyle(.footnote,
        weight: .regular,
        maximumPointSize: maxFontSize)

    }

    // MARK: - NavBar
    static var navBarImage: UIImage {
        return UIImage.wooLogoImage()!
    }

    // MARK: - StatusBar
    static var statusBarDark: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    static var statusBarLight: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}


// MARK: - Private convenience methods
private extension StyleManager {
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

import UIKit


/// WooCommerce UIFont Constants
///
extension UIFont {
    static var largeTitle: UIFont {
        return .preferredFont(forTextStyle: .largeTitle)
    }

    static var title1: UIFont {
        return .preferredFont(forTextStyle: .title1)
    }

    static var title2: UIFont {
        return .preferredFont(forTextStyle: .title2)
    }

    static var title2SemiBold: UIFont {
        return font(forStyle: .title2, weight: .semibold)
    }

    static var title3: UIFont {
        return .preferredFont(forTextStyle: .title3)
    }

    static var headline: UIFont {
        return .preferredFont(forTextStyle: .headline)
    }

    static var subheadline: UIFont {
        return .preferredFont(forTextStyle: .subheadline)
    }

    static var body: UIFont {
        return .preferredFont(forTextStyle: .body)
    }

    static var callout: UIFont {
        return .preferredFont(forTextStyle: .callout)
    }

    static var footnote: UIFont {
        return .preferredFont(forTextStyle: .footnote)
    }

    static var caption1: UIFont {
        return .preferredFont(forTextStyle: .caption1)
    }

    static var caption2: UIFont {
        return .preferredFont(forTextStyle: .caption2)
    }
}


/// WooCommerce UIFont Helpers
///
extension UIFont {

    /// Returns a Noticons UIFont instance with the specified Style.
    ///
    static func noticon(forStyle style: UIFont.TextStyle) -> UIFont {
        let name = "Noticons"
        let size = pointSize(for: style)
        return UIFont(name: name, size: size)!
    }

    /// Returns a Noticons UIFont instance with the specified text style based on the specified size.
    ///
    /// - Parameters:
    ///   - style: The text style to apply to the font.
    ///   - baseSize: this size corresponds to the font size at the 4th stop of font size from the smallest for `body` text style and the 3rd stop for `title1`
    ///     text style.
    /// - Returns: A Noticons font that scales to support Dynamic Type.
    static func noticon(forStyle style: UIFont.TextStyle, baseSize: CGFloat) -> UIFont {
        guard let noticonFont = UIFont(name: "Noticons", size: baseSize) else {
            fatalError("Failed to load the 'Noticons' font.")
        }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: noticonFont)
    }

    /// Returns a UIFont instance for the specified Style + Weight.
    ///
    class func font(forStyle style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let targetSize = pointSize(for: style)
        return UIFont.systemFont(ofSize: targetSize, weight: weight)
    }

    /// Returns the System's Point Size for the specified Style.
    ///
    private class func pointSize(for style: UIFont.TextStyle) -> CGFloat {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let initialFont = UIFont(descriptor: descriptor, size: CGFloat(0.0))
        let scaledFont = UIFontMetrics(forTextStyle: style).scaledFont(for: initialFont)

        return scaledFont.pointSize
    }
}

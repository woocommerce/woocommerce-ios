import UIKit

/// Disposable Class to find this `Bundle` at runtime
///
internal class WooFoundationBundleClass {}

public extension UIColor {

    /// Get a UIColor from the Color Studio color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a ColorStudio
    /// - Returns: UIColor. Red in cases of error
    class func withColorStudio(_ colorStudio: ColorStudio) -> UIColor {
        let assetName = colorStudio.assetName()
        let color = UIColor(named: assetName, in: Bundle(for: WooFoundationBundleClass.self), compatibleWith: nil)

        guard let unwrappedColor = color else {
            return .red
        }

        return unwrappedColor
    }
    /// Get a UIColor from the Color Studio color palette, adjusted to a given shade
    /// - Parameter color: an instance of a ColorStudio
    /// - Parameter shade: a ColorStudioShade
    class func withColorStudio(_ colorStudio: ColorStudio, shade: ColorStudioShade) -> UIColor {
        let newColor = ColorStudio(from: colorStudio, shade: shade)
        return withColorStudio(newColor)
    }
}


public extension UIColor {
    // A way to create dynamic colors that's compatible with iOS 11 & 12
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
    }

    convenience init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

public extension UIColor {
    func color(for trait: UITraitCollection?) -> UIColor {
        if let trait = trait {
            return resolvedColor(with: trait)
        }
        return self
    }
}

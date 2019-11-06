import UIKit

extension UIColor {
    // A way to create dynamic colors that's compatible with iOS 11 & 12
    convenience init(light: UIColor, dark: UIColor) {
        if #available(iOS 13, *) {
            self.init { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            // in older versions of iOS, we assume light mode
            self.init(color: light)
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

extension UIColor {
    func color(for trait: UITraitCollection?) -> UIColor {
        if #available(iOS 13, *), let trait = trait {
            return resolvedColor(with: trait)
        }
        return self
    }
}

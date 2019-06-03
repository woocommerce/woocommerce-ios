import UIKit

extension UIColor {

    /// Creates a new `UIImage` using the current `UIColor` as the fill
    ///
    /// - Parameter size: Size of the image returned — defaults to 1x1
    /// - Returns: UIImage instance
    ///
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }

    func fullAlphaColor(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}

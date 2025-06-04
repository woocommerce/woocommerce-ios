import UIKit

public extension UIImage {
    /// Adds a background color to the given UIImage, setting also whether it should be opaque or not
    ///
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

        guard let currentContext = UIGraphicsGetCurrentContext(),
              let image = cgImage else {
            return self
        }

        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        currentContext.setFillColor(color.cgColor)
        currentContext.fill(rect)

        // Because the coordinate system in Core Graphics is different from that of UIKit,
        // we need to flip the context vertically, and then translate it vertically
        currentContext.scaleBy(x: 1, y: -1)
        currentContext.translateBy(x: 0, y: -size.height)
        currentContext.draw(image, in: rect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

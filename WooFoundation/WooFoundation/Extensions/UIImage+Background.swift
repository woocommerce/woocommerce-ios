import UIKit

public extension UIImage {
    /// Adds a background color to the given UIImage, setting also whether it should be opaque or not
    /// 
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
      UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

      guard let ctx = UIGraphicsGetCurrentContext(),
                let image = cgImage else {
          return self
      }

      defer { UIGraphicsEndImageContext() }

      let rect = CGRect(origin: .zero, size: size)
      ctx.setFillColor(color.cgColor)
      ctx.fill(rect)
      ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
      ctx.draw(image, in: rect)

      return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

import UIKit

extension UIImage {
    /// Draws a dot at the top right corner of a new image along with the original image.
    ///
    /// - Parameters:
    ///   - imageOrigin: the origin where self image is located.
    ///   - finalSize: the size of the returned image.
    ///   - dotDiameter: the diameter of the dot.
    ///   - dotColor: the color of the dot.
    /// - Returns: an image with the original image at the given origin and a dot at the top right of the given diameter and color.
    func imageWithTopRightDot(imageOrigin: CGPoint,
                              finalSize: CGSize,
                              dotDiameter: CGFloat = 7,
                              dotColor: UIColor = .error) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(finalSize, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()

        // Dot at the top right corner.
        let path = UIBezierPath(ovalIn: CGRect(x: finalSize.width - dotDiameter,
                                               y: 0,
                                               width: dotDiameter,
                                               height: dotDiameter))
        dotColor.setFill()
        path.fill()

        // Draws the original image at the given origin.
        draw(at: imageOrigin)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        // Restores the previous drawing context of the original image.
        context.restoreGState()
        UIGraphicsEndImageContext()

        return newImage
    }
}

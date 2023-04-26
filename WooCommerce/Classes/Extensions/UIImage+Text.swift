import UIKit

extension UIImage {
    /// Creates an image from the given text and size.
    /// - Parameters:
    ///   - text: Text to be shown in the image. The font size is scaled to fit the size.
    ///   - size: The size of the image.
    /// - Returns: An image with the given text and size, if available.
    static func image(fromText text: String, size: CGSize) -> UIImage? {
        let attributedString = NSAttributedString(string: text,
                                                  attributes: [
                                                    .font: UIFont.systemFont(ofSize: min(size.width, size.height))
                                                  ])

        // Renders the attributed string to an image.
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        attributedString.draw(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

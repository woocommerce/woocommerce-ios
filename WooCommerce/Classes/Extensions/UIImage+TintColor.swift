import UIKit

extension UIImage {
    /// Returns an image with a tint color applied to the original image.
    /// For the image to react to Light/Dark mode changes in iOS 13+, we have to call the iOS 13+ API `withTintColor`.
    ///
    func applyTintColor(_ color: UIColor) -> UIImage? {
        guard #available(iOS 13.0, *) else {
            return imageWithTintColor(color)
        }
        return withTintColor(color)
    }
}

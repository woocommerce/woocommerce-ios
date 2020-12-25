import UIKit

extension UIImage {
    /// If iOS 13+, returns an image with a tint color applied to the original image.
    /// For the image to react to Light/Dark mode changes in iOS 13+, we have to call the iOS 13+ API `withTintColor`.
    ///
    func applyTintColorToiOS13(_ color: UIColor) -> UIImage? {
        return withTintColor(color)
    }

    /// Returns an image with a tint color applied to the original image.
    ///
    func applyTintColor(_ color: UIColor) -> UIImage? {
        return withTintColor(color)
    }
}

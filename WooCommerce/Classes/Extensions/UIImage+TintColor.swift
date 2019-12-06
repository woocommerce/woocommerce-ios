import UIKit

extension UIImage {
    /// If iOS 13+, returns an image with a tint color applied to the original image.
    /// For the image to react to Light/Dark mode changes in iOS 13+, we have to call the iOS 13+ API `withTintColor`.
    ///
    func applyTintColorToiOS13(_ color: UIColor) -> UIImage? {
        guard #available(iOS 13.0, *) else {
            return self
        }
        return withTintColor(color)
    }
}

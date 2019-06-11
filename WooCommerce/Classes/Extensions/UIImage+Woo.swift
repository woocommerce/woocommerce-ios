import Foundation
import UIKit
import Gridicons


/// WooCommerce UIImage Assets
///
extension UIImage {

    /// WooCommerce Styled Checkmark
    ///
    static var checkmarkImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.checkmark).imageWithTintColor(tintColor)!
    }

    /// Chevron pointing right
    ///
    static var chevronImage: UIImage {
        let tintColor = StyleManager.wooGreyMid
        return Gridicon.iconOfType(.chevronRight).imageWithTintColor(tintColor)!
    }

    /// Product Placeholder Image
    ///
    static var productPlaceholderImage: UIImage {
        let tintColor = StyleManager.wooGreyLight
        return Gridicon.iconOfType(.product).imageWithTintColor(tintColor)!
    }

    /// Gravatar Placeholder Image
    ///
    static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }

    /// Pencil Icon
    ///
    static var pencilImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.pencil)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Delete icon
    ///
    static var deleteImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.crossCircle)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// More icon
    ///
    static var moreImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.ellipsis)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Jetpack Logo Image
    ///
    static var jetpackLogoImage: UIImage {
        return UIImage(named: "icon-jetpack-gray")!
    }

    /// Creates a bitmap image of the Woo "bubble" logo based on a vector image in our asset catalog.
    ///
    /// - Parameters:
    ///   - size: desired size of the resulting bitmap image
    ///   - tintColor: desired tint color of the resulting bitmap image
    /// - Returns: a bitmap image
    ///
    static func wooLogoImage(withSize size: CGSize = Metrics.defaultWooLogoSize, tintColor: UIColor = .white) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        let vectorImage = UIImage(named: "woo-logo")!
        let renderer = UIGraphicsImageRenderer(size: size)
        let im2 = renderer.image { ctx in
            vectorImage.draw(in: rect)
        }

        return im2.imageWithTintColor(tintColor)
    }

    /// Error State Image
    ///
    static var errorStateImage: UIImage {
        return UIImage(named: "woo-error-state")!
    }

    /// Waiting for Customers Image
    ///
    static var waitingForCustomersImage: UIImage {
        return UIImage(named: "woo-waiting-customers")!
    }

    /// Quote Image
    ///
    static var quoteImage: UIImage {
        return Gridicon.iconOfType(.quote)
    }

    /// Add Icon
    ///
    static var addOutlineImage: UIImage {
        return Gridicon.iconOfType(.addOutline)
    }

    /// Camera Icon
    ///
    static var cameraImage: UIImage {
        return Gridicon.iconOfType(.camera)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// External link Icon
    static var external: UIImage {
        return Gridicon.iconOfType(.external)
            .imageFlippedForRightToLeftLayoutDirection()
    }
}

private extension UIImage {

    enum Metrics {
        static let defaultWooLogoSize = CGSize(width: 30, height: 18)
    }
}

import Foundation
import UIKit
import Gridicons


/// WooCommerce UIImage Assets
///
extension UIImage {

    /// Add Icon
    ///
    static var addOutlineImage: UIImage {
        return Gridicon.iconOfType(.addOutline)
    }

    /// Aside Image
    ///
    static var asideImage: UIImage {
        return Gridicon.iconOfType(.aside)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Bell Icon
    ///
    static var bellImage: UIImage {
        return Gridicon.iconOfType(.bell)
    }

    /// Camera Icon
    ///
    static var cameraImage: UIImage {
        return Gridicon.iconOfType(.camera)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Checkmark image, no style applied
    ///
    static var checkmarkImage: UIImage {
        return Gridicon.iconOfType(.checkmark)
    }

    /// WooCommerce Styled Checkmark
    ///
    static var checkmarkStyledImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return checkmarkImage.imageWithTintColor(tintColor)!
    }

    /// Chevron Pointing Right
    ///
    static var chevronImage: UIImage {
        let tintColor = StyleManager.wooGreyMid
        return Gridicon.iconOfType(.chevronRight).imageWithTintColor(tintColor)!
    }

    /// Chevron Pointing Down
    ///
    static var chevronDownImage: UIImage {
        return Gridicon.iconOfType(.chevronDown)
    }

    /// Chevron Pointing Up
    ///
    static var chevronUpImage: UIImage {
        return Gridicon.iconOfType(.chevronUp)
    }

    /// Cog Icon
    ///
    static var cogImage: UIImage {
        return Gridicon.iconOfType(.cog)
    }

    /// Delete Icon
    ///
    static var deleteImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.crossCircle)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Ellipsis Icon
    ///
    static var ellipsisImage: UIImage {
        return Gridicon.iconOfType(.ellipsis)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Error State Image
    ///
    static var errorStateImage: UIImage {
        return UIImage(named: "woo-error-state")!
    }

    /// External Link Icon
    ///
    static var externalImage: UIImage {
        return Gridicon.iconOfType(.external)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Filter Icon
    ///
    static var filterImage: UIImage {
        return Gridicon.iconOfType(.filter)
    }

    /// Gravatar Placeholder Image
    ///
    static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }

    /// Heart Outline
    ///
    static var heartOutlineImage: UIImage {
        return Gridicon.iconOfType(.heartOutline)
    }

    /// Jetpack Logo Image
    ///
    static var jetpackLogoImage: UIImage {
        return UIImage(named: "icon-jetpack-gray")!
    }

    /// Invisible Image
    ///
    static var invisibleImage: UIImage {
        return Gridicon.iconOfType(.image)
    }

    /// Mail Icon
    ///
    static var mailImage: UIImage {
        return Gridicon.iconOfType(.mail)
    }

    /// More Icon
    ///
    static var moreImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return ellipsisImage.imageWithTintColor(tintColor)!
    }

    /// Product Placeholder Image
    ///
    static var productPlaceholderImage: UIImage {
        let tintColor = StyleManager.wooGreyLight
        return Gridicon.iconOfType(.product).imageWithTintColor(tintColor)!
    }

    /// Product Image
    ///
    static var productImage: UIImage {
        return Gridicon.iconOfType(.product)
    }

    /// Pencil Icon
    ///
    static var pencilImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.pencil)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Quote Image
    ///
    static var quoteImage: UIImage {
        return Gridicon.iconOfType(.quote)
    }

    /// Pages Icon
    ///
    static var pagesImage: UIImage {
        return Gridicon.iconOfType(.pages)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Search Icon
    ///
    static var searchImage: UIImage {
        return Gridicon.iconOfType(.search)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Spam Icon
    ///
    static var spamImage: UIImage {
        return Gridicon.iconOfType(.spam)
    }

    /// Returns a star icon with the given size and color
    ///
    /// - Parameters:
    ///   - size: desired size of the resulting star icon
    ///   - tintColor: desired tint color of the resulting icon
    /// - Returns: a bitmap image
    ///
    static func starImage(size: Double, tintColor: UIColor) -> UIImage {
        let starSize = CGSize(width: size, height: size)
        return Gridicon.iconOfType(.star,
                                   withSize: starSize)
            .imageWithTintColor(tintColor)!
    }

    /// Returns a star outline icon with the given size and color
    ///
    /// - Parameters:
    ///   - size: desired size of the resulting star icon
    ///   - tintColor: desired tint color of the resulting icon
    /// - Returns: a bitmap image
    ///
    static func starOutlineImage(size: Double, tintColor: UIColor) -> UIImage {
        let starSize = CGSize(width: size, height: size)
        return Gridicon.iconOfType(.starOutline,
                                   withSize: starSize)
            .imageWithTintColor(tintColor)!
    }

    /// Stats Icon
    ///
    static var statsImage: UIImage {
        return Gridicon.iconOfType(.stats)
        .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Stats Alt Icon
    ///
    static var statsAltImage: UIImage {
        return Gridicon.iconOfType(.statsAlt)
        .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Trash Can Icon
    ///
    static var trashImage: UIImage {
        return Gridicon.iconOfType(.trash)
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

    /// Waiting for Customers Image
    ///
    static var waitingForCustomersImage: UIImage {
        return UIImage(named: "woo-waiting-customers")!
    }
}

private extension UIImage {

    enum Metrics {
        static let defaultWooLogoSize = CGSize(width: 30, height: 18)
    }
}

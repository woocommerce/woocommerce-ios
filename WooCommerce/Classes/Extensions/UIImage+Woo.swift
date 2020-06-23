import Foundation
import UIKit
import Gridicons


/// WooCommerce UIImage Assets
///
extension UIImage {

    /// Add Icon
    ///
    static var addOutlineImage: UIImage {
        return UIImage.gridicon(.addOutline)
    }

    /// Notice Icon
    ///
    static var noticeImage: UIImage {
        let tintColor = UIColor.listIcon
        return UIImage.gridicon(.notice).imageWithTintColor(tintColor)!
    }

    /// Aside Image
    ///
    static var asideImage: UIImage {
        return UIImage.gridicon(.aside)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Bell Icon
    ///
    static var bellImage: UIImage {
        return UIImage.gridicon(.bell)
    }

    /// Brief Description Icon
    ///
    static var briefDescriptionImage: UIImage {
        return UIImage.gridicon(.alignLeft, size: CGSize(width: 24, height: 24)).imageFlippedForRightToLeftLayoutDirection()
    }

    /// Camera Icon
    ///
    static var cameraImage: UIImage {
        return UIImage.gridicon(.camera)
            .imageFlippedForRightToLeftLayoutDirection()
            .applyTintColor(.placeholderImage)!
    }

    /// Product categories Icon
    ///
    static var categoriesIcon: UIImage {
        return UIImage.gridicon(.folder).imageFlippedForRightToLeftLayoutDirection()
    }

    /// Add Image icon
    ///
    static var addImage: UIImage {
        let tintColor = UIColor.neutral(.shade40)
        return UIImage.gridicon(.addImage).imageWithTintColor(tintColor)!
    }

    /// Checkmark image, no style applied
    ///
    static var checkmarkImage: UIImage {
        return UIImage.gridicon(.checkmark)
    }

    /// WooCommerce Styled Checkmark
    ///
    static var checkmarkStyledImage: UIImage {
        let tintColor = UIColor.primary
        return checkmarkImage.imageWithTintColor(tintColor)!
    }

    /// Chevron Pointing Right
    ///
    static var chevronImage: UIImage {
        let tintColor = UIColor.neutral(.shade40)
        return UIImage.gridicon(.chevronRight).imageWithTintColor(tintColor)!
    }

    /// Chevron Pointing Down
    ///
    static var chevronDownImage: UIImage {
        return UIImage.gridicon(.chevronDown)
    }

    /// Chevron Pointing Up
    ///
    static var chevronUpImage: UIImage {
        return UIImage.gridicon(.chevronUp)
    }

    /// Close bar button item
    ///
    static var closeButton: UIImage {
        return UIImage.gridicon(.cross)
    }

    /// Cog Icon
    ///
    static var cogImage: UIImage {
        return UIImage.gridicon(.cog)
    }

    /// Comment Icon
    ///
    static var commentImage: UIImage {
        return UIImage.gridicon(.comment)
    }

    /// Delete Icon
    ///
    static var deleteImage: UIImage {
        let tintColor = UIColor.primary
        return UIImage.gridicon(.crossCircle)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Ellipsis Icon
    ///
    static var ellipsisImage: UIImage {
        return UIImage.gridicon(.ellipsis)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Empty Products Icon
    ///
    static var emptyProductsImage: UIImage {
        return UIImage(named: "woo-empty-products")!
    }

    /// Empty Reviews Icon
    ///
    static var emptyReviewsImage: UIImage {
        return UIImage(named: "woo-empty-reviews")!
    }

    /// An image showing a hand holding a magnifying glass over a page.
    ///
    static var emptySearchResultsImage: UIImage {
        UIImage(named: "woo-empty-search-results")!
    }

    /// An image showing a bar chart. This is used to show an empty All Orders tab.
    ///
    static var emptyOrdersImage: UIImage {
        UIImage(named: "woo-empty-orders")!
    }

    /// Error State Image
    ///
    static var errorStateImage: UIImage {
        return UIImage(named: "woo-error-state")!
    }

    /// External Link Icon
    ///
    static var externalImage: UIImage {
        return UIImage.gridicon(.external)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Filter Icon
    ///
    static var filterImage: UIImage {
        return UIImage.gridicon(.filter)
    }

    /// Gift Icon (with a red dot at the top right corner)
    ///
    static var giftWithTopRightRedDotImage: UIImage {
        guard let image = UIImage.gridicon(.gift, size: CGSize(width: 24, height: 24))
            // Applies a constant gray color that looks fine in both Light/Dark modes, since we are generating an image with multiple colors.
            .applyTintColor(.gray(.shade30))?
            .imageWithTopRightDot(imageOrigin: CGPoint(x: 0, y: 2),
                                  finalSize: CGSize(width: 26, height: 26)) else {
                                    fatalError()
        }
        return image
    }

    /// Gravatar Placeholder Image
    ///
    static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }

    /// Heart Outline
    ///
    static var heartOutlineImage: UIImage {
        return UIImage.gridicon(.heartOutline)
    }

    /// Login prologue slanted rectangle
    ///
    static var slantedRectangle: UIImage {
        return UIImage(named: "prologue-slanted-rectangle")!
    }

    /// Inventory Icon
    ///
    static var inventoryImage: UIImage {
        return UIImage.gridicon(.listCheckmark, size: CGSize(width: 24, height: 24))
    }

    /// Jetpack Logo Image
    ///
    static var jetpackLogoImage: UIImage {
        return UIImage(named: "icon-jetpack-gray")!
    }

    /// Info Icon
    ///
    static var infoImage: UIImage {
        return UIImage.gridicon(.info, size: CGSize(width: 24, height: 24))
    }

    /// Invisible Image
    ///
    static var invisibleImage: UIImage {
        return UIImage.gridicon(.image)
    }

    /// Link Image
    ///
    static var linkImage: UIImage {
        return UIImage.gridicon(.link)
    }

    /// Login magic link
    ///
    static var loginMagicLinkImage: UIImage {
        return UIImage(named: "logic-magic-link")!
    }

    /// Login site address info
    ///
    static var loginSiteAddressInfoImage: UIImage {
        return UIImage(named: "login-site-address-info")!
    }

    /// Mail Icon
    ///
    static var mailImage: UIImage {
        return UIImage.gridicon(.mail)
    }

    /// More Icon
    ///
    static var moreImage: UIImage {
        let tintColor = UIColor.primary
        return ellipsisImage.imageWithTintColor(tintColor)!
    }

    /// Price Icon
    ///
    static var priceImage: UIImage {
        return UIImage.gridicon(.money, size: CGSize(width: 24, height: 24))
    }

    /// Product Placeholder Image
    ///
    static var productPlaceholderImage: UIImage {
        let tintColor = UIColor.listIcon
        return UIImage.gridicon(.product).imageWithTintColor(tintColor)!
    }

    /// Product Placeholder Image on Products Tab Cell
    ///
    static var productsTabProductCellPlaceholderImage: UIImage {
        let tintColor = UIColor.listSmallIcon
        return UIImage.gridicon(.product, size: CGSize(width: 20, height: 20))
            .imageWithTintColor(tintColor)!
    }

    /// Work In Progress banner icon on the Products Tab
    ///
    static var workInProgressBanner: UIImage {
        let tintColor = UIColor.gray(.shade30)
        return UIImage(named: "icon-tools")!
            .imageWithTintColor(tintColor)!
    }

    /// Product Image
    ///
    static var productImage: UIImage {
        return UIImage.gridicon(.product)
    }

    /// Pencil Icon
    ///
    static var pencilImage: UIImage {
        let tintColor = UIColor.primary
        return UIImage.gridicon(.pencil)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Quote Image
    ///
    static var quoteImage: UIImage {
        return UIImage.gridicon(.quote)
    }

    /// Pages Icon
    ///
    static var pagesImage: UIImage {
        return UIImage.gridicon(.pages)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Plus Icon
    ///
    static var plusImage: UIImage {
        return UIImage.gridicon(.plus)
    }

    /// Search Icon
    ///
    static var searchImage: UIImage {
        return UIImage.gridicon(.search)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Shipping Icon
    ///
    static var shippingImage: UIImage {
        return UIImage.gridicon(.shipping, size: CGSize(width: 24, height: 24)).imageFlippedForRightToLeftLayoutDirection()
    }

    /// Shipping class list selector empty icon
    ///
    static var shippingClassListSelectorEmptyImage: UIImage {
        return UIImage.gridicon(.shipping, size: CGSize(width: 80, height: 80))
    }

    /// Spam Icon
    ///
    static var spamImage: UIImage {
        return UIImage.gridicon(.spam)
    }

    /// Scan Icon
    ///
    static var scanImage: UIImage {
        return UIImage(named: "icon-scan")!
    }

    /// Returns a star icon with the given size
    ///
    /// - Parameters:
    ///   - size: desired size of the resulting star icon
    /// - Returns: a bitmap image
    ///
    static func starImage(size: Double) -> UIImage {
        let starSize = CGSize(width: size, height: size)
        return UIImage.gridicon(.star, size: starSize)
    }

    /// Returns a star outline icon with the given size
    ///
    /// - Parameters:
    ///   - size: desired size of the resulting star icon, defaults to `Gridicon.defaultSize.height`
    /// - Returns: a bitmap image
    ///
    static func starOutlineImage(size: Double = Double(Gridicon.defaultSize.height)) -> UIImage {
        let starSize = CGSize(width: size, height: size)
        return UIImage.gridicon(.starOutline, size: starSize)
    }

    /// Stats Icon
    ///
    static var statsImage: UIImage {
        return UIImage.gridicon(.stats)
        .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Stats Alt Icon
    ///
    static var statsAltImage: UIImage {
        return UIImage.gridicon(.statsAlt)
        .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Trash Can Icon
    ///
    static var trashImage: UIImage {
        return UIImage.gridicon(.trash)
    }
    
    
    static var syncImage: UIImage {
        return UIImage.gridicon(.sync).imageFlippedForRightToLeftLayoutDirection()
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

    /// Password Field Image
    ///
    static var passwordFieldImage: UIImage {
        return UIImage.gridicon(.visible)
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

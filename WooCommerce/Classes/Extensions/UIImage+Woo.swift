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

    /// Arrow Up Icon
    ///
    static var arrowUp: UIImage {
        return UIImage.gridicon(.arrowUp)
    }

    /// Align justify Icon
    ///
    static var alignJustifyImage: UIImage {
        return UIImage.gridicon(.alignJustify)
    }

    /// Notice Icon
    ///
    static var noticeImage: UIImage {
        return UIImage.gridicon(.notice)
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

    /// Short Description Icon
    ///
    static var shortDescriptionImage: UIImage {
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

    /// Product tags Icon
    ///
    static var tagsIcon: UIImage {
        return UIImage.gridicon(.tag).imageFlippedForRightToLeftLayoutDirection()
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

    /// Checkmark image that is shown in a cell's image overlay
    ///
    static var checkmarkInCellImageOverlay: UIImage {
        return UIImage.gridicon(.checkmark, size: CGSize(width: 22, height: 22))
            .imageWithTintColor(.listBackground)!
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
        return UIImage.gridicon(.chevronRight)
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

    /// Credit Card Icon
    ///
    static var creditCardImage: UIImage {
        UIImage.gridicon(.creditCard)
    }

    /// Customize Icon
    ///
    static var customizeImage: UIImage {
        UIImage.gridicon(.customize)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Delete Icon
    ///
    static var deleteImage: UIImage {
        let tintColor = UIColor.primary
        return UIImage.gridicon(.crossCircle)
            .imageWithTintColor(tintColor)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Delete cell image shown in a cell's accessory view
    ///
    static var deleteCellImage: UIImage {
        return UIImage.gridicon(.cross, size: CGSize(width: 22, height: 22))
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

    /// External Product
    ///
    static var externalProductImage: UIImage {
        return UIImage(named: "icon-external-product")!.withRenderingMode(.alwaysTemplate)
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

    /// House Image
    ///
    static var houseImage: UIImage {
        UIImage.gridicon(.house)
    }

    /// House Outlined Image
    ///
    static var houseOutlinedImage: UIImage {
        UIImage(imageLiteralResourceName: "icon-house-outlined")
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

    /// Linked Products Icon
    ///
    static var linkedProductsImage: UIImage {
        return UIImage.gridicon(.reblog, size: CGSize(width: 24, height: 24))
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

    /// Info Outline Icon
    ///
    static var infoOutlineImage: UIImage {
        return UIImage.gridicon(.infoOutline)
    }

    /// Info Outline Icon (footnote)
    ///
    static var infoOutlineFootnoteImage: UIImage {
        .gridicon(.infoOutline, size: CGSize(width: 20, height: 20))
    }

    /// Files Download Icon
    ///
    static var cloudImage: UIImage {
        return UIImage.gridicon(.cloud)
    }

    /// Menu Icon
    ///
    static var menuImage: UIImage {
        return UIImage.gridicon(.menu)
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

    /// Location Image
    ///
    static var locationImage: UIImage {
        UIImage.gridicon(.location)
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

    /// Login error: no Jetpack
    ///
    static var loginNoJetpackError: UIImage {
        return UIImage(named: "woo-no-jetpack-error")!.imageFlippedForRightToLeftLayoutDirection()
    }

    /// Login error: no WordPress
    ///
    static var loginNoWordPressError: UIImage {
        return UIImage(named: "woo-wp-no-site")!.imageFlippedForRightToLeftLayoutDirection()
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

    /// Product Reviews Icon
    ///
    static var productReviewsImage: UIImage {
        let tintColor = UIColor.gray(.shade30)
        return UIImage.gridicon(.starOutline, size: CGSize(width: 24, height: 24)).imageWithTintColor(tintColor)!
    }

    /// Product Placeholder Image
    ///
    static var productPlaceholderImage: UIImage {
        return UIImage.gridicon(.product)
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

    /// Pages Icon (footnote)
    ///
    static var pagesFootnoteImage: UIImage {
        return UIImage.gridicon(.pages, size: CGSize(width: 20, height: 20))
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

    /// WordPress Logo Icon
    ///
    static var wordPressLogoImage: UIImage {
        return UIImage.gridicon(.mySites)
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

    /// Sync Icon
    ///
    static var syncIcon: UIImage {
        return UIImage.gridicon(.sync)
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

    /// Widgets Icon
    ///
    static var widgetsImage: UIImage {
        return UIImage(named: "icon-widgets")!.withRenderingMode(.alwaysTemplate)
    }

    static var syncDotIcon: UIImage {
        return UIImage(imageLiteralResourceName: "icon-sync-dot")
    }

    /// Variations Icon
    ///
    static var variationsImage: UIImage {
        return UIImage.gridicon(.types).imageFlippedForRightToLeftLayoutDirection()
    }

    /// Visibility Image
    ///
    static var visibilityImage: UIImage {
        return UIImage.gridicon(.visible)
    }

    /// No store image
    ///
    static var noStoreImage: UIImage {
        return UIImage(imageLiteralResourceName: "woo-no-store").imageFlippedForRightToLeftLayoutDirection()
    }

    /// Megaphone Icon
    ///
    static var megaphoneIcon: UIImage {
        return UIImage(imageLiteralResourceName: "megaphone").imageFlippedForRightToLeftLayoutDirection()
    }

    /// Error image
    ///
    static var errorImage: UIImage {
        return UIImage(imageLiteralResourceName: "woo-error").imageFlippedForRightToLeftLayoutDirection()
    }

    /// Empty box image
    ///
    static var emptyBoxImage: UIImage {
        UIImage(imageLiteralResourceName: "empty-box")
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

    /// What is Jetpack Image
    ///
    static var whatIsJetpackImage: UIImage {
        return UIImage(named: "woo-what-is-jetpack")!
    }
}

private extension UIImage {

    enum Metrics {
        static let defaultWooLogoSize = CGSize(width: 30, height: 18)
    }
}

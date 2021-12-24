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

    /// Alarm Bell Ring Image
    ///
    static var alarmBellRingImage: UIImage {
        return UIImage(named: "icon-alarm-bell-ring")!
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

    /// Analytics Image
    ///
    static var analyticsImage: UIImage {
        return UIImage(named: "icon-analytics")!
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

    /// Green circle with checkmark
    ///
    static var checkCircleImage: UIImage {
        return UIImage(named: "check-circle-done")!
    }

    /// Circle without checkmark
    ///
    static var checkEmptyCircleImage: UIImage {
        return UIImage(named: "check-circle-empty")!
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

    /// Chevron Pointing Left
    ///
    static var chevronLeftImage: UIImage {
        return UIImage.gridicon(.chevronLeft)
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

    /// Cloud Outline Icon
    ///
    static var cloudOutlineImage: UIImage {
        return UIImage.gridicon(.cloudOutline)
    }

    /// Coooy Icon - used in `UIBarButtonItem`
    ///
    static var copyBarButtonItemImage: UIImage {
        return UIImage(systemName: "doc.on.doc")!
    }

    /// Connection Icon
    ///
    static var connectionImage: UIImage {
        return UIImage(named: "icon-connection")!
    }

    /// Gear Icon - used in `UIBarButtonItem`
    ///
    static var gearBarButtonItemImage: UIImage {
        return UIImage(systemName: "gear", withConfiguration: Configurations.barButtonItemSymbol)!
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

    /// Empty Products Tab Icon
    ///
    static var emptyProductsTabImage: UIImage {
        return UIImage(named: "woo-empty-products-tab")!
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

    /// Store Image
    ///
    static var storeImage: UIImage {
        UIImage(named: "icon-store")!
    }

    /// Cog Image
    ///
    static var cogImage: UIImage {
        return UIImage.gridicon(.cog)
    }

    /// Login prologue curved rectangle
    ///
    static var curvedRectangle: UIImage {
        return UIImage(named: "prologue-curved-rectangle")!
    }

    /// Login prologue analytics image
    ///
    static var prologueAnalyticsImage: UIImage {
        return UIImage(named: "login-prologue-analytics")!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Login prologue orders image
    ///
    static var prologueOrdersImage: UIImage {
        return UIImage(named: "login-prologue-orders")!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Login prologue products image
    ///
    static var prologueProductsImage: UIImage {
        return UIImage(named: "login-prologue-products")!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Login prologue reviews image
    ///
    static var prologueReviewsImage: UIImage {
        return UIImage(named: "login-prologue-reviews")!
            .imageFlippedForRightToLeftLayoutDirection()
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

    static var jetpackGreenLogoImage: UIImage {
        return UIImage(named: "icon-jetpack-green")!
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

    /// Credit card tapping on a card reader
    ///
    static var cardPresentImage: UIImage {
        return UIImage(named: "woo-payments-card")!
    }

    /// Searching for Card Reader, Card Reader with radio waves
    ///
    static var cardReaderScanning: UIImage {
        return UIImage(named: "card-reader-scanning")!
    }

    /// Found Card Reader
    ///
    static var cardReaderFound: UIImage {
        return UIImage(named: "card-reader-found")!
    }

    /// Person with mobile device standing next to card reader with radio waves
    ///
    static var cardReaderConnect: UIImage {
        return UIImage(named: "card-reader-connect")!
    }

    /// Connecting to Card Reader, Card Reader with radio waves
    ///
    static var cardReaderConnecting: UIImage {
        return UIImage(named: "card-reader-connecting")!
    }

    /// Card Reader Update background
    ///
    static var cardReaderUpdateProgressBackground: UIImage {
        return UIImage(named: "card-reader-update-progress-background")!
    }

    /// Card Reader Update arrow
    ///
    static var cardReaderUpdateProgressArrow: UIImage {
        return UIImage(named: "card-reader-update-progress-arrow")!
    }

    /// Card Reader Update checkmark
    ///
    static var cardReaderUpdateProgressCheckmark: UIImage {
        return UIImage(named: "card-reader-update-progress-checkmark")!
    }

    /// Card Reader Low Battery
    ///
    static var cardReaderLowBattery: UIImage {
        return UIImage(named: "card-reader-low-battery")!
    }

    /// Shopping cart
    ///
    static var shoppingCartIcon: UIImage {
        return UIImage(named: "icon-shopping-cart")!
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Credit card
    ///
    static var creditCardIcon: UIImage {
        return UIImage(named: "icon-card")!
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Card Reader Manual
    ///
    static var cardReaderManualIcon: UIImage {
        return UIImage(named: "icon-card-reader-manual")!
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Files Download Icon
    ///
    static var cloudImage: UIImage {
        return UIImage.gridicon(.cloud)
    }

    /// Hub Menu tab icon
    ///
    static var hubMenu: UIImage {
        return UIImage(named: "icon-hub-menu")!
    }

    /// Menu Icon
    ///
    static var menuImage: UIImage {
        return UIImage.gridicon(.menu)
    }

    /// Lightning icon on offline banner
    ///
    static var lightningImage: UIImage {
        return UIImage.gridicon(.offline).imageFlippedForRightToLeftLayoutDirection()
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

    /// Plugins error
    ///
    static var pluginListError: UIImage {
        return UIImage(named: "woo-plugins-error")!.imageFlippedForRightToLeftLayoutDirection()
    }

    static var incorrectRoleError: UIImage {
        return UIImage(named: "woo-incorrect-role-error")!.imageFlippedForRightToLeftLayoutDirection()
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

    /// Payment celebration
    ///
    static var celebrationImage: UIImage {
        return UIImage(named: "woo-celebration")!
    }

    /// Payment error
    ///
    static var paymentErrorImage: UIImage {
        return UIImage(named: "woo-payments-error")!
    }

    /// Payments loading
    ///
    static var paymentsLoading: UIImage {
        return UIImage(named: "woo-payments-loading")!
    }

    /// Payments plugin
    ///
    static var paymentsPlugin: UIImage {
        return UIImage(named: "woo-payments-plugin")!
    }

    /// Price Icon
    ///
    static var priceImage: UIImage {
        return UIImage.gridicon(.money, size: CGSize(width: 24, height: 24))
    }

    /// Print Icon
    ///
    static var print: UIImage {
        return UIImage.gridicon(.print)
    }

    /// Product Deleted Icon
    ///
    static var productDeletedImage: UIImage {
        UIImage(named: "woo-product-deleted")!
    }

    /// Product Error Icon
    ///
    static var productErrorImage: UIImage {
        UIImage(named: "woo-product-error")!
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

    /// Simple Payments Icon
    ///
    static var simplePaymentsImage: UIImage {
        return UIImage(named: "icon-simple-payments")!
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

    /// Plus Icon - used in `UIBarButtonItem`
    ///
    static var plusBarButtonItemImage: UIImage {
        return UIImage(systemName: "plus", withConfiguration: Configurations.barButtonItemSymbol)!
    }

    /// Small Plus Icon
    ///
    static var plusSmallImage: UIImage {
        return UIImage.gridicon(.plusSmall)
    }

    /// Small Minus Icon
    ///
    static var minusSmallImage: UIImage {
        return UIImage.gridicon(.minusSmall)
    }

    /// Search Icon - used in `UIBarButtonItem`
    ///
    static var searchBarButtonItemImage: UIImage {
        return UIImage(systemName: "magnifyingglass", withConfiguration: Configurations.barButtonItemSymbol)!
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

    static var shippingLabelCreationInfoImage: UIImage {
        UIImage(named: "woo-shipping-label-creation")!
    }

    /// Globe Image
    ///
    static var globeImage: UIImage {
        UIImage.gridicon(.globe)
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

    /// Multiple Users Image
    ///
    static var multipleUsersImage: UIImage {
        return UIImage(named: "icon-multiple-users")!
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

    /// Welcome Image
    ///
    static var welcomeImage: UIImage {
        UIImage(imageLiteralResourceName: "img-welcome")
    }
}

private extension UIImage {

    enum Metrics {
        static let defaultWooLogoSize = CGSize(width: 30, height: 18)
    }

    enum Configurations {
        static let barButtonItemSymbol = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .medium)
    }
}

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

    /// App icon (iPhone size)
    ///
    static var appIconDefault: UIImage {
        return UIImage(named: "AppIcon60x60")!
    }

    /// Bell icon
    ///
    static var bell: UIImage {
        UIImage(named: "bell")!
    }

    /// Blaze icon
    ///
    static var blaze: UIImage {
        UIImage(named: "blaze")!
    }

    /// Blaze Intro Illustration icon
    ///
    static var blazeIntroIllustration: UIImage {
        UIImage(named: "blaze-intro-illustration")!
    }

    /// Blaze product placeholder
    ///
    static var blazeProductPlaceholder: UIImage {
        UIImage(named: "blaze-product-placeholder")!
    }

    /// Currency Image
    ///
    static var currencyImage: UIImage {
        UIImage(named: "icon-currency")!
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

    /// Sparkles Icon
    ///
    static var sparklesImage: UIImage {
        .init(named: "sparkles")!
    }

    /// Calendar clock Image
    ///
    static var calendarClock: UIImage {
        .init(systemName: "calendar.badge.clock")!
    }

    /// Camera Icon
    ///
    static var cameraImage: UIImage {
        return UIImage.gridicon(.camera)
            .imageFlippedForRightToLeftLayoutDirection()
            .withTintColor(.placeholderImage)
    }

    /// Cash register image
    ///
    static var cashRegisterImage: UIImage {
        return UIImage(named: "cash-register")!
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

    /// Blank Product
    ///
    static var blankProductImage: UIImage {
        return UIImage(named: "icon-blank-product")!.withRenderingMode(.alwaysTemplate)
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

    static var checkPartialCircleImage: UIImage {
        return UIImage(named: "check-circle-partial")!
    }

    /// Large checkmark image that is shown upon success
    ///
    static var checkSuccessImage: UIImage {
        return UIImage(named: "check-success")!
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

    /// Copy Icon - used in `UIBarButtonItem`
    ///
    static var copyBarButtonItemImage: UIImage {
        return UIImage(systemName: "doc.on.doc")!
    }

    /// Coupon Icon - used in hub menu
    ///
    static var couponImage: UIImage {
        return UIImage(named: "icon-coupon")!
    }

    /// Connection Icon
    ///
    static var connectionImage: UIImage {
        return UIImage(named: "icon-connection")!
    }

    /// Create order image
    ///
    static var createOrderImage: UIImage {
        return UIImage(named: "create-order")!
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

    /// Comment Content Icon
    ///
    static var commentContent: UIImage {
        let tintColor = UIColor(light: .black, dark: .white)
        return UIImage(named: "icon-comment-content")?.withTintColor(tintColor) ?? .commentImage.withTintColor(tintColor)
    }

    /// Credit Card Icon
    ///
    static var creditCardImage: UIImage {
        UIImage.gridicon(.creditCard)
    }

    static var tapToPayOnIPhoneIcon: UIImage {
        UIImage(systemName: "wave.3.right.circle")?.withRenderingMode(.alwaysTemplate) ?? .creditCardImage
    }

    static var bankIcon: UIImage {
        UIImage(systemName: "building.columns")?.withRenderingMode(.alwaysTemplate) ?? .emptyBoxImage
    }

    static var scanToPayIcon: UIImage {
        UIImage(systemName: "qrcode.viewfinder")?.withRenderingMode(.alwaysTemplate) ?? .creditCardImage
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

    /// Domain credit image.
    ///
    static var domainCreditImage: UIImage {
        return UIImage(named: "domain-credit")!
    }

    /// Domain purchase success image.
    ///
    static var domainPurchaseSuccessImage: UIImage {
        return UIImage(named: "domain-purchase-success")!
    }

    static var emailImage: UIImage {
        UIImage(named: "email")!
    }

    /// Domain search placeholder image.
    ///
    static var domainSearchPlaceholderImage: UIImage {
        return UIImage(named: "domain-search-placeholder")!
    }

    /// Ellipsis Icon
    ///
    static var ellipsisImage: UIImage {
        return UIImage.gridicon(.ellipsis)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Empty Coupons Icon
    ///
    static var emptyCouponsImage: UIImage {
        return UIImage(named: "woo-empty-coupons")!
    }

    /// Empty Inbox Notes Icon
    ///
    static var emptyInboxNotesImage: UIImage {
        UIImage(named: "woo-empty-inbox-notes")!
    }

    /// Empty Tax Rates Icon
    ///
    static var emptyTaxRatesImage: UIImage {
        UIImage(named: "woo-empty-tax-rates")!
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

    static var shoppingBagsImage: UIImage {
        UIImage(named: "shopping-bags")!
    }

    /// An image showing a bar chart. This is used to show an empty All Orders tab.
    ///
    static var emptyOrdersImage: UIImage {
        UIImage(named: "woo-empty-orders")!
    }

    /// An image showing a magnifying glass. This is used to show a default image when searching for customers.
    ///
    static var customerSearchImage: UIImage {
        UIImage(named: "woo-customer-search")!
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

    /// Big error icon
    ///
    static var bigErrorIcon: UIImage {
        return UIImage(named: "error-big-icon")!
    }

    /// Blaze success image
    ///
    static var blazeSuccessImage: UIImage {
        return UIImage(named: "blaze-success")!
    }

    /// Subscription Product
    ///
    static var subscriptionProductImage: UIImage {
        return UIImage(systemName: "repeat")!
    }

    /// Subscription Product
    ///
    static var variableSubscriptionProductImage: UIImage {
        if #available(iOS 16.0, *) {
            return UIImage(systemName: "square.3.layers.3d")!
        } else {
            return UIImage(systemName: "square.stack.3d.up")!
        }
    }

    /// Filter Icon
    ///
    static var filterImage: UIImage {
        return UIImage.gridicon(.filter)
    }

    /// Fixed cart discount icon
    ///
    static var fixedCartDiscountIcon: UIImage {
        return UIImage(named: "icon-fixed-cart-discount")!
    }

    /// Fixed product discount icon
    ///
    static var fixedProductDiscountIcon: UIImage {
        return UIImage(named: "icon-fixed-product-discount")!
    }

    /// Percentage discount icon
    ///
    static var percentageDiscountIcon: UIImage {
        return UIImage(named: "icon-percentage-discount")!
    }

    /// Gift Icon (with a red dot at the top right corner)
    ///
    static var giftWithTopRightRedDotImage: UIImage {
        guard let image = UIImage.gridicon(.gift, size: CGSize(width: 24, height: 24))
            // Applies a constant gray color that looks fine in both Light/Dark modes, since we are generating an image with multiple colors.
            .withTintColor(.gray(.shade30))
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

    /// Help Outline
    ///
    static var helpOutlineImage: UIImage {
        return UIImage.gridicon(.helpOutline)
    }

    /// House Image
    ///
    static var houseImage: UIImage {
        UIImage.gridicon(.house)
    }

    /// Hourglass Image
    ///
    static var hourglass: UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .medium)
        return UIImage(systemName: "hourglass", withConfiguration: config)!
    }

    /// Hourglass Image from Woo design
    ///
    static var wooHourglass: UIImage {
        UIImage(named: "woo-hourglass")!
    }

    /// House Outlined Image
    ///
    static var houseOutlinedImage: UIImage {
        UIImage(imageLiteralResourceName: "icon-house-outlined")
    }

    /// Mailbox Icon - used in hub menu
    ///
    static var mailboxImage: UIImage {
        return UIImage(named: "icon-mailbox")!
    }

    /// Store plan image used in the store creation flow.
    ///
    static var storeCreationPlanImage: UIImage {
        UIImage(named: "store-creation-plan")!
    }

    /// Store Image
    ///
    static var storeImage: UIImage {
        UIImage(named: "icon-store")!
    }

    /// Store details Image
    ///
    static var storeDetailsImage: UIImage {
        UIImage(named: "icon-store-details")!
    }

    /// Store creation progress step 1
    static var storeCreationProgress1: UIImage {
        UIImage(named: "store-creation-progress-1")!
    }

    /// Store creation progress step 2
    static var storeCreationProgress2: UIImage {
        UIImage(named: "store-creation-progress-2")!
    }

    /// Store creation progress step 3
    static var storeCreationProgress3: UIImage {
        UIImage(named: "store-creation-progress-3")!
    }

    /// Store creation progress step 4
    static var storeCreationProgress4: UIImage {
        UIImage(named: "store-creation-progress-4")!
    }

    /// Swap icon - horizontal
    static var swapHorizontal: UIImage {
        UIImage(named: "swap-horizontal")!
    }

    /// Add product image
    ///
    static var addProductImage: UIImage {
        UIImage(named: "icon-add-product")!
    }

    /// AI product description celebration image
    ///
    static var aiDescriptionCelebrationImage: UIImage {
        return UIImage(named: "ai-description-celebration")!
    }

    /// Product Creation AI Survey image
    ///
    static var productCreationAISurveyImage: UIImage {
        return UIImage(named: "product-creation-ai-survey")!
    }

    /// Launch store Image
    ///
    static var launchStoreImage: UIImage {
        UIImage(named: "icon-launch-store")!
    }

    /// Customize domain image
    ///
    static var customizeDomainsImage: UIImage {
        UIImage(named: "icon-customize-domain")!
    }

    /// Get paid image
    ///
    static var getPaidImage: UIImage {
        UIImage(named: "icon-get-paid")!
    }

    /// Store summary image used in the store creation flow.
    ///
    static var storeSummaryImage: UIImage {
        return UIImage(named: "store-summary")!
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

    /// Login prologue Woo Mobile
    ///
    static var prologueWooMobileImage: UIImage {
        UIImage(named: "login-prologue-woo-mobile")!
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

    static var enableAnalyticsImage: UIImage {
        return UIImage(named: "woo-analytics")!
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

    static var wooPaymentsBadge: UIImage {
        UIImage(named: "woo-payments-badge")!
    }

    /// Credit card tapping on a card reader
    ///
    static var cardPresentImage: UIImage {
        return UIImage(named: "woo-payments-card")!
    }

    static var walletImage: UIImage {
        return UIImage(named: "woo-payments-wallet")!
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

    /// Card Reader image - BBPOS Chipper 2X BT
    ///
    static var cardReaderImageBBPOSChipper: UIImage {
        return UIImage(named: "card-reader-bbpos-chipper")!
    }

    /// Card Reader image - Stripe Reader M2
    ///
    static var cardReaderImageM2: UIImage {
        return UIImage(named: "card-reader-m2")!
    }

    /// Card Reader image - Wisepad 3
    ///
    static var cardReaderImageWisepad3: UIImage {
        return UIImage(named: "card-reader-wisepad3")!
    }

    /// Shopping cart
    ///
    static var shoppingCartIcon: UIImage {
        return UIImage(named: "icon-shopping-cart")!
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Shopping cart Purple
    ///
    static var shoppingCartPurpleIcon: UIImage {
        return UIImage(named: "icon-shopping-cart-purple")!
    }

    /// Bordered Custom Amount
    ///
    static var borderedCustomAmount: UIImage {
        return UIImage(named: "icon-bordered-custom-amount")!
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

    /// Credit card give icon
    ///
    static var creditCardGiveIcon: UIImage {
        return UIImage(named: "credit-card-give")!
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Cash give icon
    ///
    static var moneyIcon: UIImage {
        return UIImage(named: "icon-money")!
            .withRenderingMode(.alwaysTemplate)
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

    /// Document image
    ///
    static var documentImage: UIImage {
        return .init(systemName: "doc.fill")!
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

    /// The Multiple stores icon on the Jetpack benefit modal
    ///
    static var multipleStoresImage: UIImage {
        return UIImage(named: "multiple-stores")!
    }

    /// Select multiple items icon
    ///
    static var multiSelectIcon: UIImage {
        return UIImage(named: "icon-multiselect")!
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

    /// WooCommerce Stripe Gateway plugin
    ///
    static var stripePlugin: UIImage {
        return UIImage(named: "stripe-payments-plugin")!
    }

    /// WooCommerce Payments plugin
    ///
    static var wcPayPlugin: UIImage {
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
        return UIImage(named: "icon-simple-payments")!.withRenderingMode(.alwaysTemplate)
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

    /// Switching mode image
    ///
    static var switchingModeImage: UIImage {
        UIImage(systemName: "arrow.left.arrow.right")!
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

    /// Point of sale image
    ///
    static var pointOfSaleImage: UIImage {
        UIImage(named: "point-of-sale")!
    }

    /// Product description AI announcement image
    ///
    static var productDescriptionAIAnnouncementImage: UIImage {
        .init(named: "product-description-ai-announcement")!
    }

    /// Small Minus Icon
    ///
    static var minusSmallImage: UIImage {
        return UIImage.gridicon(.minusSmall)
    }

    /// Rectangle on rectangle, angled
    ///
    static var rectangleOnRectangleAngled: UIImage {
        return UIImage(systemName: "rectangle.on.rectangle.angled", withConfiguration: Configurations.barButtonItemSymbol)!
            .imageFlippedForRightToLeftLayoutDirection()
    }

    /// Reply Icon
    ///
    static var replyImage: UIImage {
        return UIImage.gridicon(.reply)
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

    /// Search Image
    ///
    static var searchImage: UIImage {
        UIImage(named: "search")!
    }

    /// Search No Result Image
    ///
    static var searchNoResultImage: UIImage {
        UIImage(named: "search-no-result")!
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

    /// Stripe icon
    ///
    static var stripeIcon: UIImage {
        return UIImage(named: "stripe-icon")!
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

    /// Tooltip icon
    ///
    static var tooltipImage: UIImage {
        return UIImage(named: "icon-tooltip")!
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

    /// Stripe icon
    ///
    static var wcpayIcon: UIImage {
        return UIImage(named: "wcpay-icon")!
    }

    /// No store image
    ///
    static var noStoreImage: UIImage {
        return UIImage(imageLiteralResourceName: "woo-no-store").imageFlippedForRightToLeftLayoutDirection()
    }

    /// No connection image
    ///
    static var noConnectionImage: UIImage {
        UIImage(imageLiteralResourceName: "connection-icon")
    }

    /// Upgrade plan error
    ///
    static var planUpgradeError: UIImage {
        return UIImage(imageLiteralResourceName: "plan-upgrade-error")
    }

    /// Upgrade plan success celebratory image
    ///
    static var planUpgradeSuccessCelebration: UIImage {
        return UIImage(imageLiteralResourceName: "plan-upgrade-success-celebration")
    }

    /// Megaphone Icon
    ///
    static var megaphoneIcon: UIImage {
        return UIImage(imageLiteralResourceName: "megaphone").imageFlippedForRightToLeftLayoutDirection()
    }

    /// Speaker icon
    ///
    static var speakerIcon: UIImage {
        return UIImage.gridicon(.speaker).imageFlippedForRightToLeftLayoutDirection()
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

    /// Woo logo that is displayed on the login prologue.
    ///
    static var wooLogoPrologueImage: UIImage {
        UIImage(named: "prologue-logo")!
    }

    /// Waiting for Customers Image
    ///
    static var waitingForCustomersImage: UIImage {
        return UIImage(named: "woo-waiting-customers")!
    }

    static var puzzleExtensionsImage: UIImage {
        return UIImage(named: "woo-puzzle-extensions")!
    }

    /// Install WCShip banner Image
    ///
    static var installWCShipImage: UIImage {
        return UIImage(named: "woo-wcship-install-banner")!
    }

    /// Payments Feature Banner
    ///
    static var paymentsFeatureBannerImage: UIImage {
        return UIImage(named: "woo-payments-feature-banner")!
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

    /// Icon Circular Rate Discount (used in WCShip onboarding)
    ///
    static var circularRateDiscountIcon: UIImage {
        return UIImage(named: "icon-circular-rate-discount")!
    }

    /// Icon Circular Document (used in WCShip onboarding)
    ///
    static var circularDocumentIcon: UIImage {
        return UIImage(named: "icon-circular-document")!
    }

    /// Icon Circular Time (used in WCShip onboarding)
    ///
    static var circularTimeIcon: UIImage {
        return UIImage(named: "icon-circular-time")!
    }

    /// Google Icon
    ///
    static var googleLogo: UIImage {
        return UIImage(named: "google-logo")!
    }

    /// Lock Image
    ///
    static var lockImage: UIImage {
        return UIImage(systemName: "lock.fill")?.withRenderingMode(.alwaysTemplate) ?? UIImage.gridicon(.lock, size: CGSize(width: 24, height: 24))
    }

    /// Sites Image
    ///
    static var sitesImage: UIImage {
        UIImage.gridicon(.site).imageFlippedForRightToLeftLayoutDirection()
    }

    /// Image on the empty store picker screen
    ///
    static var emptyStorePickerImage: UIImage {
        UIImage(named: "woo-empty-store-picker")!
    }

    /// Image on the Jetpack required screen
    ///
    static var jetpackSetupImage: UIImage {
        UIImage(named: "woo-jetpack-setup")!
    }

    /// Image on the Jetpack required screen when a Jetpack connection is missing
    ///
    static var jetpackConnectionImage: UIImage {
        UIImage(named: "woo-jetpack-connection")!
    }

    /// WordPress.com logo image.
    ///
    static func wpcomLogoImage(tintColor: UIColor? = nil) -> UIImage {
        if let tintColor {
            return UIImage(named: "wpcom-logo")!.imageWithTintColor(tintColor)!
        } else {
            return UIImage(named: "wpcom-logo")!
        }
    }

    /// Image on the Jetpack setup interrupted screen
    ///
    static var jetpackSetupInterruptedImage: UIImage {
        UIImage(named: "woo-jetpack-setup-interrupted")!
    }

    /// Calendar Icon
    ///
    static var calendar: UIImage {
        return UIImage.gridicon(.calendar)
    }

    // MARK: - Tap on Mobile flow images
    /// Select reader type
    ///
    static var cardPaymentsSelectReaderType: UIImage {
        return UIImage(named: "card-payments-select-reader-type")!
    }

    /// Preparing built-in card reader: intended for use before we're ready to take payment
    ///
    static var preparingBuiltInReader: UIImage {
        return UIImage(named: "built-in-reader-preparing")!
    }

    /// Built-in reader Processing: intended for use when a payment is
    /// underway with the iPhone's built in reader.
    ///
    static var builtInReaderProcessing: UIImage {
        return UIImage(named: "built-in-reader-processing")!
    }

    /// Built-in reader Success: intended for use when a transaction is complete
    /// with the built-in reader
    ///
    static var builtInReaderSuccess: UIImage {
        return UIImage(named: "built-in-reader-payment-success")!
    }

    static var builtInReaderError: UIImage {
        return UIImage(named: "built-in-reader-error")!
    }

    static var setUpBuiltInReader: UIImage {
        return UIImage(named: "built-in-reader-set-up")!
    }

    static var iconBolt: UIImage {
        UIImage(imageLiteralResourceName: "icon-bolt")
    }

    /// Illustration for the free trial summary screen.
    ///
    static var freeTrialIllustration: UIImage {
        UIImage(imageLiteralResourceName: "free-trial-ilustration")
    }

    static var ecommerceIcon: UIImage {
        UIImage(imageLiteralResourceName: "ecommerce-icon")
    }

    static var supportIcon: UIImage {
        UIImage(imageLiteralResourceName: "support-icon")
    }

    static var backupsIcon: UIImage {
        UIImage(imageLiteralResourceName: "backups-icon")
    }

    static var giftIcon: UIImage {
        UIImage(imageLiteralResourceName: "gifts-icon")
    }

    static var emailOutlineIcon: UIImage {
        UIImage(imageLiteralResourceName: "email-outline-icon")
    }

    static var shippingOutlineIcon: UIImage {
        UIImage(imageLiteralResourceName: "shipping-outline-icon")
    }

    static var advertisingIcon: UIImage {
        UIImage(imageLiteralResourceName: "advertising-icon")
    }

    static var launchIcon: UIImage {
        UIImage(imageLiteralResourceName: "launch-icon")
    }

    static var paymentOptionsIcon: UIImage {
        UIImage(imageLiteralResourceName: "payment-options-icon")
    }

    static var premiumThemesIcon: UIImage {
        UIImage(imageLiteralResourceName: "premium-themes-icon")
    }

    static var siteSecurityIcon: UIImage {
        UIImage(imageLiteralResourceName: "site-security-icon")
    }

    static var unlimitedProductsIcon: UIImage {
        UIImage(imageLiteralResourceName: "unlimited-products-icon")
    }

    static var feedbackOutlineIcon: UIImage {
        UIImage(named: "icon-feedback-outline")!
    }

    static var appPasswordTutorialImage: UIImage {
        UIImage(named: "app-password-tutorial-1")!
    }

    static var exclamationFilledImage: UIImage {
        UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: Configurations.barButtonItemSymbol)!.withRenderingMode(.alwaysTemplate)
    }

    static var exclamationImage: UIImage {
        UIImage(systemName: "exclamationmark.circle", withConfiguration: Configurations.barButtonItemSymbol)!.withRenderingMode(.alwaysTemplate)
    }

    static var magnifyingGlassNotFound: UIImage {
        UIImage(imageLiteralResourceName: "magnifying-glass-not-found")
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

import XCTest
import Gridicons
@testable import WooCommerce

final class IconsTests: XCTestCase {
    func testAddOutlineIconIsNotNil() {
        XCTAssertNotNil(UIImage.addOutlineImage)
    }

    func test_arrowUp_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.arrowUp)
    }

    func test_alignJustify_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.alignJustifyImage)
    }

    func test_alarmBellRing_image_is_not_nil() {
        XCTAssertNotNil(UIImage.alarmBellRingImage)
    }

    func test_analytics_image_is_not_nil() {
        XCTAssertNotNil(UIImage.analyticsImage)
    }

    func test_bell_image_is_not_nil() {
        XCTAssertNotNil(UIImage.bell)
    }

    func test_blaze_image_is_not_nil() {
        XCTAssertNotNil(UIImage.blaze)
    }

    func test_blazeSuccessImage_is_not_nil() {
        XCTAssertNotNil(UIImage.blazeSuccessImage)
    }

    func test_blazeIntroIllustration_is_not_nil() {
        XCTAssertNotNil(UIImage.blazeIntroIllustration)
    }

    func test_blazeProductPlaceholder_is_not_nil() {
        XCTAssertNotNil(UIImage.blazeProductPlaceholder)
    }

    func test_currency_image_is_not_nil() {
        XCTAssertNotNil(UIImage.currencyImage)
    }

    func test_calendarClock_image_is_not_nil() {
        XCTAssertNotNil(UIImage.calendarClock)
    }

    func testNoticeImageIsNotNil() {
        XCTAssertNotNil(UIImage.noticeImage)
    }

    func testAsideIconIsNotNil() {
        XCTAssertNotNil(UIImage.asideImage)
    }

    func testBellIconIsNotNil() {
        XCTAssertNotNil(UIImage.bellImage)
    }

    func testShortDescriptionImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.shortDescriptionImage)
    }

    func test_sparkles_image_is_not_nil() {
        XCTAssertNotNil(UIImage.sparklesImage)
    }

    func testCameraIconIsNotNil() {
        XCTAssertNotNil(UIImage.cameraImage)
    }

    func testAddImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.addImage)
    }

    func testCheckmarkImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.checkmarkImage)
    }

    func testCheckmarkInCellImageOverlayIsNotNil() {
        XCTAssertNotNil(UIImage.checkmarkInCellImageOverlay)
    }

    func testCheckmarkStyledImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.checkmarkStyledImage)
    }

    func testCheckCircleDoneImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.checkCircleImage)
    }

    func testCheckCircleEmptyImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.checkEmptyCircleImage)
    }

    func test_check_circle_partial_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.checkPartialCircleImage)
    }

    func test_check_success_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.checkSuccessImage)
    }

    func testChevronImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.chevronImage)
    }

    func testChevronLeftImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.chevronLeftImage)
    }

    func testChevronDownImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.chevronDownImage)
    }

    func testChevronUpImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.chevronUpImage)
    }

    func testCloseButtonIconIsNotNil() {
        XCTAssertNotNil(UIImage.closeButton)
    }

    func testConnectionIconIsNotNil() {
        XCTAssertNotNil(UIImage.connectionImage)
    }

    func test_create_order_image_is_not_nil() {
        XCTAssertNotNil(UIImage.createOrderImage)
    }

    func testGearBarButtonItemImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.gearBarButtonItemImage)
    }

    func testCommentImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.commentImage)
    }

    func testCreditCardImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.creditCardImage)
    }

    func testCustomizeImageIsNotNil() {
        XCTAssertNotNil(UIImage.customizeImage)
    }

    func testDeleteImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.deleteImage)
    }

    func testDeleteCellImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.deleteCellImage)
    }

    func testDeleteCellImageIconDefaultSize() {
        let deleteCellImage = UIImage.deleteCellImage
        XCTAssertEqual(deleteCellImage.size, CGSize(width: 22, height: 22))
    }

    func test_documentImage_is_not_nil() {
        XCTAssertNotNil(UIImage.documentImage)
    }

    func test_domainCreditImage_is_not_nil() {
        XCTAssertNotNil(UIImage.domainCreditImage)
    }

    func test_domainPurchaseSuccessImage_is_not_nil() {
        XCTAssertNotNil(UIImage.domainPurchaseSuccessImage)
    }

    func test_domainSearchPlaceholderImage_is_not_nil() {
        XCTAssertNotNil(UIImage.domainSearchPlaceholderImage)
    }

    func test_emailImage_is_not_nil() {
        XCTAssertNotNil(UIImage.emailImage)
    }

    func testEllipsisImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.ellipsisImage)
    }

    func test_empty_coupon_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.emptyCouponsImage)
    }

    func test_empty_inbox_notes_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.emptyInboxNotesImage)
    }

    func testEmptyProductsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.emptyProductsImage)
    }

    func test_emptyProductsTabImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.emptyProductsTabImage)
    }

    func testEmptyReviewsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.emptyReviewsImage)
    }

    func testEmptySearchResultsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.emptySearchResultsImage)
    }

    func testEmptyOrdersImageIsNotNil() {
        XCTAssertNotNil(UIImage.emptyOrdersImage)
    }

    func testErrorStateImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.errorStateImage)
    }

    func testExternalImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.externalImage)
    }

    func testExternalProductImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.externalProductImage)
    }

    func test_bigErrorIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.bigErrorIcon)
    }

    func testFilterImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.filterImage)
    }

    func test_fixed_cart_discount_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.fixedCartDiscountIcon)
    }

    func test_fixed_product_discount_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.fixedProductDiscountIcon)
    }

    func test_percentage_discount_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.percentageDiscountIcon)
    }

    func testGiftWithTopRightRedDotImageIsNotNil() {
        XCTAssertNotNil(UIImage.giftWithTopRightRedDotImage)
    }

    func testHeartOutlineImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.heartOutlineImage)
    }

    func test_helpOutlineImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.helpOutlineImage)
    }

    func testHouseImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.houseImage)
    }

    func test_wooHourglass_is_not_nil() {
        XCTAssertNotNil(UIImage.wooHourglass)
    }

    func testHouseOutlinedImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.houseOutlinedImage)
    }

    func test_mailbox_image_is_not_nil() {
        XCTAssertNotNil(UIImage.mailboxImage)
    }

    func test_storeCreationPlanImage_is_not_nil() {
        XCTAssertNotNil(UIImage.storeCreationPlanImage)
    }

    func test_storeCreationProgress1_is_not_nil() {
        XCTAssertNotNil(UIImage.storeCreationProgress1)
    }

    func test_storeCreationProgress2_is_not_nil() {
        XCTAssertNotNil(UIImage.storeCreationProgress2)
    }

    func test_storeCreationProgress3_is_not_nil() {
        XCTAssertNotNil(UIImage.storeCreationProgress3)
    }

    func test_storeCreationProgress4_is_not_nil() {
        XCTAssertNotNil(UIImage.storeCreationProgress4)
    }

    func testStoreImageIsNotNil() {
        XCTAssertNotNil(UIImage.storeImage)
    }

    func test_addProductImage_is_not_nil() {
        XCTAssertNotNil(UIImage.addProductImage)
    }

    func test_aiDescriptionCelebrationImage_is_not_nil() {
        XCTAssertNotNil(UIImage.aiDescriptionCelebrationImage)
    }

    func test_productCreationAISurveyImage_is_not_nil() {
        XCTAssertNotNil(UIImage.productCreationAISurveyImage)
    }

    func test_launchStoreImage_is_not_nil() {
        XCTAssertNotNil(UIImage.launchStoreImage)
    }

    func test_storeDetailsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.storeDetailsImage)
    }

    func test_customizeDomainsImagee_is_not_nil() {
        XCTAssertNotNil(UIImage.customizeDomainsImage)
    }

    func test_getPaidImage_is_not_nil() {
        XCTAssertNotNil(UIImage.getPaidImage)
    }

    func test_storeSummaryImage_is_not_nil() {
        XCTAssertNotNil(UIImage.storeSummaryImage)
    }

    func testCotImageIsNotNil() {
        XCTAssertNotNil(UIImage.cogImage)
    }

    func testIconImageIsNotNil() {
        XCTAssertNotNil(UIImage.infoImage)
    }

    func testJetpackLogoImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.jetpackLogoImage)
    }

    func testJetpackGreenLogoImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.jetpackGreenLogoImage)
    }

    func testInfoOutlineImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.infoOutlineImage)
    }

    func testInfoOutlineFootnoteImageIsNotNil() {
        XCTAssertNotNil(UIImage.infoOutlineFootnoteImage)
    }

    func testInfoOutlineFootnoteImageMatchesExpectedSize() {
        let size = CGSize(width: 20, height: 20)
        let image = UIImage.infoOutlineFootnoteImage
        XCTAssertEqual(size, image.size)
    }

    func testInvisibleImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.invisibleImage)
    }

    func testInventoryImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.inventoryImage)
    }

    func test_linkedProducts_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.linkedProductsImage)
    }

    func testLinkImageIsNotNil() {
        XCTAssertNotNil(UIImage.linkImage)
    }

    func testLocationImageIsNotNil() {
        XCTAssertNotNil(UIImage.locationImage)
    }

    func testLoginMagicLinkImageIsNotNil() {
        XCTAssertNotNil(UIImage.loginMagicLinkImage)
    }

    func testLoginSiteAddressInfoImageIsNotNil() {
        XCTAssertNotNil(UIImage.loginSiteAddressInfoImage)
    }

    func test_login_Jetpack_error_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.loginNoJetpackError)
    }

    func test_login_WP_error_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.loginNoWordPressError)
    }

    func test_plugin_list_error_image_is_not_nil() {
        XCTAssertNotNil(UIImage.pluginListError)
    }

    func testMailImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.mailImage)
    }

    func test_minus_small_image_is_not_nil() {
        XCTAssertNotNil(UIImage.minusSmallImage)
    }

    func testMoreImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.moreImage)
    }

    func test_multipleStoresImage_is_not_nil() {
        XCTAssertNotNil(UIImage.multipleStoresImage)
    }

    func test_multiSelectIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.multiSelectIcon)
    }

    func test_multipleUsers_image_is_not_nil() {
        XCTAssertNotNil(UIImage.multipleUsersImage)
    }

    func test_payment_card_reader_scanning_image() {
        XCTAssertNotNil(UIImage.cardReaderScanning)
    }

    func test_payment_card_reader_found_image() {
        XCTAssertNotNil(UIImage.cardReaderFound)
    }

    func test_payment_card_reader_connect_image() {
        XCTAssertNotNil(UIImage.cardReaderConnect)
    }

    func test_payment_card_reader_connecting_image() {
        XCTAssertNotNil(UIImage.cardReaderConnecting)
    }

    func test_payment_card_reader_update_progress_background() {
        XCTAssertNotNil(UIImage.cardReaderUpdateProgressBackground)
    }

    func test_payment_card_reader_update_progress_arrow() {
        XCTAssertNotNil(UIImage.cardReaderUpdateProgressArrow)
    }

    func test_payment_card_reader_update_progress_checkmark() {
        XCTAssertNotNil(UIImage.cardReaderUpdateProgressCheckmark)
    }

    func test_payment_card_reader_low_battery() {
        XCTAssertNotNil(UIImage.cardReaderLowBattery)
    }

    func test_woo_payments_badge_is_not_nil() {
        XCTAssertNotNil(UIImage.wooPaymentsBadge)
    }

    func test_payment_card_image() {
        XCTAssertNotNil(UIImage.cardPresentImage)
    }

    func test_payment_celebration_image() {
        XCTAssertNotNil(UIImage.celebrationImage)
    }

    func test_payment_error_image() {
        XCTAssertNotNil(UIImage.paymentErrorImage)
    }

    func test_payments_loading_not_nil() {
        XCTAssertNotNil(UIImage.paymentsLoading)
    }

    func test_stripe_plugin_not_nil() {
        XCTAssertNotNil(UIImage.stripePlugin)
    }

    func test_wcpay_plugin_not_nil() {
        XCTAssertNotNil(UIImage.wcPayPlugin)
    }

    func test_print_icon_in_not_nil() {
        XCTAssertNotNil(UIImage.print)
    }

    func testPlusImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.plusImage)
    }

    func testPlusBarButtonItemImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.plusBarButtonItemImage)
    }

    func test_plus_small_image_is_not_nil() {
        XCTAssertNotNil(UIImage.plusSmallImage)
    }

    func test_productDescriptionAIAnnouncementImage_is_not_nil() {
        XCTAssertNotNil(UIImage.productDescriptionAIAnnouncementImage)
    }

    func testPriceImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.priceImage)
    }

    func test_productDeletedImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.productDeletedImage)
    }

    func test_productErrorImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.productErrorImage)
    }

    func testProductReviewsImageIsNotNil() {
        XCTAssertNotNil(UIImage.productReviewsImage)
    }

    func testProductReviewsImageMatchesExpectedSize() {
        let size = CGSize(width: 24, height: 24)
        let image = UIImage.productReviewsImage
        XCTAssertEqual(size, image.size)
    }

    func testProductPlaceholderImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.productPlaceholderImage)
    }

    func testProductImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.productImage)
    }

    func testProductsTabWorkInProgressBannerIconIsNotNil() {
        XCTAssertNotNil(UIImage.workInProgressBanner)
    }

    func testPencilImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.pencilImage)
    }

    func testPagesImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.pagesImage)
    }

    func testPagesFootnoteImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.pagesFootnoteImage)
    }

    func testScanImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.scanImage)
    }

    func testSearchBarButtonItemImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.searchBarButtonItemImage)
    }

    func testShippingImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.shippingImage)
    }

    func testShippingClassListSelectorEmptyImageIsNotNil() {
        XCTAssertNotNil(UIImage.shippingClassListSelectorEmptyImage)
    }

    func test_shippingLabelCreationInfoImage_is_not_nil() {
        XCTAssertNotNil(UIImage.shippingLabelCreationInfoImage)
    }

    func test_globeImage_is_not_nil() {
        XCTAssertNotNil(UIImage.globeImage)
    }

    func testSpamImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.spamImage)
    }

    func testStarImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.starImage(size: 1))
    }

    func testStarImageMatchesExpectedSize() {
        let size = Double(1)
        let starImage = UIImage.starImage(size: size)
        XCTAssertEqual(starImage.size, CGSize(width: size, height: size))
    }

    func testStarOutlineImageMatchesExpectedSize() {
        let size = Double(1)
        let starOutlineImage = UIImage.starOutlineImage(size: size)
        XCTAssertEqual(starOutlineImage.size, CGSize(width: size, height: size))
    }

    func testStarOutlineImageDefaultSize() {
        let starOutlineImage = UIImage.starOutlineImage()
        XCTAssertEqual(starOutlineImage.size, Gridicon.defaultSize)
    }

    func testStatsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.statsImage)
    }

    func testStatsAltImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.statsAltImage)
    }

    func test_search_image_is_not_nil() {
        XCTAssertNotNil(UIImage.searchImage)
    }

    func test_searchNoResult_image_is_not_nil() {
        XCTAssertNotNil(UIImage.searchNoResultImage)
    }

    func testTrashImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.trashImage)
    }

    func testVariationsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.variationsImage)
    }

    func testVisibleImageIsNotNil() {
        XCTAssertNotNil(UIImage.visibilityImage)
    }

    func test_what_is_Jetpack_image() {
        XCTAssertNotNil(UIImage.whatIsJetpackImage)
    }

    func testWooLogoImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.wooLogoImage())
    }

    func testWooLogoImageMatchesExpectedSize() {
        let size = CGSize(width: 20, height: 20)
        let image = UIImage.wooLogoImage(withSize: size, tintColor: .clear)
        XCTAssertEqual(size, image!.size)
    }

    func test_wooLogoPrologueImage_is_not_nil() {
        XCTAssertNotNil(UIImage.wooLogoPrologueImage)
    }

    func testWaitingForCustomersImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.waitingForCustomersImage)
    }

    func testInstallWCShipImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.installWCShipImage)
    }

    func testWidgetsImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.widgetsImage)
    }

    func testCategoriesIconIsNotNil() {
        XCTAssertNotNil(UIImage.categoriesIcon)
    }

    func testCategoriesIconHasDefaultSize() {
        let categoriesIcon = UIImage.categoriesIcon
        XCTAssertEqual(categoriesIcon.size, Gridicon.defaultSize)
    }

    func testTagsIconIsNotNil() {
        XCTAssertNotNil(UIImage.tagsIcon)
    }

    func testTagsIconHasDefaultSize() {
        let tagsIcon = UIImage.tagsIcon
        XCTAssertEqual(tagsIcon.size, Gridicon.defaultSize)
    }

    func test_sync_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.syncIcon)
    }

    func test_sync_dot_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.syncDotIcon)
    }

    func testNoStoreImageIsNotNil() {
        XCTAssertNotNil(UIImage.noStoreImage)
    }

    func test_no_connection_image_is_not_nil() {
        XCTAssertNotNil(UIImage.noConnectionImage)
    }

    func test_megaphoneIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.megaphoneIcon)
    }

    func test_speakerIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.speakerIcon)
    }

    func testCloudImageIsNotNil() {
        XCTAssertNotNil(UIImage.cloudImage)
    }

    func test_copy_bar_button_item_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.copyBarButtonItemImage)
    }

    func test_coupon_image_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.couponImage)
    }

    func testHubMenuIconIsNotNil() {
        XCTAssertNotNil(UIImage.hubMenu)
    }

    func testMenuImageIconIsNotNil() {
        XCTAssertNotNil(UIImage.menuImage)
    }

    func test_wordPressLogoImage_is_not_nil() {
        XCTAssertNotNil(UIImage.wordPressLogoImage)
    }

    func test_errorImage_is_not_nil() {
        XCTAssertNotNil(UIImage.errorImage)
    }

    func test_emptyBoxImage_is_not_nil() {
        XCTAssertNotNil(UIImage.emptyBoxImage)
    }

    func test_curvedRectangle_is_not_nil() {
        XCTAssertNotNil(UIImage.curvedRectangle)
    }

    func test_prologueAnalyticsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.prologueAnalyticsImage)
    }

    func test_prologueOrdersImage_is_not_nil() {
        XCTAssertNotNil(UIImage.prologueOrdersImage)
    }

    func test_prologueProductsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.prologueProductsImage)
    }

    func test_prologueReviewsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.prologueReviewsImage)
    }

    func test_prologueWooMobileImage_is_not_nil() {
        XCTAssertNotNil(UIImage.prologueWooMobileImage)
    }

    func test_cloudOutlineImage_is_not_nil() {
        XCTAssertNotNil(UIImage.cloudOutlineImage)
    }

    func test_welcomeImage_is_not_nil() {
        XCTAssertNotNil(UIImage.welcomeImage)
    }

    func test_lightningImage_is_not_nil() {
        XCTAssertNotNil(UIImage.lightningImage)
    }

    func test_shoppingCartIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.shoppingCartIcon)
    }

    func test_creditCardIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.creditCardIcon)
    }

    func test_cardReaderManualIcon_is_not_nil() {
        XCTAssertNotNil(UIImage.cardReaderManualIcon)
    }

    func test_simplePaymentsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.simplePaymentsImage)
    }

    func test_enableAnalyticsImage_is_not_nil() {
        XCTAssertNotNil(UIImage.enableAnalyticsImage)
    }

    func test_creditCardGiveImage_is_not_nil() {
        XCTAssertNotNil(UIImage.creditCardGiveIcon)
    }

    func test_stripeIconImage_is_not_nil() {
        XCTAssertNotNil(UIImage.stripeIcon)
    }

    func test_wcpayIconImage_is_not_nil() {
        XCTAssertNotNil(UIImage.wcpayIcon)
    }

    func test_rectangle_on_rectangle_angled_is_not_nil() {
        XCTAssertNotNil(UIImage.rectangleOnRectangleAngled)
    }

    func test_circular_rate_discount_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.circularRateDiscountIcon)
    }

    func test_circular_document_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.circularDocumentIcon)
    }

    func test_circular_time_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.circularTimeIcon)
    }

    func test_lock_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.lockImage)
    }

    func test_reply_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.replyImage)
    }

    func test_sites_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.sitesImage)
    }

    func test_emptyStorePickerImage_is_not_nil() {
        XCTAssertNotNil(UIImage.emptyStorePickerImage)
    }

    func test_jetpackSetupImage_is_not_nil() {
        XCTAssertNotNil(UIImage.jetpackSetupImage)
    }

    func test_jetpackConnectionImage_is_not_nil() {
        XCTAssertNotNil(UIImage.jetpackConnectionImage)
    }

    func test_wpcomLogoImage_is_not_nil() {
        XCTAssertNotNil(UIImage.wpcomLogoImage())
    }

    func test_wpcomLogoImage_with_tint_color_is_not_nil() {
        XCTAssertNotNil(UIImage.wpcomLogoImage(tintColor: .red))
    }

    func test_jetpackSetupInterruptedImage_is_not_nil() {
        XCTAssertNotNil(UIImage.jetpackSetupInterruptedImage)
    }

    func test_calendar_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.calendar)
    }

    func test_app_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.appIconDefault)
    }

    func test_blankProductImage_is_not_nil() {
        XCTAssertNotNil(UIImage.blankProductImage)
    }

    func test_icon_bolt_is_not_nil() {
        XCTAssertNotNil(UIImage.iconBolt)
    }

    func test_free_trial_illustration_is_not_nil() {
        XCTAssertNotNil(UIImage.freeTrialIllustration)
    }

    func test_ecommerce_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.ecommerceIcon)
    }

    func test_support_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.supportIcon)
    }

    func test_backups_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.backupsIcon)
    }

    func test_gifts_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.giftIcon)
    }

    func test_emailOutline_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.emailOutlineIcon)
    }

    func test_shippingOutline_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.shippingOutlineIcon)
    }

    func test_advertising_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.advertisingIcon)
    }

    func test_launch_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.launchIcon)
    }

    func test_paymentsOption_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.paymentOptionsIcon)
    }

    func test_premiumThemes_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.premiumThemesIcon)
    }

    func test_siteSecurity_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.siteSecurityIcon)
    }

    func test_unlimitedProducts_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.unlimitedProductsIcon)
    }

    func test_subscriptionProductImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.subscriptionProductImage)
    }

    func test_variableSubscriptionProductImage_icon_is_not_nil() {
        XCTAssertNotNil(UIImage.variableSubscriptionProductImage)
    }

    func test_cashRegisterImage_is_not_nil() {
        XCTAssertNotNil(UIImage.cashRegisterImage)
    }

    func test_exclamationFilledImage_is_not_nil() {
        XCTAssertNotNil(UIImage.exclamationFilledImage)
    }

    func test_exclamationImage_is_not_nil() {
        XCTAssertNotNil(UIImage.exclamationImage)
    }

    func test_magnifyingGlassNotFound_is_not_nil() {
        XCTAssertNotNil(UIImage.magnifyingGlassNotFound)
    }
}

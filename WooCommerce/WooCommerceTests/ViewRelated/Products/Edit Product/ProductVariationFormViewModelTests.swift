import XCTest

@testable import WooCommerce
import Yosemite
import TestKit

final class ProductVariationFormViewModelTests: XCTestCase {
    // MARK: `canViewProductInStore`

    func test_edit_product_variation_form_with_published_status_can_view_product_in_store() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.published)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Then
        XCTAssertTrue(canViewProductInStore)
    }

    func test_add_product_variation_form_with_published_status_cannot_view_product_in_store() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.published)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Then
        XCTAssertFalse(canViewProductInStore)
    }

    func test_edit_product_variation_form_with_non_published_status_cannot_view_product_in_store() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.pending)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Then
        XCTAssertFalse(canViewProductInStore)
    }

    func test_add_product_variation_form_with_non_published_status_cannot_view_product_in_store() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Then
        XCTAssertFalse(canViewProductInStore)
    }

    // MARK: `canShareProduct`

    func test_edit_product_variation_form_with_published_status_can_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_variation_form_with_published_status_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.published)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_variation_form_with_non_published_status_can_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.pending)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_non_public_site_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .privateSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_variation_form_with_invalid_permalink_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "", status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_variation_form_with_valid_permalink_can_share_product() {
        // Given
        let product = ProductVariation.fake().copy(permalink: "https://example.com/product", status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    // MARK: - `canPromoteWithBlaze`

    func test_canPromoteWithBlaze_is_false_when_variation_is_public() {
        // Given
        let product = ProductVariation.fake().copy(status: .published)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        XCTAssertFalse(viewModel.canPromoteWithBlaze())
    }

    // MARK: Subscription Free trial

    func test_updateSubscriptionFreeTrialSettings_sets_subscription_free_trial_info() throws {
        // Given
        let product = ProductVariation.fake().copy(subscription: .fake().copy(trialLength: "4", trialPeriod: .month))
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        viewModel.updateSubscriptionFreeTrialSettings(trialLength: "5", trialPeriod: .week)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.trialLength, "5")
        XCTAssertEqual(subscription.trialPeriod, .week)
    }

    // MARK: Subscription Expire after

    func test_updateSubscriptionExpirySettings_sets_subscription_length_info() throws {
        // Given
        let product = ProductVariation.fake().copy(subscription: .fake().copy(length: "4"))
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        viewModel.updateSubscriptionExpirySettings(length: "5")

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.length, "5")
    }
}

private extension ProductVariationFormViewModelTests {
    func createViewModel(product: ProductVariation, formType: ProductFormType, stores: StoresManager = ServiceLocator.stores) -> ProductVariationFormViewModel {
        let model = EditableProductVariationModel(productVariation: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        return ProductVariationFormViewModel(productVariation: model,
                                             formType: formType,
                                             productImageActionHandler: productImageActionHandler,
                                             storesManager: stores)
    }
}

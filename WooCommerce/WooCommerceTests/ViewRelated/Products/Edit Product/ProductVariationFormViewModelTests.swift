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
        let product = ProductVariation.fake().copy(status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_variation_form_with_published_status_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.published)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_variation_form_with_non_published_status_can_share_product() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.pending)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_non_public_site_cannot_share_product() {
        // Given
        let product = ProductVariation.fake().copy(status: ProductStatus.published)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: false)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
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

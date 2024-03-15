import XCTest

@testable import WooCommerce
import Yosemite
import TestKit
import Experiments

final class ProductFormViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var sessionManager: SessionManager!
    private var stores: StoresManager!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
    }

    override func tearDown() {
        super.tearDown()
        analytics = nil
        analyticsProvider = nil
        sessionManager = nil
        stores = nil
    }

    // MARK: `canViewProductInStore`

    func test_edit_product_form_with_published_status_can_view_product_in_store() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertTrue(canViewProductInStore)
    }

    func test_add_product_form_with_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    func test_edit_product_form_with_non_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    func test_add_product_form_with_non_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    // MARK: `canShareProduct`

    func test_edit_product_form_with_published_status_can_share_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.published.rawValue)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_published_status_cannot_share_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_non_published_status_can_share_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.pending.rawValue)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_share_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_non_public_site_cannot_share_product() {
        // Given
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.published.rawValue)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: false)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_invalid_permalink_cannot_share_product() {
        // Given
        let product = Product.fake().copy(name: "Test", permalink: "", statusKey: ProductStatus.published.rawValue)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_valid_permalink_can_share_product() {
        // Given
        let product = Product.fake().copy(name: "Test", permalink: "https://example.com/product", statusKey: ProductStatus.published.rawValue)
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(isPublic: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let canShareProduct = viewModel.canShareProduct()

        // Then
        XCTAssertTrue(canShareProduct)
    }

    // MARK: - `canPromoteWithBlaze`

    func test_canPromoteWithBlaze_is_true_when_product_is_eligible_for_blaze() {
        // Given
        let product = Product.fake()
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isProductEligible: true)
        let viewModel = createViewModel(product: product, formType: .edit, blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        waitUntil {
            viewModel.canPromoteWithBlaze()
        }
    }

    func test_canPromoteWithBlaze_is_false_when_product_is_not_eligible_for_blaze() {
        // Given
        let product = Product.fake()
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isProductEligible: false)
        let viewModel = createViewModel(product: product, formType: .edit, blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        waitUntil {
            viewModel.canPromoteWithBlaze() == false
        }
    }

    func test_canPromoteWithBlaze_is_false_for_product_creation_when_product_is_eligible_for_blaze() {
            // Given
            let product = Product.fake()
            let blazeEligibilityChecker = MockBlazeEligibilityChecker(isProductEligible: true)
            let nonEditableFormTypes: [ProductFormType] = [.add, .readonly]

            // When
            nonEditableFormTypes.forEach { nonEditableFormType in
                // When
                let viewModel = createViewModel(product: product, formType: nonEditableFormType, blazeEligibilityChecker: blazeEligibilityChecker)

                waitUntil {
                    // Then
                    viewModel.canPromoteWithBlaze() == false
                }
            }
    }

    // MARK: - Favorite

    func test_canFavoriteProduct_is_true_when_form_type_is_not_add() {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product,
                                        formType: .edit,
                                        featureFlagService: MockFeatureFlagService(favoriteProducts: true))

        // When
        XCTAssertTrue(viewModel.canFavoriteProduct())
    }

    func test_canFavoriteProduct_is_false_when_form_type_add() {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product,
                                        formType: .add,
                                        featureFlagService: MockFeatureFlagService(favoriteProducts: true))

        // When
        XCTAssertFalse(viewModel.canFavoriteProduct())
    }

    func test_canFavoriteProduct_is_false_when_feature_flag_off() {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product,
                                        formType: .add,
                                        featureFlagService: MockFeatureFlagService(favoriteProducts: false))

        // When
        XCTAssertFalse(viewModel.canFavoriteProduct())
    }

    func test_markAsFavorite_marks_product_as_favorite() {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product,
                                        formType: .add,
                                        featureFlagService: MockFeatureFlagService(favoriteProducts: true))

        // When
        viewModel.markAsFavorite()

        // Then
        XCTAssertTrue(viewModel.isFavorite())
    }

    func test_removeFromFavorite_removes_product_as_favorite() {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product,
                                        formType: .add,
                                        featureFlagService: MockFeatureFlagService(favoriteProducts: true))
        viewModel.markAsFavorite()

        // When
        viewModel.removeFromFavorite()

        // Then
        XCTAssertFalse(viewModel.isFavorite())
    }

    // MARK: `canDeleteProduct`

    func test_edit_product_form_with_published_status_can_delete_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertTrue(canDeleteProduct)
    }

    func test_add_product_form_with_published_status_cannot_delete_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertFalse(canDeleteProduct)
    }

    func test_edit_product_form_with_non_published_status_can_delete_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertTrue(canDeleteProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_delete_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertFalse(canDeleteProduct)
    }

    // MARK: `canDuplicateProduct`
    func test_add_product_form_with_non_published_status_cannot_duplicate_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canDuplicateProduct = viewModel.canDuplicateProduct()

        // Assert
        XCTAssertFalse(canDuplicateProduct)
    }

    func test_edit_product_form_with_non_published_status_can_duplicate_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.pending.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDuplicateProduct = viewModel.canDuplicateProduct()

        // Assert
        XCTAssertTrue(canDuplicateProduct)
    }

    func test_edit_product_form_with_published_status_can_duplicate_product() {
        // Arrange
        let product = Product.fake().copy(name: "Test", statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDuplicateProduct = viewModel.canDuplicateProduct()

        // Assert
        XCTAssertTrue(canDuplicateProduct)
    }

    func test_update_variations_updates_original_product_while_maintaining_pending_changes() throws {
        // Given
        let product = Product.fake()
        let viewModel = createViewModel(product: product, formType: .edit)
        viewModel.updateName("new-name")

        // When
        let attributes = ProductAttribute(siteID: 0, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Green, Blue"])
        let newProduct = product.copy(attributes: [attributes], variations: [1])
        viewModel.updateProductVariations(from: newProduct)

        // Then
        XCTAssertEqual(viewModel.productModel.name, "new-name")
        XCTAssertEqual(viewModel.productModel.product.variations, newProduct.variations)
        XCTAssertEqual(viewModel.productModel.product.attributes, newProduct.attributes)
    }

    func test_update_variations_fires_replace_product_action() throws {
        // Given
        let product = Product.fake()
        let mockStores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = createViewModel(product: product, formType: .edit, stores: mockStores)

        // When
        let attributes = ProductAttribute(siteID: 0, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Green, Blue"])
        let newProduct = product.copy(attributes: [attributes], variations: [1])

        let receivedReplaceProductAction: Bool = waitFor { promise in
            mockStores.whenReceivingAction(ofType: ProductAction.self) { action in
                switch action {
                case .replaceProductLocally:
                    promise(true)
                default:
                    promise(false)
                }
            }
            viewModel.updateProductVariations(from: newProduct)
        }

        // Then
        XCTAssertTrue(receivedReplaceProductAction)
    }

    func test_updateProductVariations_with_new_draft_product_updates_original_product_and_formType() throws {
        // Given
        let product = Product.fake().copy(productID: 0)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let attributes = ProductAttribute(siteID: 0, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Green, Blue"])
        let newProduct = product.copy(productID: 10, statusKey: "draft", attributes: [attributes], variations: [1])
        viewModel.updateProductVariations(from: newProduct)

        // Then
        XCTAssertEqual(viewModel.originalProductModel.productID, newProduct.productID)
        XCTAssertEqual(viewModel.originalProductModel.status, newProduct.productStatus)
        XCTAssertEqual(viewModel.formType, .edit)
    }

    func test_action_buttons_for_new_product_and_pending_changes() throws {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, isVirtual: false, siteID: 123))
        let viewModel = createViewModel(product: product, formType: .add, stores: stores)
        viewModel.updateName("new name")

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.preview, .publish, .more])
    }

    func test_action_buttons_for_new_product_and_no_pending_changes() throws {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, isVirtual: false, siteID: 123))
        let viewModel = createViewModel(product: product, formType: .add, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.preview, .publish, .more])
    }

    func test_action_buttons_for_new_template_product() throws {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")

        // Adding some value to simulate a template product
        let product = try XCTUnwrap(ProductFactory().createNewProduct(type: .simple, isVirtual: false, siteID: 123)?.copy(price: "10.00"))
        let viewModel = createViewModel(product: product, formType: .add, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.preview, .publish, .more])
        XCTAssertTrue(viewModel.shouldEnablePreviewButton())
    }

    func test_action_buttons_for_new_product_with_different_status() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add, stores: stores)

        let updatedProduct = product.copy(statusKey: ProductStatus.draft.rawValue)
        let settings = ProductSettings(from: updatedProduct, password: nil)
        viewModel.updateProductSettings(settings)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.save, .more])
    }

    func test_action_buttons_for_existing_published_product_and_pending_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)
        viewModel.updateName("new name")

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.save, .more])
    }

    func test_action_buttons_for_existing_published_product_and_no_pending_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123", isPublic: true)
        let product = Product.fake().copy(productID: 123,
                                          permalink: "https://example.com/product",
                                          statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.share, .more])
    }

    func test_action_buttons_for_existing_draft_product_and_pending_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)
        viewModel.updateName("new name")

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.preview, .save, .more])
    }

    func test_action_buttons_for_existing_draft_product_and_no_pending_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.preview, .publish, .more])
    }

    func test_action_buttons_for_existing_product_with_other_status_and_peding_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(productID: 123, statusKey: "other")
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)
        viewModel.updateName("new name")

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.save, .more])
    }

    func test_action_buttons_for_existing_product_with_other_status_and_no_peding_changes() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123")
        let product = Product.fake().copy(productID: 123, statusKey: "other")
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.publish, .more])
    }

    func test_action_buttons_for_any_product_in_read_only_mode() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "abc123", isPublic: true)
        let product = Product.fake().copy(productID: 123,
                                          permalink: "https://example.com/product",
                                          statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .readonly, stores: stores)
        viewModel.updateName("new name")

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.share, .more])
    }

    func test_no_preview_button_for_existing_draft_product_on_site_with_no_frame_nonce() {
        // Given
        sessionManager.defaultSite = Site.fake().copy(frameNonce: "")

        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit, stores: stores)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.publish, .more])
    }

    func test_canPublishOption_is_true_when_creating_new_product_with_different_status() {
        // Given
        let product = Product.fake().copy(productID: 0, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertTrue(canShowPublishOption)
    }

    func test_canPublishOption_is_false_when_creating_new_product_with_publish_status() {
        // Given
        let product = Product.fake().copy(productID: 0, statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertFalse(canShowPublishOption)
    }

    func test_canPublishOption_is_true_when_editing_existing_draft_product_with_changes() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        viewModel.updateName("new_name")

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertTrue(canShowPublishOption)
    }

    func test_canPublishOption_is_false_when_editing_existing_draft_product_without_changes() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertFalse(canShowPublishOption)
    }

    func test_canPublishOption_is_false_when_editing_existing_published_product_without_changes() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertFalse(canShowPublishOption)
    }

    func test_canPublishOption_is_false_when_editing_existing_published_product_with_changes() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        viewModel.updateName("new_name")

        // When
        let canShowPublishOption = viewModel.canShowPublishOption()

        // Then
        XCTAssertFalse(canShowPublishOption)
    }

    func test_publish_message_is_shown_when_publishing_an_new_product() {
        // Given
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)

        // When
        let messageType = viewModel.saveMessageType(for: .published)

        // Then
        assertEqual(messageType, .publish)
    }

    func test_publish_message_is_shown_when_publishing_a_draft_product() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let messageType = viewModel.saveMessageType(for: .published)

        // Then
        assertEqual(messageType, .publish)
    }

    func test_save_message_is_shown_when_updating_a_published_product() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let messageType = viewModel.saveMessageType(for: .published)

        // Then
        assertEqual(messageType, .save)
    }

    func test_save_message_is_shown_when_updating_a_draft_product() {
        // Given
        let product = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        let messageType = viewModel.saveMessageType(for: .draft)

        // Then
        assertEqual(messageType, .save)
    }

    func test_viewModel_correctly_tracks_product_form_loaded() throws {
        // Given
        let product = Product.fake().copy(upsellIDs: [1])
        let viewModel = createViewModel(product: product, formType: .edit, analytics: analytics)

        // When
        viewModel.trackProductFormLoaded()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.productDetailLoaded.rawValue)

        let hasLinkedProducts = try XCTUnwrap(analyticsProvider.receivedProperties.first?["has_linked_products"] as? Bool)
        XCTAssertTrue(hasLinkedProducts)
    }

    func test_onProductCreated_called_when_new_product_saved_remotely() {
        // Given
        var isCallbackCalled = false
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = createViewModel(product: Product.fake(), formType: .add, stores: stores)
        viewModel.onProductCreated = { _ in
            isCallbackCalled = true
        }

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .addProduct(product, onCompletion):
                onCompletion(.success(product))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.saveProductRemotely(status: .draft) { _ in }

        // Then
        XCTAssertTrue(isCallbackCalled)
    }

    func test_updateDownloadableFiles_sets_downloadable_when_adding_files() {
        // Given
        let product = Product.fake().copy(downloadable: false, downloads: [.fake()])
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        viewModel.updateDownloadableFiles(downloadableFiles: [.fake()], downloadLimit: 0, downloadExpiry: 0)

        // Then
        XCTAssertTrue(viewModel.productModel.downloadable)
    }

    func test_updateDownloadableFiles_does_not_change_downloadable_when_empty_files() {
        // Given
        let product = Product.fake().copy(downloadable: false, downloads: [.fake()])
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        viewModel.updateDownloadableFiles(downloadableFiles: [], downloadLimit: 0, downloadExpiry: 0)

        // Then
        XCTAssertFalse(viewModel.productModel.downloadable)
    }


    // MARK: Subscription Free trial

    func test_updateSubscriptionFreeTrialSettings_sets_subscription_free_trial_info() throws {
        // Given
        let product = Product.fake().copy(subscription: .fake().copy(trialLength: "4", trialPeriod: .month))
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
        let product = Product.fake().copy(subscription: .fake().copy(length: "4"))
        let viewModel = createViewModel(product: product, formType: .edit)

        // When
        viewModel.updateSubscriptionExpirySettings(length: "5")

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.length, "5")
    }
}

private extension ProductFormViewModelTests {
    func createViewModel(product: Product,
                         formType: ProductFormType,
                         stores: StoresManager = ServiceLocator.stores,
                         analytics: Analytics = ServiceLocator.analytics,
                         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker(),
                         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) -> ProductFormViewModel {
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        return ProductFormViewModel(product: model,
                                    formType: formType,
                                    productImageActionHandler: productImageActionHandler,
                                    stores: stores,
                                    analytics: analytics,
                                    blazeEligibilityChecker: blazeEligibilityChecker,
                                    featureFlagService: featureFlagService)
    }
}

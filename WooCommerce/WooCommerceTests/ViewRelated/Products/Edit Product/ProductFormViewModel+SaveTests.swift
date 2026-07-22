import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for `ProductFormViewModel`'s `saveProductRemotely`
final class ProductFormViewModel_SaveTests: XCTestCase {
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(storesManager)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    // MARK: `saveProductRemotely` for adding a product

    func test_adding_a_product_remotely_with_nil_status_uses_the_original_product() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.addProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: nil) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(savedProduct, EditableProductModel(product: product))
    }

    func test_adding_a_product_remotely_with_a_given_status_overrides_the_status_of_the_original_product() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .add)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.addProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .pending) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(savedProduct, EditableProductModel(product: product.copy(statusKey: ProductStatus.pending.rawValue)))
    }

    func test_adding_a_product_remotely_fires_replaceLocalID_in_productImagesUploader() throws {
        // Given
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let productImagesUploader = MockProductImageUploader()
        let viewModel = createViewModel(product: product, formType: .add, productImagesUploader: productImagesUploader)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.addProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // When
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .pending) { _ in
                expectation.fulfill()
            }
        }
        // Then
        XCTAssertTrue(productImagesUploader.replaceLocalIDWasCalled)
    }

    func test_adding_a_product_remotely_fires_method_to_save_images_in_background_using_productImagesUploader() throws {
        // Given
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let productImagesUploader = MockProductImageUploader()
        let viewModel = createViewModel(product: product, formType: .add, productImagesUploader: productImagesUploader)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.addProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // When
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .pending) { _ in
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(productImagesUploader.saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled)
    }

    // MARK: `saveProductRemotely` for editing a product

    func test_editing_a_product_remotely_with_nil_status_uses_the_original_product() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: nil) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(savedProduct, EditableProductModel(product: product))
    }

    func test_editing_a_product_remotely_with_a_given_status_overrides_the_status_of_the_original_product() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                onCompletion(.success(product))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .pending) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(savedProduct, EditableProductModel(product: product.copy(statusKey: ProductStatus.pending.rawValue)))
    }

    func test_editing_a_product_remotely_with_changes_in_details_triggers_updateProduct() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        viewModel.updateName("Test")
        var updateProductTriggered = false
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                updateProductTriggered = true
                onCompletion(.success(product.copy(name: "Test")))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .published) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(updateProductTriggered)
        XCTAssertEqual(savedProduct, EditableProductModel(product: product.copy(name: "Test")))
    }

    func test_editing_a_product_remotely_with_changes_in_uploaded_images_triggers_updateProduct() throws {
        // Arrange
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let viewModel = createViewModel(product: product, formType: .edit)
        let newImage = ProductImage.fake().copy(imageID: 134)
        viewModel.updateImages([newImage])
        var updateProductTriggered = false
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                updateProductTriggered = true
                onCompletion(.success(product.copy(images: [newImage])))
            }
        }

        // Action
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .published) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Assert
        XCTAssertTrue(updateProductTriggered)
        XCTAssertEqual(savedProduct, EditableProductModel(product: product.copy(images: [newImage])))
    }

    func test_editing_a_product_remotely_fires_method_to_save_images_in_background_using_productImagesUploader() throws {
        // Given
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)
        let productImagesUploader = MockProductImageUploader()
        let viewModel = createViewModel(product: product, formType: .edit, productImagesUploader: productImagesUploader)
        var updateProductTriggered = false
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                updateProductTriggered = true
                onCompletion(.success(product))
            }
        }

        // When
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .published) { _ in
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(productImagesUploader.saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled)
        XCTAssertFalse(updateProductTriggered)
    }

    func test_saveProductRemotely_when_draft_variable_product_saved_with_published_status_then_saves_with_published_status() throws {
        // Given
        let product = Product.fake().copy(
            productID: 123,
            productTypeKey: ProductType.variable.rawValue,
            statusKey: ProductStatus.draft.rawValue
        )
        let viewModel = createViewModel(product: product, formType: .edit)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let ProductAction.updateProduct(product, onCompletion) = action {
                onCompletion(.success(product.copy(statusKey: product.statusKey)))
            }
        }

        // When
        var savedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.saveProductRemotely(status: .published) { result in
                savedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(savedProduct?.status, .published)
    }

    // MARK: `duplicateProduct`

    func test_duplicateProduct_does_not_change_original_form_baseline() throws {
        // Given
        let originalProduct = Product.fake().copy(productID: 123,
                                                  name: "Original",
                                                  statusKey: ProductStatus.published.rawValue)
        let productImagesUploader = MockProductImageUploader()
        let viewModel = createViewModel(product: originalProduct, formType: .edit, productImagesUploader: productImagesUploader)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, _, onCompletion):
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(productToSave, onCompletion):
                // Simulate the server returning the duplicate with a new ID and copied name.
                onCompletion(.success(productToSave.copy(productID: 456, name: "Original Copy")))
            default:
                break
            }
        }

        // When
        var duplicatedProduct: EditableProductModel?
        waitForExpectation { expectation in
            viewModel.duplicateProduct { result in
                duplicatedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        // The completion returns the duplicate...
        XCTAssertEqual(duplicatedProduct?.productID, 456)
        // ...but this form still represents the original product, so its baseline must be untouched.
        XCTAssertEqual(viewModel.originalProductModel, EditableProductModel(product: originalProduct))
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_duplicateProduct_uses_captured_saved_aggregate_and_password_in_compatibility_fallback() throws {
        // Given
        let savedPassword = "saved-password"
        let savedProduct = Product.fake().copy(productID: 123,
                                               name: "Saved product",
                                               slug: "saved-product",
                                               permalink: "https://example.com/saved-product",
                                               statusKey: ProductStatus.published.rawValue,
                                               sku: "saved-sku",
                                               variations: [11, 12],
                                               password: savedPassword)
        let viewModel = createViewModel(product: savedProduct, formType: .edit)
        viewModel.resetPassword(savedPassword)
        viewModel.updateName("Unsaved product")
        viewModel.updateProductSettings(ProductSettings(from: viewModel.productModel.product, password: "unsaved-password"))
        let snapshot = try XCTUnwrap(viewModel.productDuplicationSnapshot())

        // Change the persisted baseline after the initial intent. The captured source must remain unchanged.
        viewModel.updateProductVariations(from: savedProduct.copy(variations: [99]))
        viewModel.resetPassword("later-password")

        var productSentToFallback: Product?
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(siteID, productID, onCompletion):
                XCTAssertEqual(siteID, savedProduct.siteID)
                XCTAssertEqual(productID, savedProduct.productID)
                onCompletion(.failure(.endpointUnavailable))
            case let .addProduct(product, _):
                productSentToFallback = product
            default:
                break
            }
        }

        // When
        viewModel.duplicateProduct(from: snapshot) { _ in
            XCTFail("The fallback request is intentionally left pending")
        }

        // Then
        let expectedFallbackProduct = savedProduct.copy(productID: 0,
                                                        name: "Saved product Copy",
                                                        slug: "",
                                                        permalink: "",
                                                        statusKey: ProductStatus.draft.rawValue,
                                                        sku: .some(nil),
                                                        password: savedPassword)
        XCTAssertEqual(productSentToFallback, expectedFallbackProduct)
        XCTAssertEqual(viewModel.productModel.name, "Unsaved product")
    }

    func test_duplicateProduct_failure_retains_live_product_and_password_draft() {
        // Given
        let savedProduct = Product.fake().copy(productID: 123, name: "Saved product")
        let viewModel = createViewModel(product: savedProduct, formType: .edit)
        viewModel.resetPassword("saved-password")
        viewModel.updateName("Unsaved product")
        viewModel.updateProductSettings(ProductSettings(from: viewModel.productModel.product, password: "unsaved-password"))
        let expectedDraft = viewModel.productModel
        let error = NSError(domain: "ProductDuplicate", code: 500)
        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .duplicateProduct(_, _, onCompletion) = action {
                onCompletion(.failure(.unknown(error: AnyError(error))))
            }
        }

        // When
        var result: Result<EditableProductModel, ProductUpdateError>?
        viewModel.duplicateProduct { result = $0 }

        // Then
        XCTAssertEqual(result, .failure(.unknown(error: AnyError(error))))
        XCTAssertEqual(viewModel.productModel, expectedDraft)
        XCTAssertEqual(viewModel.password, "unsaved-password")
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_duplicateProduct_for_edit_form_product_with_productID_zero_no_ops() {
        // Given
        let product = Product.fake().copy(productID: 0)
        let viewModel = createViewModel(product: product, formType: .edit)
        var completionCalled = false

        // When
        viewModel.duplicateProduct { _ in completionCalled = true }

        // Then
        XCTAssertFalse(completionCalled)
        XCTAssertFalse(storesManager.receivedActions.contains { action in
            guard let productAction = action as? ProductAction else {
                return false
            }
            if case .duplicateProduct = productAction {
                return true
            }
            return false
        })
    }
}

private extension ProductFormViewModel_SaveTests {
    func createViewModel(
        product: Product,
        formType: ProductFormType,
        productImagesUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader
    ) -> ProductFormViewModel {
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        return ProductFormViewModel(product: model,
                                    formType: formType,
                                    productImageActionHandler: productImageActionHandler,
                                    productImagesUploader: productImagesUploader)
    }
}

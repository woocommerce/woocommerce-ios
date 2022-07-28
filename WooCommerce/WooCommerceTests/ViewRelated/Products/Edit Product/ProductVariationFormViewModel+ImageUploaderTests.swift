import Combine
import Photos
import XCTest

@testable import WooCommerce
import Yosemite

final class ProductVariationFormViewModel_ImageUploaderTests: XCTestCase {
    private var storesManager: MockStoresManager!
    private var subscriptions: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_isUpdateEnabled_is_false_after_saving_a_variation_while_an_image_is_uploading() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(status: .published)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = MockProductImageActionHandler(productImageStatuses: [.uploading(asset: PHAsset())])
        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: storesManager,
                                                      isBackgroundImageUploadEnabled: true)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let ProductVariationAction.updateProductVariation(productVariation, onCompletion) = action {
                onCompletion(.success(productVariation))
            }
        }

        var isUpdateEnabledValues: [Bool] = []
        viewModel.isUpdateEnabled.removeDuplicates().sink { isUpdateEnabled in
            isUpdateEnabledValues.append(isUpdateEnabled)
        }.store(in: &subscriptions)
        XCTAssertEqual(isUpdateEnabledValues, [])

        // When
        waitFor { promise in
            viewModel.saveProductRemotely(status: .published) { result in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(isUpdateEnabledValues, [false])
    }

    func test_isUpdateEnabled_becomes_false_after_saving_a_variation_from_image_upload() throws {
        // Given
        let originalImage = ProductImage.fake().copy(imageID: 7)
        let productVariation = ProductVariation.fake().copy(image: originalImage, status: .published)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = MockProductImageActionHandler(productImageStatuses: [])
        let productImageUploader = MockProductImageUploader()
        let image = ProductImage.fake().copy(imageID: 6)
        productImageUploader.whenProductIsSaved(thenReturn: .success([image]))
        productImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: storesManager,
                                                      productImagesUploader: productImageUploader,
                                                      isBackgroundImageUploadEnabled: true)

        var isUpdateEnabledValues: [Bool] = []
        viewModel.isUpdateEnabled.removeDuplicates().sink { isUpdateEnabled in
            isUpdateEnabledValues.append(isUpdateEnabled)
        }.store(in: &subscriptions)
        XCTAssertEqual(isUpdateEnabledValues, [])

        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let ProductVariationAction.updateProductVariation(productVariation, completion) = action {
                completion(.success(productVariation))
            }
        }

        XCTAssertEqual(viewModel.originalProductModel.images, [originalImage])
        XCTAssertEqual(viewModel.productModel.images, [originalImage])

        // When
        // Adds an image to the variation.
        viewModel.updateImages([image])
        XCTAssertEqual(isUpdateEnabledValues, [true])

        let _: Void = waitFor { promise in
            productImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: false)
            viewModel.saveProductRemotely(status: .published) { result in
                promise(())
            }
            XCTAssertEqual(isUpdateEnabledValues, [true, false])
        }

        // Then
        XCTAssertEqual(isUpdateEnabledValues, [true, false])
        XCTAssertEqual(viewModel.originalProductModel.images, [image])
        XCTAssertEqual(viewModel.productModel.images, [image])
    }

    func test_isUpdateEnabled_is_always_false_when_image_was_saved_previously() throws {
        // Given
        let originalImage = ProductImage.fake().copy(imageID: 7)
        let productVariation = ProductVariation.fake().copy(image: originalImage, status: .published)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = MockProductImageActionHandler(productImageStatuses: [])
        let productImageUploader = MockProductImageUploader()
        let image = ProductImage.fake().copy(imageID: 6)
        productImageUploader.whenProductIsSaved(thenReturn: .success([image]))

        // Sets `hasUnsavedChangesOnImages` to `false` to simulate the scenario when an image was saved previously
        // and thus no unsaved changes on the variation image.
        productImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: false)

        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: storesManager,
                                                      productImagesUploader: productImageUploader,
                                                      isBackgroundImageUploadEnabled: true)

        var isUpdateEnabledValues: [Bool] = []
        viewModel.isUpdateEnabled.removeDuplicates().sink { isUpdateEnabled in
            isUpdateEnabledValues.append(isUpdateEnabled)
        }.store(in: &subscriptions)
        XCTAssertEqual(isUpdateEnabledValues, [])

        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let ProductVariationAction.updateProductVariation(productVariation, completion) = action {
                completion(.success(productVariation))
            }
        }

        XCTAssertEqual(viewModel.originalProductModel.images, [originalImage])
        XCTAssertEqual(viewModel.productModel.images, [originalImage])

        // When
        // Adds an image to the variation.
        viewModel.updateImages([image])
        XCTAssertEqual(isUpdateEnabledValues, [false])

        let _: Void = waitFor { promise in
            viewModel.saveProductRemotely(status: .published) { result in
                promise(())
            }
            XCTAssertEqual(isUpdateEnabledValues, [false])
        }

        // Then
        XCTAssertEqual(isUpdateEnabledValues, [false])
        XCTAssertEqual(viewModel.originalProductModel.images, [image])
        XCTAssertEqual(viewModel.productModel.images, [image])
    }
}

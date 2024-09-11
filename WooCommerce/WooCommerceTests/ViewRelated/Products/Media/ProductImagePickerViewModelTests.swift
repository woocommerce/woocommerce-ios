import XCTest
@testable import WooCommerce

import Yosemite
import protocol Storage.StorageType
import protocol Storage.StorageManagerType

final class ProductImagePickerViewModelTests: XCTestCase {

    private let siteID: Int64 = 123

    private let productID: Int64 = 33

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// View storage for tests
    ///
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_productImages_is_updated_correctly_when_there_exists_current_product_in_storage() async {
        // Given
        let image1 = ProductImage.fake().copy(imageID: 13)
        let image2 = ProductImage.fake().copy(imageID: 14)
        let product = Product.fake().copy(siteID: siteID, productID: productID, images: [image1])
        insertProduct(product)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductImagePickerViewModel(siteID: siteID, productID: productID, stores: stores, storage: storageManager)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProduct(_, _, onCompletion):
                XCTAssertEqual(viewModel.productImages, [image1])
                let product = Product.fake().copy(siteID: self.siteID, productID: self.productID, images: [image1, image2])
                self.insertProduct(product)
                onCompletion(.success(product))
            default:
                break
            }
        }
        await viewModel.retrieveProductImages()

        // Then
        XCTAssertEqual(viewModel.productImages, [image1, image2])
    }

    @MainActor
    func test_loadingData_is_updated_correctly() async {
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductImagePickerViewModel(siteID: siteID, productID: productID, stores: stores, storage: storageManager)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProduct(_, _, onCompletion):
                XCTAssertTrue(viewModel.loadingData)
                let product = Product.fake().copy(siteID: self.siteID, productID: self.productID, images: [])
                onCompletion(.success(product))
            default:
                break
            }
        }
        await viewModel.retrieveProductImages()

        // Then
        XCTAssertFalse(viewModel.loadingData)
    }
}

private extension ProductImagePickerViewModelTests {
    func insertProduct(_ readOnlyProduct: Product) {
        storage.deleteProducts(siteID: siteID)
        let storageProduct = storage.insertNewObject(ofType: StorageProduct.self)
        storageProduct.update(with: readOnlyProduct)

        for image in readOnlyProduct.images {
            let storageImage = storage.insertNewObject(ofType: StorageProductImage.self)
            storageImage.update(with: image)
            storageProduct.addToImages(storageImage)
        }
        storage.saveIfNeeded()
    }
}

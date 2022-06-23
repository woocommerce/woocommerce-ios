import Combine
import XCTest

@testable import WooCommerce

final class ProductFormViewController_ProductImageUploaderTests: XCTestCase {
    func test_triggering_viewDidLoad_invokes_stopEmittingStatusUpdates() throws {
        // Given
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: 256, imageStatuses: [])
        let productImageUploader = MockProductImageUploader()

        // When
        let productForm = ProductFormViewController(viewModel:
                                                        ProductFormViewModel(product: .init(product: .fake()),
                                                                             formType: .edit,
                                                                             productImageActionHandler: actionHandler),
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: actionHandler,
                                                    presentationStyle: .navigationStack,
                                                    productImageUploader: productImageUploader)
        productForm.viewDidLoad()

        // Then
        XCTAssertFalse(productImageUploader.startEmittingStatusUpdatesWasCalled)
        XCTAssertTrue(productImageUploader.stopEmittingStatusUpdatesWasCalled)
    }

    func test_deinit_invokes_startEmittingStatusUpdates() throws {
        // Given
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: 256, imageStatuses: [])
        let productImageUploader = MockProductImageUploader()

        // When
        var productForm: ProductFormViewController<ProductFormViewModel>? =
        ProductFormViewController(viewModel:
                                    ProductFormViewModel(product: .init(product: .fake()),
                                                         formType: .edit,
                                                         productImageActionHandler: actionHandler),
                                  eventLogger: ProductFormEventLogger(),
                                  productImageActionHandler: actionHandler,
                                  presentationStyle: .navigationStack,
                                  productImageUploader: productImageUploader)
        productForm = nil
        XCTAssertNil(productForm)

        // Then
        XCTAssertTrue(productImageUploader.startEmittingStatusUpdatesWasCalled)
    }
}

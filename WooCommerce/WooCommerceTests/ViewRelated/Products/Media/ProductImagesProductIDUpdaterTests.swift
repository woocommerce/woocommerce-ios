@testable import WooCommerce
import XCTest
import Yosemite

final class ProductImagesProductIDUpdaterTests: XCTestCase {
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .testingInstance)
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_updateProductIDOfImage_dispatches_MediaAction_updateProductID_to_update_media_parent_id() async throws {
        // Given
        let productImage = ProductImage.fake()
        let media = Media.fake().copy(mediaID: productImage.imageID)
        let productImagesProductIDUpdater = ProductImagesProductIDUpdater(stores: storesManager)
        storesManager.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let MediaAction.updateProductID(_, _, _, onCompletion) = action {
                onCompletion(.success(media))
            }
        }

        // When
        let savedMedia = try await productImagesProductIDUpdater.updateImageProductID(siteID: 1,
                                                                                      productID: 1,
                                                                                      productImage: productImage)
        // Then
        XCTAssertEqual(savedMedia, media)
    }
}

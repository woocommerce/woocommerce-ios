import Foundation
import Testing
import Yosemite
import Fakes
import YosemiteTestHelpers
@testable import WooCommerce

struct RefundDetailsViewModelTests {
    private let siteID: Int64 = 123
    private let productID: Int64 = 1
    private let variationID: Int64 = 10

    @Test func dataSource_uses_the_injected_storageManager_to_resolve_images() {
        // Given
        let storageManager = MockStorageManager()
        let variation = ProductVariation.fake().copy(siteID: siteID,
                                                     productID: productID,
                                                     productVariationID: variationID,
                                                     image: ProductImage.fake().copy(src: "https://example.com/variation.jpg"))
        insert(variation: variation, into: storageManager)
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: variationID)
        let viewModel = RefundDetailsViewModel(order: Order.fake().copy(siteID: siteID),
                                               refund: Refund.fake().copy(items: [refundedItem]),
                                               storageManager: storageManager)

        // When
        viewModel.configureResultsControllers(onReload: {})

        // Then
        #expect(viewModel.dataSource.imageURL(for: refundedItem) == URL(string: "https://example.com/variation.jpg"))
    }
}

private extension RefundDetailsViewModelTests {
    /// `update(with:)` only copies attributes, so the image relationship is attached manually.
    func insert(variation: ProductVariation, into storageManager: MockStorageManager) {
        let storageVariation = storageManager.viewStorage.insertNewObject(ofType: StorageProductVariation.self)
        storageVariation.update(with: variation)
        if let image = variation.image {
            let storageImage = storageManager.viewStorage.insertNewObject(ofType: StorageProductImage.self)
            storageImage.update(with: image)
            storageVariation.image = storageImage
        }
    }
}

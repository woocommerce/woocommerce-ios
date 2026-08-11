import Foundation
import Testing
import Yosemite
import Fakes
import YosemiteTestHelpers
@testable import WooCommerce

struct RefundedProductsViewModelTests {
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
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
        let refundedItem = MockAggregateOrderItem.emptyItem().copy(productID: productID, variationID: variationID)
        let viewModel = RefundedProductsViewModel(order: Order.fake().copy(siteID: siteID),
                                                  refundedProducts: [refundedItem],
                                                  storageManager: storageManager)

        // When
        viewModel.configureResultsControllers(onReload: {})

        // Then
        #expect(viewModel.dataSource.imageURL(for: refundedItem) == URL(string: "https://example.com/variation.jpg"))
    }
}

import Foundation
import Testing
import Yosemite
import Fakes
import YosemiteTestHelpers
@testable import WooCommerce

struct RefundDetailsDataSourceTests {
    private let storageManager: MockStorageManager
    private let order: Order

    private let siteID: Int64 = 123
    private let productID: Int64 = 1
    private let variationID: Int64 = 10

    init() {
        storageManager = MockStorageManager()
        order = Order.fake().copy(siteID: siteID)
    }

    @Test func imageURL_when_item_is_a_variation_then_it_returns_the_variation_image() {
        // Given
        let variation = ProductVariation.fake().copy(siteID: siteID,
                                                     productID: productID,
                                                     productVariationID: variationID,
                                                     image: ProductImage.fake().copy(src: "https://example.com/variation.jpg"))
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: variationID)
        let dataSource = makeDataSource(items: [refundedItem])

        // When
        let imageURL = dataSource.imageURL(for: refundedItem)

        // Then
        #expect(imageURL == URL(string: "https://example.com/variation.jpg"))
    }

    @Test func imageURL_when_item_is_a_simple_product_then_it_returns_the_product_image() {
        // Given
        let product = Product.fake().copy(siteID: siteID,
                                          productID: productID,
                                          images: [ProductImage.fake().copy(src: "https://example.com/product.jpg")])
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: 0)
        let dataSource = makeDataSource(items: [refundedItem])

        // When
        let imageURL = dataSource.imageURL(for: refundedItem)

        // Then
        #expect(imageURL == URL(string: "https://example.com/product.jpg"))
    }

    @Test func imageURL_when_the_variation_is_not_in_storage_then_it_returns_nil() {
        // Given
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: variationID)
        let dataSource = makeDataSource(items: [refundedItem])

        // When
        let imageURL = dataSource.imageURL(for: refundedItem)

        // Then
        #expect(imageURL == nil)
    }

    @Test func imageURL_when_the_variation_image_URL_has_spaces_then_it_returns_a_percent_encoded_URL() {
        // Given
        let variation = ProductVariation.fake().copy(siteID: siteID,
                                                     productID: productID,
                                                     productVariationID: variationID,
                                                     image: ProductImage.fake().copy(src: "https://example.com/variation image.jpg"))
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: variationID)
        let dataSource = makeDataSource(items: [refundedItem])

        // When
        let imageURL = dataSource.imageURL(for: refundedItem)

        // Then
        #expect(imageURL == URL(string: "https://example.com/variation%20image.jpg"))
    }
}

private extension RefundDetailsDataSourceTests {
    func makeDataSource(items: [OrderItemRefund]) -> RefundDetailsDataSource {
        let dataSource = RefundDetailsDataSource(refund: Refund.fake().copy(items: items),
                                                 order: order,
                                                 storageManager: storageManager)
        dataSource.configureResultsControllers(onReload: {})
        return dataSource
    }
}

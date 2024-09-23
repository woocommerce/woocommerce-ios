import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingItemsDataSourceTests: XCTestCase {

    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .testingInstance)
    }

    func test_it_inits_with_expected_order_items() {
        // Given
        let order = Order.fake().copy(items: [OrderItem.fake(), OrderItem.fake()])

        // When
        let dataSource = DefaultWooShippingItemsDataSource(order: order)

        // Then
        assertEqual(2, dataSource.orderItems.count)
    }

    func test_it_inits_with_expected_stored_products_and_variations() {
        // Given
        let product = Product.fake().copy(productID: 11)
        let variation = ProductVariation.fake().copy(productVariationID: 12)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
        let order = Order.fake().copy(items: [OrderItem.fake().copy(productID: product.productID),
                                              OrderItem.fake().copy(variationID: variation.productVariationID)])

        // When
        let dataSource = DefaultWooShippingItemsDataSource(order: order, storageManager: storageManager)

        // Then
        assertEqual(1, dataSource.products.count)
        assertEqual(1, dataSource.productVariations.count)
    }

    func test_it_inits_with_expected_products_and_variations_from_remote() {
        // Given
        let product = Product.fake().copy(productID: 13)
        let variation = ProductVariation.fake().copy(productVariationID: 14)
        let order = Order.fake().copy(items: [OrderItem.fake().copy(productID: product.productID),
                                              OrderItem.fake().copy(variationID: variation.productVariationID)])
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .requestMissingProducts:
                self.storageManager.insertSampleProduct(readOnlyProduct: product)
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .requestMissingVariations:
                self.storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }


        // When
        let dataSource = DefaultWooShippingItemsDataSource(order: order, storageManager: storageManager, stores: stores)

        // Then
        assertEqual(1, dataSource.products.count)
        assertEqual(1, dataSource.productVariations.count)
    }

}

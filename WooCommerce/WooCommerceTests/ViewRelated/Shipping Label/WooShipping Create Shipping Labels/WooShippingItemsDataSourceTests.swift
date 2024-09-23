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

    func test_it_inits_with_expected_items_from_storage() {
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
        assertEqual(2, dataSource.items.count)
    }

    func test_it_inits_with_expected_items_from_remote() {
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
        assertEqual(2, dataSource.items.count)
    }

}

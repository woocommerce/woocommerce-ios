import XCTest
import Foundation
@testable import WooCommerce
@testable import Storage
@testable import Yosemite

final class TopProductsFromCachedOrdersProviderTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var storageManager: MockStorageManager!
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()

        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_no_orders_return_empty() {
        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: sampleSiteID)

        XCTAssertEqual(topProducts, ProductSelectorTopProducts.empty)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_orders_return_popular_products_sorted() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        preparePopularProductsSamples(with: expectedProductIDs)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: sampleSiteID)

        XCTAssertEqual(topProducts.popularProductsIds, expectedProductIDs)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_orders_but_not_completed_returns_popular_products_empty() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        preparePopularProductsSamples(with: expectedProductIDs, orderStatus: .pending)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: sampleSiteID)

        XCTAssertEqual(topProducts, ProductSelectorTopProducts.empty)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_popular_products_but_site_id_is_different_returns_empty() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        preparePopularProductsSamples(with: expectedProductIDs)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: 956)

        XCTAssertEqual(topProducts, ProductSelectorTopProducts.empty)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_orders_return_last_sold_sorted() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        prepareRecentlySoldProductSamples(with: expectedProductIDs)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: sampleSiteID)

        XCTAssertEqual(topProducts.lastSoldProductsIds, expectedProductIDs)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_orders_but_not_completed_returns_last_sold_empty() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        prepareRecentlySoldProductSamples(with: expectedProductIDs, orderStatus: .pending)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: sampleSiteID)

        XCTAssertEqual(topProducts, ProductSelectorTopProducts.empty)
    }

    func test_provideTopProductsFromCachedOrders_when_there_are_last_sold_products_but_site_id_is_different_returns_empty() {
        let expectedProductIDs: [Int64] = [1, 2, 3]
        prepareRecentlySoldProductSamples(with: expectedProductIDs)

        let provider = TopProductsFromCachedOrdersProvider(storageManager: storageManager)

        let topProducts = provider.provideTopProducts(siteID: 956)

        XCTAssertEqual(topProducts, ProductSelectorTopProducts.empty)
    }
}

extension TopProductsFromCachedOrdersProviderTests {
    func preparePopularProductsSamples(with productIDs: [Int64], orderStatus: OrderStatusEnum = .completed) {
        productIDs.forEach { storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(productID: $0))}

        let orderItems = productIDs.map { OrderItem.fake().copy(productID: $0) }
        let orders = (0 ..< 3).map { _ in Order.fake().copy(siteID: sampleSiteID, status: orderStatus) }

        storageManager.insertSampleOrder(readOnlyOrder: orders[0]).items = NSOrderedSet(array: (0 ..< 1)
            .map { index in storageManager.insertSampleOrderItem(readOnlyOrderItem: orderItems[index]) })
        storageManager.insertSampleOrder(readOnlyOrder: orders[1]).items = NSOrderedSet(array: (0 ..< 2)
            .map { index in storageManager.insertSampleOrderItem(readOnlyOrderItem: orderItems[index]) })
        storageManager.insertSampleOrder(readOnlyOrder: orders[2]).items = NSOrderedSet(array: (0 ..< 3)
            .map { index in storageManager.insertSampleOrderItem(readOnlyOrderItem: orderItems[index]) })
    }

    func prepareRecentlySoldProductSamples(with productIDs: [Int64], orderStatus: OrderStatusEnum = .completed) {
        productIDs.forEach { storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(productID: $0))}

        let orderItems = productIDs.map { OrderItem.fake().copy(productID: $0) }
        let orders = (0 ..< 3).map { index in Order.fake().copy(siteID: sampleSiteID, status: orderStatus, datePaid: Date().addingDays(-index)) }

        for (index, _) in orders.enumerated() {
          storageManager.insertSampleOrder(readOnlyOrder: orders[index]).items = [storageManager.insertSampleOrderItem(readOnlyOrderItem: orderItems[index])]
        }
    }
}

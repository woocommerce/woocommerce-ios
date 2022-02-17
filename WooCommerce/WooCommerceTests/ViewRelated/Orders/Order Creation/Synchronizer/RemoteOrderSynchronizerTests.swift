import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class RemoteOrderSynchronizerTests: XCTestCase {

    let sampleSiteID: Int64 = 123
    let sampleProductID: Int64 = 234
    let sampleInputID: Int64 = 345

    func test_sending_status_input_updates_local_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        synchronizer.setStatus.send(.completed)

        // Then
        XCTAssertEqual(synchronizer.order.status, .completed)
    }

    func test_sending_new_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        synchronizer.setProduct.send(input)

        // Then
        let item = try XCTUnwrap(synchronizer.order.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, input.quantity)
    }

    func test_sending_update_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1)
        let input2 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 2)
        synchronizer.setProduct.send(input)
        synchronizer.setProduct.send(input2)

        // Then
        let item = try XCTUnwrap(synchronizer.order.items.first)
        XCTAssertEqual(item.itemID, input2.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, input2.quantity)
    }

    func test_sending_delete_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1)
        let input2 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 0)
        synchronizer.setProduct.send(input)
        synchronizer.setProduct.send(input2)

        // Then
        XCTAssertEqual(synchronizer.order.items.count, 0)
    }

    func test_sending_addresses_input_updates_local_order() throws {
        // Given
        let address = Address.fake().copy(firstName: "Woo", lastName: "Customer")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let input = OrderSyncAddressesInput(billing: address, shipping: address)
        synchronizer.setAddresses.send(input)

        // Then
        XCTAssertEqual(synchronizer.order.billingAddress, address)
        XCTAssertEqual(synchronizer.order.shippingAddress, address)
    }

    func test_sending_nil_addresses_input_updates_local_order() throws {
        // Given
        let address = Address.fake().copy(firstName: "Woo", lastName: "Customer")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let input = OrderSyncAddressesInput(billing: address, shipping: address)
        synchronizer.setAddresses.send(input)
        synchronizer.setAddresses.send(nil)


        // Then
        XCTAssertNil(synchronizer.order.billingAddress)
        XCTAssertNil(synchronizer.order.shippingAddress)
    }
}

import XCTest
import TestKit
import Fakes
import Combine

@testable import WooCommerce
@testable import Yosemite

class RemoteOrderSynchronizerTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private let sampleProductID: Int64 = 234
    private let sampleInputID: Int64 = 345
    private let sampleShippingID: Int64 = 456
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        subscriptions.removeAll()
    }

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

    func test_sending_shipping_input_updates_local_order() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: sampleShippingID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        synchronizer.setShipping.send(shippingLine)

        // Then
        XCTAssertEqual(synchronizer.order.shippingLines, [shippingLine])
    }

    func test_sending_nil_shipping_input_updates_local_order() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: sampleShippingID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        synchronizer.setShipping.send(shippingLine)
        synchronizer.setShipping.send(nil)

        // Then
        XCTAssertEqual(synchronizer.order.shippingLines, [])
    }

    func test_sending_product_input_triggers_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let orderCreationInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            let input = OrderSyncProductInput(product: .product(product), quantity: 1)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_sending_addresses_input_triggers_order_creation() {
        // Given
        let address = Address.fake().copy(firstName: "Woo", lastName: "Customer")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let orderCreationInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            let input = OrderSyncAddressesInput(billing: address, shipping: address)
            synchronizer.setAddresses.send(input)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_sending_shipping_input_triggers_order_creation() {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: sampleShippingID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let orderCreationInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            synchronizer.setShipping.send(shippingLine)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_sending_fee_input_triggers_order_creation() {
        // Given
        let fee = OrderFeeLine.fake().copy()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let orderCreationInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            synchronizer.setFee.send(fee)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_states_are_properly_set_upon_success_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, let completion):
                completion(.success(.fake()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        synchronizer.setProduct.send(input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)
        }

        // Then
        XCTAssertEqual(states, [.syncing, .synced])
    }

    func test_states_are_properly_set_upon_failing_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, let completion):
                completion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let input = OrderSyncProductInput(product: .product(product), quantity: 1)
        synchronizer.setProduct.send(input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)
        }

        // Then
        assertEqual(states, [.syncing, .error(error)])
    }

    func test_sending_double_input_triggers_only_one_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)

        // When
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder:
                exp.fulfill()
            default:
                break
            }
        }

        let input1 = OrderSyncProductInput(product: .product(product), quantity: 1)
        synchronizer.setProduct.send(input1)

        let input2 = OrderSyncProductInput(product: .product(product), quantity: 2)
        synchronizer.setProduct.send(input2)

        // Then
        wait(for: [exp], timeout: 1.0)
    }

    func test_order_is_created_with_draft_status_and_returned_with_selected_status() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in // Set version that supports auto-draft
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(.fake().copy(version: "6.3.0"))
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, stores: stores)
        XCTAssertEqual(synchronizer.order.status, .pending) // initial status

        // When
        let submittedStatus: OrderStatusEnum = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, order, onCompletion):
                    onCompletion(.success(order))
                    promise(order.status)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            synchronizer.setFee.send(.fake())
        }

        // Then
        XCTAssertEqual(submittedStatus, .autoDraft) // Submitted Status
        XCTAssertEqual(synchronizer.order.status, .pending) // Selected status
    }
}

extension OrderSyncState: Equatable {
    public static func == (lhs: OrderSyncState, rhs: OrderSyncState) -> Bool {
        switch (lhs, rhs) {
        case (.syncing, .syncing), (.synced, .synced):
            return true
        case (.error(let error1), .error(let error2)):
            return error1 as NSError == error2 as NSError
        default:
            return false
        }
    }
}

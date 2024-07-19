import XCTest
import TestKit
import Fakes
import Combine
import WordPressAuthenticator

@testable import WooCommerce
@testable import Yosemite
import SwiftUI

final class RemoteOrderSynchronizerTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private let sampleProductID: Int64 = 234
    private let sampleInputID: Int64 = 345
    private let anotherSampleInputID: Int64 = 312
    private let sampleShippingID: Int64 = 456
    private let sampleOrderID: Int64 = 567
    private let sampleFeeID: Int64 = 678
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initializeAuthenticator()
        subscriptions.removeAll()
    }

    override func tearDown() {
        // There is no known tear down for the Authenticator. So this method intentionally does
        // nothing.
        super.tearDown()
    }

    func test_sending_status_input_updates_local_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.setStatus.send(.completed)

        // Then
        XCTAssertEqual(synchronizer.order.status, .completed)
    }

    func test_sending_new_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        synchronizer.setProduct.send(input)

        // Then
        let item = try XCTUnwrap(synchronizer.order.items.first)
        XCTAssertEqual(item.itemID, input.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, input.quantity)
    }

    func test_setProducts_sends_single_product_input_then_updates_order_successfully() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let productInput = OrderSyncProductInput(
            id: sampleInputID,
            product: .product(product),
            quantity: 1,
            discount: 0)

        // Confidence check
        XCTAssertEqual(synchronizer.order.items.count, 0)

        // When
        let inputs: [OrderSyncProductInput] = [productInput]
        synchronizer.setProducts.send(inputs)

        // Then
        XCTAssertEqual(synchronizer.order.items.count, 1)

        let item = try XCTUnwrap(synchronizer.order.items.first)
        XCTAssertEqual(item.itemID, productInput.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, productInput.quantity)
    }

    func test_setProducts_sends_multiple_product_input_then_updates_order_successfully() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let product = Product.fake().copy(productID: sampleProductID)
        let anotherProduct = Product.fake().copy(productID: 12345)
        let productInput = OrderSyncProductInput(
            id: sampleInputID,
            product: .product(product),
            quantity: 1,
            discount: 0)
        let anotherProductInput = OrderSyncProductInput(
            id: anotherSampleInputID,
            product: .product(anotherProduct),
            quantity: 1,
            discount: 0)

        // Confidence check
        XCTAssertEqual(synchronizer.order.items.count, 0)

        // When
        let inputs: [OrderSyncProductInput] = [productInput, anotherProductInput]
        synchronizer.setProducts.send(inputs)

        // Then
        XCTAssertEqual(synchronizer.order.items.count, 2)
        let item = try XCTUnwrap(synchronizer.order.items[0])
        let anotherItem = try XCTUnwrap(synchronizer.order.items[1])

        XCTAssertEqual(item.itemID, productInput.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, productInput.quantity)

        XCTAssertEqual(anotherItem.itemID, anotherProductInput.id)
        XCTAssertEqual(anotherItem.productID, anotherProduct.productID)
        XCTAssertEqual(anotherItem.quantity, anotherProductInput.quantity)
    }

    func test_sending_update_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let initialInput = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        synchronizer.setProduct.send(initialInput)

        // When
        let updatedInput = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 2, discount: 0)
        synchronizer.setProduct.send(updatedInput)

        // Then
        let item = try XCTUnwrap(synchronizer.order.items.first)
        XCTAssertEqual(item.itemID, updatedInput.id)
        XCTAssertEqual(item.productID, product.productID)
        XCTAssertEqual(item.quantity, updatedInput.quantity)
    }

    func test_sending_delete_product_input_updates_local_order() throws {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let initialInput = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        synchronizer.setProduct.send(initialInput)

        // When
        let updatedInput = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 0, discount: 0)
        synchronizer.setProduct.send(updatedInput)

        // Then
        XCTAssertEqual(synchronizer.order.items.count, 1)
        XCTAssertEqual(synchronizer.order.items[0].quantity, .zero)
    }

    func test_sending_addresses_input_updates_local_order() throws {
        // Given
        let address = Address.fake().copy(firstName: "Woo", lastName: "Customer")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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
        let shippingLine = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: "free_shipping")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.setShipping.send(shippingLine)

        // Then
        XCTAssertEqual(synchronizer.order.shippingLines, [shippingLine])
    }

    func test_removing_shipping_input_updates_local_order() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: sampleShippingID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.setShipping.send(shippingLine)
        synchronizer.removeShipping.send(shippingLine)

        // Then
        let firstLine = try XCTUnwrap(synchronizer.order.shippingLines.first)
        XCTAssertNil(firstLine.methodID)
    }

    func test_sending_product_input_triggers_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_sending_new_product_input_sends_order_without_totals() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "20.0")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let submittedItems: [OrderItem] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, let order, _, _):
                    promise(order.items)
                default:
                    XCTFail("Unexpected Action received: \(action)")
                }
            }

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(submittedItems.isNotEmpty)
        for item in submittedItems {
            XCTAssertTrue(item.total.isEmpty)
            XCTAssertTrue(item.subtotal.isEmpty)
        }
    }

    func test_sending_new_product_input_sends_order_with_zero_ids() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "20.0")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let submittedItems: [OrderItem] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, let order, _, _):
                    promise(order.items)
                default:
                    XCTFail("Unexpected Action received: \(action)")
                }
            }

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(submittedItems.isNotEmpty)
        for item in submittedItems {
            XCTAssertEqual(item.itemID, .zero)
        }
    }

    func test_sending_existing_product_input_sends_order_with_totals() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID, price: "20.0")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let submittedItems: [OrderItem] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, let order, _, let completion):
                    completion(.success(order.copy(orderID: self.sampleOrderID)))
                case .updateOrder(_, let order, _, _, _):
                    promise(order.items)
                default:
                    XCTFail("Unexpected Action received: \(action)")
                }
            }

            let initialInput = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 1, discount: 0)
            self.createOrder(on: synchronizer, input: initialInput)

            let input = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(submittedItems.isNotEmpty)
        for item in submittedItems {
            XCTAssertTrue(item.total.isNotEmpty)
            XCTAssertTrue(item.subtotal.isNotEmpty)
        }
    }

    func test_sending_addresses_input_triggers_order_creation() {
        // Given
        let address = Address.fake().copy(firstName: "Woo", lastName: "Customer")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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

    func test_adding_fee_input_triggers_order_creation() {
        // Given
        let fee = OrderFeeLine.fake().copy()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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

            synchronizer.addFee.send(fee)
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_adding_fee_input_triggers_order_sync_in_edit_flow() {
        // Given
        let fee = OrderFeeLine.fake().copy()
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let orderUpdateInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    XCTFail("Creation shouldn't happen in edit flow")
                case .updateOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            synchronizer.addFee.send(fee)
        }

        // Then
        XCTAssertTrue(orderUpdateInvoked)
    }

    func test_adding_fee_input_updates_local_order() throws {
        // Given
        let feeLine = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: "test-fee")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.addFee.send(feeLine)

        // Then
        let firstLine = try XCTUnwrap(synchronizer.order.fees.first)
        XCTAssertEqual(firstLine.name, feeLine.name)
    }

    func test_removing_fee_input_updates_local_order() throws {
        // Given
        let feeLine = OrderFeeLine.fake().copy(feeID: sampleFeeID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.addFee.send(feeLine)
        synchronizer.removeFee.send(feeLine)

        // Then
        XCTAssertTrue(synchronizer.order.fees.first?.isDeleted ?? true)
    }

    func test_sending_coupon_input_triggers_order_creation() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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

            synchronizer.addCoupon.send("TESTCOUPON")
        }

        // Then
        XCTAssertTrue(orderCreationInvoked)
    }

    func test_sending_coupon_input_triggers_order_sync_in_edit_flow() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let orderUpdateInvoked: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    XCTFail("Creation shouldn't happen in edit flow")
                case .updateOrder:
                    promise(true)
                default:
                    promise(false)
                }
            }

            synchronizer.addCoupon.send("TESTCOUPON")
        }

        // Then
        XCTAssertTrue(orderUpdateInvoked)
    }

    func test_removing_coupon_input_updates_local_order() throws {
        // Given
        let couponCode = "code"
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        synchronizer.addCoupon.send(couponCode)
        synchronizer.removeCoupon.send(couponCode)

        // Then
        XCTAssertNil(synchronizer.order.coupons.first)
    }

    func test_sending_customer_note_input_updates_local_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let expectedNotes = "Test customer note"

        // When
        synchronizer.setNote.send(expectedNotes)

        // Then
        XCTAssertEqual(synchronizer.order.customerNote, expectedNotes)
    }

    func test_creating_customer_note_input_updates_local_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let randomNote = "Unexpected customer note"
        let expectedNote = "Second customer note"
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID, customerNote: randomNote)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        synchronizer.setNote.send(expectedNote)
        let resultOrder = try waitFor { promise in
            synchronizer.commitAllChanges { result, _ in
                promise(result)
            }
        }.get()

        // Then
        XCTAssertEqual(resultOrder.customerNote, expectedNote)
    }

    func test_updating_customer_note_input_updates_local_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let product = Product.fake().copy(productID: sampleProductID)
        let firstNote = "First customer note"
        let expectedNote = "Second customer note"
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, let order, _, _, let completion):
                completion(.success(order.copy(customerNote: firstNote)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        synchronizer.setNote.send(firstNote)
        let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
        synchronizer.setProduct.send(input2)
        synchronizer.setNote.send(expectedNote)

        let resultOrder = try waitFor { promise in
            synchronizer.commitAllChanges { result, _ in
                promise(result)
            }
        }.get()

        // Then
        XCTAssertEqual(resultOrder.customerNote, expectedNote)
    }

    func test_sending_customer_note_input_triggers_sync_in_edit_flow() throws {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)
        let expectedNote = "Test customer note"

        // When
        let update: (order: Order, fields: [OrderUpdateField]) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder(_, let order, _, let fields, let completion):
                    completion(.success(order))
                    promise((order, fields))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            synchronizer.setNote.send(expectedNote)
        }

        // Then
        XCTAssertEqual(update.order.customerNote, expectedNote)
        XCTAssertEqual(update.fields, OrderUpdateField.allCases)
    }

    func test_sending_customer_id_input_does_not_trigger_sync_in_creation_flow() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        synchronizer.setCustomerID.send(16)
    }

    func test_sending_customer_id_input_does_not_trigger_sync_in_edit_flow() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        synchronizer.setCustomerID.send(16)
    }

    func test_sending_customer_id_then_addresses_input_triggers_sync_in_creation_flow() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let orderToCreate = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                    case let .createOrder(_, order, _, completion):
                        completion(.success(order))
                        promise(order)
                    default:
                        XCTFail("Unexpected action: \(action)")
                }
            }
            synchronizer.setCustomerID.send(16)
            synchronizer.setAddresses.send(.init(billing: .fake(), shipping: .fake()))
        }

        // Then
        XCTAssertEqual(orderToCreate.customerID, 16)
    }

    func test_sending_customer_id_then_addresses_input_triggers_sync_in_edit_flow() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let update: (order: Order, fields: [OrderUpdateField]) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, _, fields, completion):
                    completion(.success(order))
                    promise((order, fields))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            synchronizer.setCustomerID.send(16)
            synchronizer.setAddresses.send(.init(billing: .fake(), shipping: .fake()))
        }

        // Then
        XCTAssertEqual(update.order.customerID, 16)
        XCTAssertTrue(update.fields.contains(.customerID))
    }

    func test_removing_customer_id_sets_customer_id_to_0() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID, customerID: 16)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        synchronizer.removeCustomerID.send(())

        // Then
        XCTAssertEqual(synchronizer.order.customerID, 0)
    }

    func test_removing_customer_id_does_not_trigger_sync_in_creation_flow() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        synchronizer.removeCustomerID.send(())
    }

    func test_removing_customer_id_does_not_trigger_sync_in_edit_flow() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        synchronizer.removeCustomerID.send(())
    }

    func test_states_are_properly_set_upon_success_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: true), .synced])
    }

    func test_states_are_properly_set_upon_success_order_update_with_new_items() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, let order, _, _, let completion):
                completion(.success(order))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // Wait for order creation
        let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            // Trigger order update
            let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: true), .synced])
    }

    func test_state_is_set_to_syncing_and_blocking_upon_order_update_with_new_item_that_includes_bundle_configuration() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(1)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            // Trigger order update
            let input = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 1, discount: 0, bundleConfiguration: [
                .init(bundledItemID: 0, productOrVariation: .product(id: 1), quantity: 2, isOptionalAndSelected: nil)
            ])
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: true)])
    }

    func test_states_are_properly_set_upon_success_order_update_with_no_new_items() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, let order, _, _, let completion):
                completion(.success(order))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // Wait for order creation
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            // Trigger order update
            let input2 = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: false), .synced])
    }

    func test_states_are_properly_set_upon_success_order_update_with_no_new_items_in_allUpdates_block_behavior() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        synchronizer.updateBlockingBehavior(.allUpdates)

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, let order, _, _, let completion):
                completion(.success(order))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // Wait for order creation
        let input = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            // Trigger order update
            let input2 = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: true), .synced])
    }

    func test_order_creation_can_resume_after_receiving_errors() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let receivedError: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, _, _, let completion):
                    completion(.failure(error))
                    promise(true)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }
        XCTAssertTrue(receivedError)

        let receivedCreationRequest: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertTrue(receivedCreationRequest)
    }

    func test_states_are_properly_set_upon_failing_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        assertEqual(states, [.syncing(blocking: true), .error(error, usesGiftCard: false)])
    }

    func test_states_are_properly_set_upon_failing_order_update() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                completion(.success(.fake().copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, _, _, _, let completion):
                completion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // Wait for order creation
        let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        let states: [OrderSyncState] = waitFor { promise in
            synchronizer.statePublisher
                .dropFirst()
                .collect(2)
                .sink { states in
                    promise(states)
                }
                .store(in: &self.subscriptions)

            // Trigger order update
            let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }

        // Then
        XCTAssertEqual(states, [.syncing(blocking: true), .error(error, usesGiftCard: false)])
    }

    func test_sending_double_input_triggers_only_one_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

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

        let input1 = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
        synchronizer.setProduct.send(input1)

        let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
        synchronizer.setProduct.send(input2)

        // Then
        wait(for: [exp], timeout: 1.0)
    }

    func test_sending_input_while_order_is_being_created_ignores_order_update() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        waitForExpectation { exp in
            exp.isInverted = true
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, _, _, let completion):
                    // Send update request before order is created
                    let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
                    synchronizer.setProduct.send(input2)

                    // Complete order creation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(.success(.fake().copy(orderID: self.sampleOrderID)))
                    }
                case .updateOrder:
                    exp.fulfill() // Update should not happen

                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            // Send creation request
            let input1 = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input1)
        }
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
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        XCTAssertEqual(synchronizer.order.status, .pending) // initial status

        // When
        let submittedStatus: OrderStatusEnum = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, order, _, onCompletion):
                    onCompletion(.success(order))
                    promise(order.status)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            synchronizer.addFee.send(.fake())
        }

        // Then
        XCTAssertEqual(submittedStatus, .autoDraft) // Submitted Status
        XCTAssertEqual(synchronizer.order.status, .pending) // Selected status
    }

    func test_order_is_synced_with_selected_status_in_editing_flow() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let submittedStatus: OrderStatusEnum = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder(_, let order, _, _, let completion):
                    completion(.success(order))
                    promise(order.status)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            synchronizer.setStatus.send(.onHold)
        }

        // Then
        XCTAssertEqual(submittedStatus, .onHold) // Submitted Status
        XCTAssertEqual(synchronizer.order.status, .onHold) // Selected status
    }

    func test_order_update_is_sent_with_correct_order_fields() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let updateFields: [OrderUpdateField] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, _, _, let completion):
                    completion(.success(.fake().copy(orderID: self.sampleOrderID)))
                case .updateOrder(_, _, _, let fields, _):
                    promise(fields)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            // Wait for order creation
            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            self.createOrder(on: synchronizer, input: input)

            // Send order update
            let input2 = OrderSyncProductInput(product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }

        // Then
        XCTAssertEqual(updateFields, [.shippingAddress,
                                      .billingAddress,
                                      .fees,
                                      .shippingLines,
                                      .couponLines,
                                      .items])
    }

    func test_order_update_in_edit_flow_is_sent_with_all_order_fields() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let order = Order.fake().copy(orderID: sampleOrderID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let updateFields: [OrderUpdateField] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder(_, _, _, let fields, _):
                    promise(fields)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            // Send order update
            let input = OrderSyncProductInput(product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }

        // Then
        XCTAssertEqual(updateFields, OrderUpdateField.allCases)
    }

    func test_sending_retry_trigger_after_failed_order_creation_retries_expected_order_creation() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let orderCreationFailed: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, _, _, let completion):
                    completion(.failure(error))
                    promise(true)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            let input = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 1, discount: 0)
            synchronizer.setProduct.send(input)
        }
        XCTAssertTrue(orderCreationFailed)

        let createdOrderItems: [OrderItem] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, let order, _, _):
                    promise(order.items)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            synchronizer.retryTrigger.send()
        }

        // Then
        XCTAssertEqual(createdOrderItems.count, 1)
        XCTAssertEqual(createdOrderItems.first?.productID, product.productID)
        XCTAssertEqual(createdOrderItems.first?.quantity, 1)
    }

    func test_sending_retry_trigger_with_remote_order_triggers_order_update() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let orderUpdateFailed: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, _, _, let completion):
                    completion(.success(.fake().copy(orderID: self.sampleOrderID)))
                case .updateOrder(_, _, _, _, let completion):
                    completion(.failure(error))
                    promise(true)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            // Wait for order creation
            let input = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 1, discount: 0)
            self.createOrder(on: synchronizer, input: input)

            // Trigger order update
            let input2 = OrderSyncProductInput(id: self.sampleInputID, product: .product(product), quantity: 2, discount: 0)
            synchronizer.setProduct.send(input2)
        }
        XCTAssertTrue(orderUpdateFailed)

        let updatedOrderItems: [OrderItem] = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder(_, let order, _, _, _):
                    promise(order.items)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            synchronizer.retryTrigger.send()
        }

        // Then
        XCTAssertEqual(updatedOrderItems.count, 1)
        XCTAssertEqual(updatedOrderItems.first?.productID, product.productID)
        XCTAssertEqual(updatedOrderItems.first?.quantity, 2)
    }

    func test_commit_changes_creates_order_if_order_has_not_been_created() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, let order, _, let completion):
                completion(.success(order))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let result: Result<Order, Error> = waitFor { promise in
            synchronizer.commitAllChanges { result, _ in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_commit_changes_relays_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, _, _, let completion):
                let error = NSError(domain: "", code: 0, userInfo: nil)
                completion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let result: Result<Order, Error> = waitFor { promise in
            synchronizer.commitAllChanges { result, _ in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_commit_changes_updates_order_if_order_has_been_created() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, let order, _, let completion):
                completion(.success(order.copy(orderID: self.sampleOrderID)))
            case .updateOrder(_, let order, _, _, let completion):
                completion(.success(order))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let input = OrderSyncProductInput.init(product: .product(Product.fake()), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input)

        // When
        let result: Result<Order, Error> = waitFor { promise in
            synchronizer.commitAllChanges { result, _ in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_commitAllChanges_relays_usesGiftCard_on_success() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
                case .createOrder(_, _, _, let completion):
                    completion(.success(.fake()))
                default:
                    XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        synchronizer.setGiftCard.send("AABO")
        let usesGiftCard = waitFor { promise in
            synchronizer.commitAllChanges { _, usesGiftCard in
                promise(usesGiftCard)
            }
        }

        // Then
        XCTAssertTrue(usesGiftCard)
    }

    func test_commitAllChanges_relays_usesGiftCard_on_failure() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
                case .createOrder(_, _, _, let completion):
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    completion(.failure(error))
                default:
                    XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        synchronizer.setGiftCard.send("AABO")
        let usesGiftCard = waitFor { promise in
            synchronizer.commitAllChanges { _, usesGiftCard in
                promise(usesGiftCard)
            }
        }

        // Then
        XCTAssertTrue(usesGiftCard)
    }

    func test_double_inputs_are_debounced_during_order_update() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)

        // When
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .createOrder(_, let order, _, let completion):
                completion(.success(order.copy(orderID: self.sampleOrderID)))
            case .updateOrder:
                exp.fulfill()
            default:
                break
            }
        }

        // Wait for order creation
        let input1 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 1, discount: 0)
        createOrder(on: synchronizer, input: input1)

        // Trigger product quantity updates
        let input2 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 2, discount: 0)
        let input3 = OrderSyncProductInput(id: sampleInputID, product: .product(product), quantity: 3, discount: 0)
        synchronizer.setProduct.send(input2)
        synchronizer.setProduct.send(input3)

        // Then
        wait(for: [exp], timeout: 1.0)
    }
}

private extension RemoteOrderSynchronizerTests {
    /// Waits for an order to be created.
    ///
    func createOrder(on synchronizer: OrderSynchronizer, input: OrderSyncProductInput) {
        synchronizer.setProduct.send(input)
        waitUntil {
            synchronizer.order.orderID != .zero
        }
    }
}

extension OrderSyncState: Equatable {
    public static func == (lhs: OrderSyncState, rhs: OrderSyncState) -> Bool {
        switch (lhs, rhs) {
        case (.syncing(let lhsBlocking), .syncing(let rhsBlocking)):
            return lhsBlocking == rhsBlocking
        case (.synced, .synced):
            return true
        case (.error(let error1, let usesGiftCard1), .error(let error2, let usesGiftCard2)):
            return error1 as NSError == error2 as NSError && usesGiftCard1 == usesGiftCard2
        default:
            return false
        }
    }
}

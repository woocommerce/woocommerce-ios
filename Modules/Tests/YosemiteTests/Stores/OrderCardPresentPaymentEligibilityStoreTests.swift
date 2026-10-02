import Foundation
import TestKit
import XCTest

import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
@testable import WooFoundation

final class OrderCardPresentPaymentEligibilityStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Subscriptions Remote
    ///
    private var subscriptionsRemote: MockSubscriptionsRemote!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Store
    ///
    private var store: OrderCardPresentPaymentEligibilityStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        subscriptionsRemote = MockSubscriptionsRemote()
        store = OrderCardPresentPaymentEligibilityStore(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: network,
            subscriptionsRemote: subscriptionsRemote
        )
    }

    // Other behavioural tests are in Order_CardPresentPaymentTests
    func test_orderIsEligibleForCardPresentPayment_returns_true_for_eligible_order() throws {
        // Given
        let orderItem = OrderItem.fake().copy(itemID: 1234,
                                              name: "Chocolate cake",
                                              productID: 678,
                                              quantity: 1.0)
        let cppEligibleOrder = Order.fake().copy(siteID: sampleSiteID,
                                                 orderID: 111,
                                                 status: .pending,
                                                 currency: "USD",
                                                 datePaid: nil,
                                                 total: "5.00",
                                                 paymentMethodID: "woocommerce_payments",
                                                 items: [orderItem])
        let nonSubscriptionProduct = Product.fake().copy(siteID: sampleSiteID,
                                                         productID: 678,
                                                         name: "Chocolate cake",
                                                         productTypeKey: "simple")

        storageManager.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storageManager.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration(country: .US)

        // When
        let result = waitFor { promise in
            let action = OrderCardPresentPaymentEligibilityAction
                .checkEligibility(orderID: 111,
                                                      siteID: self.sampleSiteID,
                                                      cardPresentPaymentsConfiguration: configuration) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let eligibility = try XCTUnwrap(result.get())
        XCTAssertEqual(eligibility, .eligible)
    }

    // MARK: - checkOrderContainsSubscription

    func test_checkOrderContainsSubscription_when_order_is_not_in_storage_then_fails() {
        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(subscriptionsRemote.spyLoadSubscriptionsOrderIDs.isEmpty)
    }

    func test_checkOrderContainsSubscription_when_woo_subscriptions_is_not_active_then_returns_false_without_fetching() throws {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: false)

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertFalse(try result.get())
        XCTAssertTrue(subscriptionsRemote.spyLoadSubscriptionsOrderIDs.isEmpty)
    }

    func test_checkOrderContainsSubscription_when_order_has_no_products_then_returns_false_without_fetching() throws {
        // Given
        insertOrder(orderID: 111, productID: 0)
        insertWooSubscriptionsPlugin(active: true)

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertFalse(try result.get())
        XCTAssertTrue(subscriptionsRemote.spyLoadSubscriptionsOrderIDs.isEmpty)
    }

    func test_checkOrderContainsSubscription_when_order_has_legacy_subscription_product_then_returns_true_without_fetching() throws {
        insertWooSubscriptionsPlugin(active: true)
        for (id, productTypeKey) in [(Int64(1), "subscription"), (Int64(2), "variable-subscription")] {
            // Given
            insertOrder(orderID: id, productID: id)
            storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: sampleSiteID, productID: id, productTypeKey: productTypeKey))

            // When
            let result = checkOrderContainsSubscription(orderID: id)

            // Then
            XCTAssertTrue(try result.get())
            XCTAssertTrue(subscriptionsRemote.spyLoadSubscriptionsOrderIDs.isEmpty)
        }
    }

    func test_checkOrderContainsSubscription_when_order_is_parent_of_a_subscription_then_returns_true() throws {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: true)
        subscriptionsRemote.loadSubscriptionsResult = .success([Subscription.fake()])

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertTrue(try result.get())
        XCTAssertEqual(subscriptionsRemote.spyLoadSubscriptionsOrderIDs, [111])
    }

    func test_checkOrderContainsSubscription_when_order_is_not_parent_of_a_subscription_then_returns_false() throws {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: true)
        subscriptionsRemote.loadSubscriptionsResult = .success([])

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertFalse(try result.get())
    }

    func test_checkOrderContainsSubscription_when_order_is_a_renewal_then_checks_subscriptions_by_parent() throws {
        // Given
        insertOrder(orderID: 111, productID: 678, renewalSubscriptionID: "282")
        insertWooSubscriptionsPlugin(active: true)

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertFalse(try result.get())
        XCTAssertEqual(subscriptionsRemote.spyLoadSubscriptionsOrderIDs, [111])
        XCTAssertFalse(subscriptionsRemote.loadSubscriptionCalled)
    }

    func test_checkOrderContainsSubscription_when_fetching_fails_then_fails() {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: true)
        subscriptionsRemote.loadSubscriptionsResult = .failure(NetworkError.unacceptableStatusCode(statusCode: 500))

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_checkOrderContainsSubscription_when_checked_again_after_success_then_uses_cached_result() throws {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: true)
        subscriptionsRemote.loadSubscriptionsResult = .success([Subscription.fake()])
        _ = checkOrderContainsSubscription(orderID: 111)
        subscriptionsRemote.loadSubscriptionsResult = .success([])

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertTrue(try result.get())
        XCTAssertEqual(subscriptionsRemote.spyLoadSubscriptionsOrderIDs, [111])
    }

    func test_checkOrderContainsSubscription_when_checked_again_after_failure_then_fetches_again() throws {
        // Given
        insertOrder(orderID: 111, productID: 678)
        insertWooSubscriptionsPlugin(active: true)
        subscriptionsRemote.loadSubscriptionsResult = .failure(NetworkError.unacceptableStatusCode(statusCode: 500))
        _ = checkOrderContainsSubscription(orderID: 111)
        subscriptionsRemote.loadSubscriptionsResult = .success([])

        // When
        let result = checkOrderContainsSubscription(orderID: 111)

        // Then
        XCTAssertFalse(try result.get())
        XCTAssertEqual(subscriptionsRemote.spyLoadSubscriptionsOrderIDs, [111, 111])
    }
}

private extension OrderCardPresentPaymentEligibilityStoreTests {
    func insertOrder(orderID: Int64, productID: Int64, renewalSubscriptionID: String? = nil) {
        let item = OrderItem.fake().copy(itemID: orderID, productID: productID)
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: orderID, items: [item], renewalSubscriptionID: renewalSubscriptionID)
        let storageOrder = storageManager.insertSampleOrder(readOnlyOrder: order)
        storageManager.insertSampleOrderItem(readOnlyOrderItem: item).order = storageOrder
    }

    func insertWooSubscriptionsPlugin(active: Bool) {
        let plugin = SystemPlugin.fake().copy(siteID: sampleSiteID,
                                              plugin: "woocommerce-subscriptions/woocommerce-subscriptions.php",
                                              active: active)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)
    }

    func checkOrderContainsSubscription(orderID: Int64) -> Result<Bool, Error> {
        waitFor { promise in
            let action = OrderCardPresentPaymentEligibilityAction.checkOrderContainsSubscription(orderID: orderID,
                                                                                                 siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }
    }
}

import Foundation
import TestKit
import XCTest

@testable import Yosemite
@testable import Networking

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
        store = OrderCardPresentPaymentEligibilityStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
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

        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        // When
        let result = waitFor { promise in
            let action = OrderCardPresentPaymentEligibilityAction
                .orderIsEligibleForCardPresentPayment(orderID: 111,
                                                      siteID: self.sampleSiteID,
                                                      cardPresentPaymentsConfiguration: configuration) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let eligibility = try XCTUnwrap(result.get())
        XCTAssertTrue(eligibility)
    }
}

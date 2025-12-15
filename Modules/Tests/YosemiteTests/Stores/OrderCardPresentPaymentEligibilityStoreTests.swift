import Foundation
import TestKit
import XCTest

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

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    /// Store
    ///
    private var store: OrderCardPresentPaymentEligibilityStore!

    private var currentSite: Site?
    private var isCIABSupported = true

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = OrderCardPresentPaymentEligibilityStore(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: network,
            crashLogger: MockCrashLogger(),
            isCIABEnvironmentSupported: { [weak self] in
                return self?.isCIABSupported ?? false
            },
            currentSite: { [weak self] in
                return self?.currentSite
            }
        )
    }

    override func tearDown() {
        currentSite = nil
        isCIABSupported = true
        super.tearDown()
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

        let regularSite = Site.fake().copy(
            siteID: sampleSiteID,
            isGarden: false,
            gardenName: nil
        )
        self.currentSite = regularSite

        storageManager.insertSampleSite(readOnlySite: regularSite)
        storageManager.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storageManager.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration(country: .US)

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

    func test_orderIsEligibleForCardPresentPayment_returns_true_for_eligible_order_and_none_stored_site() throws {
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

        let regularSite = Site.fake().copy(
            siteID: sampleSiteID,
            isGarden: false,
            gardenName: nil
        )
        self.currentSite = regularSite

        storageManager.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storageManager.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration(country: .US)

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

    func test_orderIsEligibleForCardPresentPayment_returns_failure_for_CIAB_sites() throws {
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

        let ciabSite = Site.fake().copy(
            siteID: sampleSiteID,
            isGarden: true,
            gardenName: "commerce"
        )
        self.currentSite = ciabSite

        storageManager.insertSampleSite(readOnlySite: ciabSite)
        storageManager.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storageManager.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration(country: .US)

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
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? OrderCardPresentPaymentEligibilityStore.OrderIsEligibleForCardPresentPaymentError,
                           .cardReaderPaymentOptionIsNotSupportedForCIABSites)
        }
    }

    func test_orderIsEligibleForCardPresentPayment_returns_success_when_site_is_CIAB_and_CIAB_not_supported() throws {
        // Given

        /// Simulate that the CIAB environment support is not yet rolled out
        isCIABSupported = false

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

        let ciabSite = Site.fake().copy(
            siteID: sampleSiteID,
            isGarden: true,
            gardenName: "commerce"
        )
        self.currentSite = ciabSite

        storageManager.insertSampleSite(readOnlySite: ciabSite)
        storageManager.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storageManager.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration(country: .US)

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

    func test_orderIsEligibleForCardPresentPayment_returns_success_when_site_is_not_obtained_and_CIAB_supported() throws {
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

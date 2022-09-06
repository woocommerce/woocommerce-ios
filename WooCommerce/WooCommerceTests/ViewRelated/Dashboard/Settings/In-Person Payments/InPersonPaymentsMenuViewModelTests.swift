import XCTest
import TestKit
import Yosemite
@testable import WooCommerce

class InPersonPaymentsMenuViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var sut: InPersonPaymentsMenuViewModel!

    private let sampleStoreID: Int64 = 12345

    private var configuration: CardPresentPaymentsConfiguration!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(sampleStoreID)

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let dependencies = InPersonPaymentsMenuViewModel.Dependencies(stores: stores,
                                                                      analytics: analytics)

        configuration = CardPresentPaymentsConfiguration(country: "US")

        sut = InPersonPaymentsMenuViewModel(dependencies: dependencies,
                                            cardPresentPaymentsConfiguration: configuration)
    }

    func test_viewDidLoad_synchronizes_payment_gateways() throws {
        // Given
        assertEmpty(stores.receivedActions)

        // When
        sut.viewDidLoad()

        // Then
        let action = try XCTUnwrap(stores.receivedActions.last as? PaymentGatewayAction)
        switch action {
        case .synchronizePaymentGateways(let siteID, _):
            assertEqual(siteID, sampleStoreID)
        default:
            XCTFail("viewDidLoad failed to dispatch .synchronizePaymentGateways action")
        }
    }

    func test_orderCardReaderPressed_tracks_paymentsMenuOrderCardReaderTapped() {
        // Given

        // When
        sut.orderCardReaderPressed()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "payments_hub_order_card_reader_tapped" }))
    }

    func test_orderCardReaderPressed_presents_card_reader_purchase_web_view() throws {
        // Given
        XCTAssertNil(sut.showWebView)

        // When
        sut.orderCardReaderPressed()

        // Then
        let cardReaderViewModel = try XCTUnwrap(sut.showWebView)
        assertEqual(configuration.purchaseCardReaderUrl(), cardReaderViewModel.initialURL)
    }
}

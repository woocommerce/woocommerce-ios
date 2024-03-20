import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeAddPaymentMethodWebViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322
    private let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_addPaymentMethodURL_returns_formUrl() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID) { }

        // Then
        XCTAssertEqual(viewModel.addPaymentMethodURL, try XCTUnwrap(URL(string: "https://wordpress.com/me/purchases/add-payment-method")))
    }

    func test_addPaymentSuccessURL_returns_successUrl() async throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID) { }

        // Then
        XCTAssertEqual(viewModel.addPaymentSuccessURL, "me/purchases/payment-methods")
    }

    func test_didAddNewPaymentMethod_sets_notice() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID) { }
        XCTAssertNil(viewModel.notice)

        // When
        viewModel.didAddNewPaymentMethod()

        // Then
        XCTAssertNotNil(viewModel.notice)
    }

    // MARK: Analytics
    func test_onAppear_tracks_event() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          analytics: analytics) { }
        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_add_payment_method_web_view_displayed"))
    }

    func test_didAddNewPaymentMethod_tracks_event() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          analytics: analytics) { }
        // When
        viewModel.didAddNewPaymentMethod()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_add_payment_method_success"))
    }
}

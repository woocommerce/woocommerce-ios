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
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod) { _ in }

        // Then
        XCTAssertEqual(viewModel.addPaymentMethodURL, try XCTUnwrap(URL(string: "https://example.com/blaze-pm-add")))
    }

    func test_addPaymentSuccessURL_returns_successUrl() async throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod) { _ in }

        // Then
        XCTAssertEqual(viewModel.addPaymentSuccessURL, "https://example.com/blaze-pm-success")
    }

    func test_didAddNewPaymentMethod_sends_newly_added_payment_id_via_completion_handler() throws {
        // Given
        var selectedPaymentID = ""
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod) { id in
            selectedPaymentID = id
        }

        let successURL = try XCTUnwrap(URL(string: "\(samplePaymentInfo.addPaymentMethod.successUrl)?\(samplePaymentInfo.addPaymentMethod.idUrlParameter)=123"))
        viewModel.didAddNewPaymentMethod(successURL: successURL)

        // Then
        XCTAssertEqual(selectedPaymentID, "123")
    }

    func test_didAddNewPaymentMethod_sets_notice() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod) { _ in }
        XCTAssertNil(viewModel.notice)

        let successURL = try XCTUnwrap(URL(string: "\(samplePaymentInfo.addPaymentMethod.successUrl)?\(samplePaymentInfo.addPaymentMethod.idUrlParameter)=123"))
        viewModel.didAddNewPaymentMethod(successURL: successURL)

        // Then
        XCTAssertNotNil(viewModel.notice)
    }

    // MARK: Analytics
    func test_onAppear_tracks_event() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod,
                                                          analytics: analytics) { _ in }
        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_add_payment_method_web_view_displayed"))
    }

    func test_didAddNewPaymentMethod_tracks_event() throws {
        // Given
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: sampleSiteID,
                                                          addPaymentMethodInfo: samplePaymentInfo.addPaymentMethod,
                                                          analytics: analytics) { _ in }
        // When
        let successURL = try XCTUnwrap(URL(string: "\(samplePaymentInfo.addPaymentMethod.successUrl)?\(samplePaymentInfo.addPaymentMethod.idUrlParameter)=123"))
        viewModel.didAddNewPaymentMethod(successURL: successURL)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_add_payment_method_success"))
    }
}

import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeAddPaymentMethodWebViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322
    private let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()

    func test_addPaymentMethodURL_returns_formUrl() async throws {
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

    func test_didAddNewPaymentMethod_sends_newly_added_payment_id_via_completion_handler() async throws {
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
}

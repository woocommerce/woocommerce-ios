import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundShippingDetailsViewModel`
///
final class RefundShippingDetailsViewModelTests: XCTestCase {
    func test_viewModel_is_created_with_correct_initial_values() {
        // Given
        let shippingLine = ShippingLine(shippingID: 0, methodTitle: "USPS Flat Rate", methodID: "USPS", total: "10.20", totalTax: "1.30", taxes: [])
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundShippingDetailsViewModel(shippingLine: shippingLine, currency: "usd", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.carrierRate, "USPS Flat Rate")
        XCTAssertEqual(viewModel.carrierCost, "$10.20")
        XCTAssertEqual(viewModel.shippingTax, "$1.30")
        XCTAssertEqual(viewModel.shippingSubtotal, "$10.20")
        XCTAssertEqual(viewModel.shippingTotal, "$11.50")
    }
}

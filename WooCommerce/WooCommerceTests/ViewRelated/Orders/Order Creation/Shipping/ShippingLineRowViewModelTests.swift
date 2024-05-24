import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class ShippingLineRowViewModelTests: XCTestCase {

    func test_view_model_inits_with_expected_values() {
        // Given
        let shippingTitle = "Package 1"
        let shippingMethod = "Flat Rate"
        let shippingAmount = "$5.00"

        // When
        let viewModel = ShippingLineRowViewModel(shippingTitle: shippingTitle, shippingMethod: shippingMethod, shippingAmount: shippingAmount, editable: true)

        // Then
        assertEqual(shippingTitle, viewModel.shippingTitle)
        assertEqual(shippingMethod, viewModel.shippingMethod)
        assertEqual(shippingAmount, viewModel.shippingAmount)
        XCTAssertTrue(viewModel.editable)
    }

    func test_view_model_inits_from_shipping_line_with_expected_values() {
        // Given
        let shippingLine = ShippingLine(shippingID: 1, methodTitle: "Package 1", methodID: "flat_rate", total: "5", totalTax: "0", taxes: [])
        let shippingMethod = ShippingMethod(siteID: 12345, methodID: "flat_rate", title: "Flat Rate")

        // When
        let viewModel = ShippingLineRowViewModel(shippingLine: shippingLine,
                                                 shippingMethods: [shippingMethod],
                                                 editable: false,
                                                 currencyFormatter: CurrencyFormatter(currencySettings: CurrencySettings()))

        // Then
        assertEqual(shippingLine.methodTitle, viewModel.shippingTitle)
        assertEqual(shippingMethod.title, viewModel.shippingMethod)
        assertEqual("$5.00", viewModel.shippingAmount)
        XCTAssertFalse(viewModel.editable)
    }
}

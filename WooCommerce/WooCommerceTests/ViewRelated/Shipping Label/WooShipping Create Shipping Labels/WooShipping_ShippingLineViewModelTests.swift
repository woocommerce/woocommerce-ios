import XCTest
@testable import WooCommerce
import Yosemite
import WooFoundation

final class WooShipping_ShippingLineViewModelTests: XCTestCase {

    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

    func test_it_inits_with_expected_values() {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: 123, methodTitle: "Flat Rate Shipping", total: "2.50")

        // When
        let viewModel = WooShipping_ShippingLineViewModel(shippingLine: shippingLine, currencyFormatter: currencyFormatter)

        // Then
        assertEqual(shippingLine.shippingID, viewModel.id)
        assertEqual(shippingLine.methodTitle, viewModel.title)
        assertEqual("$2.50", viewModel.formattedTotal)
    }
}

import XCTest
@testable import WooCommerce

final class CollapsibleProductCardPriceSummaryViewModelTests: XCTestCase {

    func test_priceQuantityLine_returns_properly_formatted_priceQuantityLine() {
        // Given
        let subtotal = "85.68"
        let price = "10.71"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    quantity: quantity,
                                                                    priceBeforeDiscount: price,
                                                                    subtotal: subtotal)

        // Then
        assertEqual("8 × $10.71", viewModel.priceQuantityLine)
    }

    func test_priceQuantityLine_returns_properly_formatted_priceQuantityLine_for_product_not_pricedIndividually() {
        // Given
        let subtotal = "85.68"
        let price = "10.71"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false,
                                                                    quantity: quantity,
                                                                    priceBeforeDiscount: price,
                                                                    subtotal: subtotal)

        // Then
        assertEqual("8 × $0.00", viewModel.priceQuantityLine)
    }

    func test_priceQuantityLine_when_price_is_nil_then_returns_properly_formatted_priceQuantityLine() {
        // Given
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true, quantity: quantity, priceBeforeDiscount: nil, subtotal: "")

        // Then
        assertEqual("8 × -", viewModel.priceQuantityLine)
    }

    func test_subtotalLabel_shows_expected_subtotal() {
        // Given
        let subtotal = "85.68"
        let price = "11"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    quantity: quantity,
                                                                    priceBeforeDiscount: price,
                                                                    subtotal: subtotal)

        // Then
        assertEqual("$85.68", viewModel.subtotalLabel)
    }

    func test_subtotalLabel_returns_expected_subtotal_when_pricedIndividually_is_true() {
        // Given
        let subtotal = "10.71"

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true, quantity: 1, priceBeforeDiscount: nil, subtotal: subtotal)

        // Then
        assertEqual("$10.71", viewModel.subtotalLabel)
    }

    func test_subtotalLabel_returns_expected_subtotal_when_pricedIndividually_is_false() {
        // Given
        let subtotal = "10.71"

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false, quantity: 1, priceBeforeDiscount: nil, subtotal: subtotal)

        // Then
        assertEqual("$0.00", viewModel.subtotalLabel)
    }

}

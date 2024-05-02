import XCTest
@testable import WooCommerce

final class CollapsibleProductCardPriceSummaryViewModelTests: XCTestCase {

    func test_priceQuantityLine_returns_properly_formatted_priceQuantityLine() {
        // Given
        let price = "10.71"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: quantity,
                                                                    price: price)

        // Then
        assertEqual("8 × $10.71", viewModel.priceQuantityLine)
    }

    func test_priceQuantityLine_returns_properly_formatted_priceQuantityLine_for_product_not_pricedIndividually() {
        // Given
        let price = "10.71"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: quantity,
                                                                    price: price)

        // Then
        assertEqual("8 × $0.00", viewModel.priceQuantityLine)
    }

    func test_priceQuantityLine_when_price_is_nil_then_returns_properly_formatted_priceQuantityLine() {
        // Given
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: quantity,
                                                                    price: nil)

        // Then
        assertEqual("8 × -", viewModel.priceQuantityLine)
    }

    func test_priceBeforeDiscountsLabel_multiplies_price_by_quantity() {
        // Given
        let price = "10.71"
        let quantity: Decimal = 8

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: quantity,
                                                                    price: price)

        // Then
        assertEqual("$85.68", viewModel.priceBeforeDiscountsLabel)
    }

    func test_priceBeforeDiscountsLabel_returns_expected_price_when_pricedIndividually_is_true() {
        // Given
        let price = "10.71"

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: true,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: 1,
                                                                    price: price)

        // Then
        assertEqual("$10.71", viewModel.priceBeforeDiscountsLabel)
    }

    func test_priceBeforeDiscountsLabel_returns_expected_price_when_pricedIndividually_is_false() {
        // Given
        let price = "10.71"

        // When
        let viewModel = CollapsibleProductCardPriceSummaryViewModel(pricedIndividually: false,
                                                                    isSubscriptionProduct: false,
                                                                    quantity: 1,
                                                                    price: price)

        // Then
        assertEqual("$0.00", viewModel.priceBeforeDiscountsLabel)
    }

}

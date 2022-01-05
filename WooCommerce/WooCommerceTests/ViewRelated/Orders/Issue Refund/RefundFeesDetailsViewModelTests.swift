import XCTest
import Yosemite
import Fakes

@testable import WooCommerce

final class RefundFeesDetailsViewModelTests: XCTestCase {

    func test_viewModel_correctly_calculates_the_subtotal() {
        // Given
        let feeLines = [
            OrderFeeLine.fake().copy(total: "12.35"),
            OrderFeeLine.fake().copy(total: "91.84"),
        ]
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundFeesDetailsViewModel(fees: feeLines, currency: "USD", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.feesSubtotal, "$104.19")
    }

    func test_viewModel_correctly_calculates_the_total_tax() {
        // Given
        let feeLines = [
            OrderFeeLine.fake().copy(totalTax: "9.87"),
            OrderFeeLine.fake().copy(totalTax: "1.32"),
        ]
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundFeesDetailsViewModel(fees: feeLines, currency: "USD", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.feesTaxes, "$11.19")
    }

    func test_viewModel_correctly_calculates_the_total_fees_to_be_refunded() {
        // Given
        let feeLines = [
            OrderFeeLine.fake().copy(total: "12.09", totalTax: "9.87"),
            OrderFeeLine.fake().copy(total: "23.56", totalTax: "1.32"),
        ]
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundFeesDetailsViewModel(fees: feeLines, currency: "USD", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.feesTotal, "$46.84")
    }

    /// I'm not sure if this is the correct behavior but this is the reality right now.
    func test_viewModel_rounds_off_the_total_when_its_formatted() {
        // Given
        let feeLines = [
            OrderFeeLine.fake().copy(totalTax: "9.87"),
            OrderFeeLine.fake().copy(totalTax: "1.3281"),
        ]
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundFeesDetailsViewModel(fees: feeLines, currency: "USD", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.feesTaxes, "$11.20")
    }
}

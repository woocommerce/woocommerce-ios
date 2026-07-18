import Combine
import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

/// Test cases for `UnitInputViewModelTests`.
///
final class UnitInputViewModelTests: XCTestCase {

    func test_view_model_values_for_bulk_price_update() {
        // Given
        let currencySettings = CurrencySettings()
        let viewModel = UnitInputViewModel.createBulkPriceViewModel(using: currencySettings,
                                                                    onInputChange: {_ in })

        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.placeholder, "0.00")
        XCTAssertEqual(viewModel.style, .secondary)
    }

    func test_regular_price_view_model_when_right_position_and_ltr_currency_symbol_then_places_unit_after_input() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .right,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)

        // When
        let viewModel = Product.createRegularPriceViewModel(regularPrice: "20",
                                                            using: currencySettings,
                                                            onInputChange: { _ in })

        // Then
        XCTAssertEqual(viewModel.unit, "$")
        XCTAssertEqual(viewModel.unitPosition, .afterInputWithoutSpace)
    }

    func test_regular_price_view_model_when_right_position_and_rtl_currency_symbol_then_places_unit_before_input() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .QAR,
                                                currencyPosition: .right,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)

        // When
        let viewModel = Product.createRegularPriceViewModel(regularPrice: "20",
                                                            using: currencySettings,
                                                            onInputChange: { _ in })

        // Then
        XCTAssertEqual(viewModel.unit, currencySettings.currencySymbol)
        XCTAssertEqual(viewModel.unitPosition, .beforeInputWithoutSpace)
    }

    func test_regular_price_view_model_when_left_position_and_rtl_currency_symbol_then_places_unit_after_input() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .QAR,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)

        // When
        let viewModel = Product.createRegularPriceViewModel(regularPrice: "20",
                                                            using: currencySettings,
                                                            onInputChange: { _ in })

        // Then
        XCTAssertEqual(viewModel.unit, currencySettings.currencySymbol)
        XCTAssertEqual(viewModel.unitPosition, .afterInputWithoutSpace)
    }

    func test_bulk_price_view_model_when_right_space_position_and_rtl_currency_symbol_then_places_unit_before_input() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .QAR,
                                                currencyPosition: .rightSpace,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)

        // When
        let viewModel = UnitInputViewModel.createBulkPriceViewModel(using: currencySettings,
                                                                    onInputChange: { _ in })

        // Then
        XCTAssertEqual(viewModel.unit, currencySettings.currencySymbol)
        XCTAssertEqual(viewModel.unitPosition, .beforeInput)
    }
}

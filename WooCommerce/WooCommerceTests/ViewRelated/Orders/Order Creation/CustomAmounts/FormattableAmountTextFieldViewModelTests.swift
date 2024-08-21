import Foundation
import XCTest
import Combine
import WooFoundation
@testable import WooCommerce
@testable import Yosemite

final class FormattableAmountTextFieldViewModelTests: XCTestCase {
    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_prepends_currency_symbol() {
        // Given
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("12")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$12")
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".",
                                              numberOfDecimals: 3)
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        viewModel.updateAmount("12.203")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "12.203 £")
    }

    func test_view_model_removes_non_digit_characters() {
        // Given
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("hi:11.30-")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$11.30")
    }

    func test_view_model_trims_more_than_two_decimal_numbers() {
        // Given
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("$67.321432432")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$67.32")
    }

    func test_view_model_removes_duplicated_decimal_separators() {
        // Given
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("$6.7.3")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$6.7")
    }

    func test_view_model_removes_consecutive_decimal_separators() {
        // Given
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("$6...")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$6.")
    }

    func test_view_model_changes_coma_separator_for_dot_separator_when_the_store_requires_it() {
        // Given
        let comaSeparatorLocale = Locale(identifier: "es_AR")
        let viewModel = FormattableAmountTextFieldViewModel(locale: comaSeparatorLocale, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.updateAmount("10,25")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$10.25")
    }

    func test_view_model_uses_the_store_currency_symbol() {
        // Given
        let storeSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: storeSettings)

        // When
        viewModel.updateAmount("10.25")

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "€10.25")
    }

    func test_amount_placeholder_is_formatted_with_store_currency_settings() {
        // Given
        let storeSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ",", numberOfDecimals: 2)
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: storeSettings)

        // When & Then
        XCTAssertEqual(viewModel.formattedAmount, "€0,00")
    }

    func test_preset_replaces_old_amount_on_the_next_input() {
        // Given
        let storeSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ",", numberOfDecimals: 2)
        let viewModel = FormattableAmountTextFieldViewModel(locale: usLocale, storeCurrencySettings: storeSettings)

        let oldAmount = "12.23"
        let newInput = "1"

        // When
        viewModel.presetAmount("12.23")
        // Simulates the input on the text field that appends the new input to the old
        viewModel.updateAmount(oldAmount + newInput)

        XCTAssertEqual(viewModel.formattedAmount, "€\(newInput)")

    }
}

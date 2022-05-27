import XCTest
import Combine

import Tools
@testable import WooCommerce
@testable import struct Yosemite.ShippingLine

final class ShippingLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // When
        viewModel.amount = "hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.amount, "11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // When
        viewModel.amount = "-hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.amount, "-11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ".",
                                              decimalSeparator: ",",
                                              numberOfDecimals: 3)

        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: customSettings,
                                                     didSelectSave: { _ in })

        // When
        viewModel.amount = "12.203"

        // Then
        XCTAssertEqual(viewModel.amount, "12,203")
        XCTAssertEqual(viewModel.currencySymbol, "£")
        XCTAssertEqual(viewModel.currencyPosition, .rightSpace)
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.amount, "11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "-$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.amount, "-11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_does_not_prefill_zero_amount_without_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "0",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.amount.isEmpty)
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.amount = "11.30"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.amount = "11.50"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.amount = "11.30"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_creates_shippping_line_with_data_from_fields() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.amount = "$11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_creates_shippping_line_with_negative_data_from_fields() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.amount = "-11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "-11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_allows_saving_zero_amount_and_creates_correct_shippping_line() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.amount = "0"
        viewModel.saveData()

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
        XCTAssertEqual(savedShippingLine?.total, "0")
    }

    func test_view_model_creates_shippping_line_with_placeholder_for_method_title() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.amount = "$11.30"
        viewModel.methodTitle = ""

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertNotEqual(savedShippingLine?.methodTitle, "") // "Shipping" placeholder string is localized -> not reliable for comparison here.
    }

    func test_view_model_amount_placeholder_has_expected_value() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertEqual(viewModel.amountPlaceholder, "0")
    }

    func test_view_model_initializes_correctly_with_no_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingShippingLine)
    }
}

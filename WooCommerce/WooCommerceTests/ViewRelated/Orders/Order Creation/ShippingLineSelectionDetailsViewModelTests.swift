import XCTest
import Combine
import WooFoundation
@testable import WooCommerce
@testable import struct Yosemite.ShippingLine

final class ShippingLineSelectionDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertTrue(viewModel.enableDoneButton)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "-hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "-11.30")
        XCTAssertTrue(viewModel.enableDoneButton)
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ".",
                                              decimalSeparator: ",",
                                              numberOfDecimals: 3)

        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: customSettings,
                                                     didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "12.203"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "12,203")
        XCTAssertTrue(viewModel.formattableAmountViewModel.formattedAmount.contains("12,203"))
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount.last, "£")
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "-$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "-11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_does_not_prefill_zero_amount_without_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "0",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.formattableAmountViewModel.amount.isEmpty)
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.30"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = ""

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: true,
                                                     initialMethodTitle: "Flat Rate",
                                                     shippingTotal: "$11.30",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.50"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.30"

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_creates_shippping_line_with_data_from_fields() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "$11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_creates_shippping_line_with_negative_data_from_fields() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "-11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "-11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_allows_saving_zero_amount_and_creates_correct_shippping_line() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "0"
        viewModel.saveData()

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)
        XCTAssertEqual(savedShippingLine?.total, "0")
    }

    func test_view_model_creates_shippping_line_with_placeholder_for_method_title() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "$11.30"
        viewModel.methodTitle = ""

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertNotEqual(savedShippingLine?.methodTitle, "") // "Shipping" placeholder string is localized -> not reliable for comparison here.
    }

    func test_view_model_amount_placeholder_has_expected_value() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount, "$0.00")
    }

    func test_view_model_initializes_correctly_with_no_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(isExistingShippingLine: false,
                                                     initialMethodTitle: "",
                                                     shippingTotal: "",
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingShippingLine)
    }
}

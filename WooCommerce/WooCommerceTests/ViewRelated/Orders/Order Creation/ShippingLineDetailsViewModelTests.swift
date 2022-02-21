import XCTest
import Combine

@testable import WooCommerce
@testable import struct Yosemite.ShippingLine

final class ShippingLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })

        // When
        viewModel.amount = "hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "$11.30")
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".",
                                              numberOfDecimals: 3)

        let viewModel = ShippingLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: customSettings, didSelectSave: { _ in })

        // When
        viewModel.amount = "12.203"

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "12.203 £")
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowShippingTotal: true,
                                                               shippingTotal: "$11.30",
                                                               shippingMethodTitle: "Flat Rate")

        let viewModel = ShippingLineDetailsViewModel(inputData: inputData, locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.formattedAmount, "$11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = ShippingLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })
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
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowShippingTotal: true,
                                                               shippingTotal: "$11.30",
                                                               shippingMethodTitle: "Flat Rate")

        let viewModel = ShippingLineDetailsViewModel(inputData: inputData, locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })
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
        let viewModel = ShippingLineDetailsViewModel(inputData: .init(),
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.amount = "$11.30"
        viewModel.methodTitle = "Flat Rate"

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_creates_shippping_line_with_placeholder_for_method_title() {
        // Given
        var savedShippingLine: ShippingLine?
        let viewModel = ShippingLineDetailsViewModel(inputData: .init(),
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
}

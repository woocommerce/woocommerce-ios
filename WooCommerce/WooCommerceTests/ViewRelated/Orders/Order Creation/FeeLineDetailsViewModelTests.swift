import XCTest
import Combine

@testable import WooCommerce
@testable import struct Yosemite.OrderFeeLine

final class FeeLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })

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

        let viewModel = FeeLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: customSettings, didSelectSave: { _ in })

        // When
        viewModel.amount = "12.203"

        // Then
        XCTAssertEqual(viewModel.formattedAmount, "12.203 £")
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowFees: true,
                                                               feesTotal: "15.30")

        let viewModel = FeeLineDetailsViewModel(inputData: inputData, locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingFeeLine)
        XCTAssertEqual(viewModel.feeType, .fixed)
        XCTAssertEqual(viewModel.formattedAmount, "$15.30")
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = FeeLineDetailsViewModel(inputData: .init(), locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })
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
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowFees: true,
                                                               feesBaseAmountForPercentage: 100,
                                                               feesTotal: "11.30")

        let viewModel = FeeLineDetailsViewModel(inputData: inputData, locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.amount = "11.50"
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.amount = "11.30"
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.feeType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_matched_percentage_value() {
        // Given
        // Initial fee is $10/5%
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowFees: true,
                                                               feesBaseAmountForPercentage: 200,
                                                               feesTotal: "10")

        let viewModel = FeeLineDetailsViewModel(inputData: inputData, locale: usLocale, storeCurrencySettings: usStoreSettings, didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // Change fee to $5
        viewModel.amount = "5"
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // Change fee to 5%
        viewModel.amount = "5"
        viewModel.feeType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_creates_fee_line_with_fixed_amount() {
        // Given
        var savedFeeLine: OrderFeeLine?
        let viewModel = FeeLineDetailsViewModel(inputData: .init(),
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.amount = "$11.30"

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine?.total, "11.30")
    }

    func test_view_model_creates_fee_line_with_percentage_amount() {
        // Given
        var savedFeeLine: OrderFeeLine?
        let inputData = NewOrderViewModel.PaymentDataViewModel(shouldShowFees: true,
                                                               feesBaseAmountForPercentage: 200,
                                                               feesTotal: "10")
        let viewModel = FeeLineDetailsViewModel(inputData: inputData,
                                                     locale: usLocale,
                                                     storeCurrencySettings: usStoreSettings,
                                                     didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.feeType = .percentage

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine?.total, "20")
    }
}

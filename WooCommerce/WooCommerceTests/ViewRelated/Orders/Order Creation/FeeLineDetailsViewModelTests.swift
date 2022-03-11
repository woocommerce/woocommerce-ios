import XCTest
import Combine

@testable import WooCommerce
@testable import struct Yosemite.OrderFeeLine

final class FeeLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 0,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.amount = "hi:11.3005.02-"

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertEqual(viewModel.amount, "11.30")
        XCTAssertEqual(viewModel.currencySymbol, "$")
        XCTAssertEqual(viewModel.currencyPosition, .left)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 0,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.amount = "-hi:11.3005.02-"

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertEqual(viewModel.amount, "-11.30")
        XCTAssertEqual(viewModel.currencySymbol, "$")
        XCTAssertEqual(viewModel.currencyPosition, .left)
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".",
                                              numberOfDecimals: 3)

        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 0,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: customSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.amount = "12.203"

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertEqual(viewModel.amount, "12.203")
        XCTAssertEqual(viewModel.currencySymbol, "£")
        XCTAssertEqual(viewModel.currencyPosition, .rightSpace)
    }

    func test_view_model_formats_percentage_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 100,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.feeType = .percentage
        viewModel.percentage = "hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.percentage, "11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_formats_negative_percentage_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 100,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.feeType = .percentage
        viewModel.percentage = "-hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.percentage, "-11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: true,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "10",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingFeeLine)
        XCTAssertEqual(viewModel.feeType, .fixed)
        XCTAssertEqual(viewModel.amount, "10.00")
        XCTAssertEqual(viewModel.percentage, "5")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: true,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "-10",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingFeeLine)
        XCTAssertEqual(viewModel.feeType, .fixed)
        XCTAssertEqual(viewModel.amount, "-10.00")
        XCTAssertEqual(viewModel.percentage, "-5")
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // $11.30
        viewModel.amount = "11.30"
        viewModel.feeType = .fixed
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // 0%
        viewModel.percentage = ""
        viewModel.feeType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // 10%
        viewModel.percentage = "10"
        viewModel.feeType = .percentage
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // $0
        viewModel.amount = ""
        viewModel.feeType = .fixed
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: true,
                                                baseAmountForPercentage: 100,
                                                feesTotal: "11.30",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
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
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: true,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "10",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
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
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 0,
                                                feesTotal: "",
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
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "0",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.feeType = .percentage
        viewModel.percentage = "10"

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine?.total, "20.00")
    }

    func test_view_model_creates_negative_fee_line() {
        // Given
        var savedFeeLine: OrderFeeLine?
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 0,
                                                feesTotal: "",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.amount = "-$11.30"

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine?.total, "-11.30")
    }

    func test_view_model_creates_fee_line_with_taxes_enabled() {
        // Given
        var savedFeeLine: OrderFeeLine?
        let viewModel = FeeLineDetailsViewModel(isExistingFeeLine: false,
                                                baseAmountForPercentage: 200,
                                                feesTotal: "100",
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedFeeLine?.taxStatus, .taxable)
    }
}

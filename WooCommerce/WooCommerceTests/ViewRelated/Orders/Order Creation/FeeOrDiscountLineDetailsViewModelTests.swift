import XCTest
import Combine

import WooFoundation
@testable import WooCommerce
@testable import struct Yosemite.OrderFeeLine

final class FeeOrDiscountLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.updateAmount("hi:11.3005.02-")

        // Then
        XCTAssertEqual(viewModel.amount, "11.30")
        XCTAssertEqual(viewModel.currencySymbol, "$")
        XCTAssertEqual(viewModel.currencyPosition, .left)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.updateAmount("-hi:11.3005.02-")

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

        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: customSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.updateAmount("12.203")

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertEqual(viewModel.amount, "12.203")
        XCTAssertEqual(viewModel.currencySymbol, "£")
        XCTAssertEqual(viewModel.currencyPosition, .rightSpace)
    }

    func test_view_model_formats_percentage_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 100,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.feeOrDiscountType = .percentage
        viewModel.updatePercentage("hi:11.3005.02-")

        // Then
        XCTAssertTrue(viewModel.isPercentageOptionAvailable)
        XCTAssertEqual(viewModel.percentage, "11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_formats_negative_percentage_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 100,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // When
        viewModel.feeOrDiscountType = .percentage
        viewModel.updatePercentage("-hi:11.3005.02-")

        // Then
        XCTAssertEqual(viewModel.percentage, "-11.30")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                baseAmountForPercentage: 200,
                                                initialTotal: "10",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingLine)
        XCTAssertEqual(viewModel.feeOrDiscountType, .fixed)
        XCTAssertEqual(viewModel.amount, "10.00")
        XCTAssertEqual(viewModel.percentage, "5")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                baseAmountForPercentage: 200,
                                                initialTotal: "-10",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingLine)
        XCTAssertEqual(viewModel.feeOrDiscountType, .fixed)
        XCTAssertEqual(viewModel.amount, "-10.00")
        XCTAssertEqual(viewModel.percentage, "-5")
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 200,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // $11.30
        viewModel.updateAmount("11.30")
        viewModel.feeOrDiscountType = .fixed
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // 0%
        viewModel.updatePercentage("")
        viewModel.feeOrDiscountType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // 10%
        viewModel.updatePercentage("10")
        viewModel.feeOrDiscountType = .percentage
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // $0
        viewModel.updateAmount("")
        viewModel.feeOrDiscountType = .fixed
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                baseAmountForPercentage: 100,
                                                initialTotal: "11.30",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.updateAmount("11.50")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.updateAmount("11.30")
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        viewModel.feeOrDiscountType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_matched_percentage_value() {
        // Given
        // Initial fee is $10/5%
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                baseAmountForPercentage: 200,
                                                initialTotal: "10",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When & Then
        // Change fee to $5
        viewModel.updateAmount("5")
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When & Then
        // Change fee to 5%
        viewModel.updateAmount("5")
        viewModel.feeOrDiscountType = .percentage
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_creates_fee_line_with_fixed_amount() {
        // Given
        var savedFeeLine: String?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.updateAmount("$11.30")

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine, "11.30")
    }

    func test_view_model_creates_fee_line_with_percentage_amount() {
        // Given
        var savedFeeLine: String?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 200,
                                                initialTotal: "0",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.feeOrDiscountType = .percentage
        viewModel.updatePercentage("10")

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine, "20.00")
    }

    func test_view_model_creates_negative_fee_line() {
        // Given
        var savedFeeLine: String?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { newFeeLine in
            savedFeeLine = newFeeLine
        })

        // When
        viewModel.updateAmount("-$11.30")

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedFeeLine, "-11.30")
    }

    func test_view_model_amount_placeholder_has_expected_value() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertEqual(viewModel.amountPlaceholder, "0")
    }

    func test_view_model_initializes_correctly_with_no_existing_fee_line() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .fee,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertFalse(viewModel.isExistingLine)
    }

    func test_saveData_when_type_line_discount_with_fixed_amount_then_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .discount,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                          analytics: WooAnalytics(analyticsProvider: analytics),
                                                didSelectSave: { _ in })

        // When
        viewModel.updateAmount("$11.30")
        viewModel.feeOrDiscountType = .fixed
        viewModel.saveData()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAdd.rawValue)
        XCTAssertEqual(analytics.receivedProperties.first?["type"] as? String, FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.fixed.rawValue)
    }

    func test_saveData_when_type_line_discount_with_percentage_then_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .discount,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                          analytics: WooAnalytics(analyticsProvider: analytics),
                                                didSelectSave: { _ in })

        // When
        viewModel.updatePercentage("10")
        viewModel.feeOrDiscountType = .percentage
        viewModel.saveData()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountAdd.rawValue)
        XCTAssertEqual(analytics.receivedProperties.first?["type"] as? String, FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType.percentage.rawValue)
    }

    func test_removeValue_when_type_line_discount_then_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                baseAmountForPercentage: 0,
                                                initialTotal: "",
                                                lineType: .discount,
                                                locale: usLocale,
                                                storeCurrencySettings: usStoreSettings,
                                                          analytics: WooAnalytics(analyticsProvider: analytics),
                                                didSelectSave: { _ in })

        // When
        viewModel.removeValue()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderProductDiscountRemove.rawValue)
    }
}

import XCTest
import Combine

import WooFoundation
@testable import WooCommerce
@testable import struct Yosemite.OrderFeeLine

final class FeeOrDiscountLineDetailsViewModelTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    private var cancellables = Set<AnyCancellable>()

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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

    func test_view_model_formats_amount_with_grouping_separators_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // When
        viewModel.updateAmount("$1,000.00")

        // Then
        XCTAssertEqual(viewModel.amount, "1000.00")
        XCTAssertEqual(viewModel.currencySymbol, "$")
        XCTAssertEqual(viewModel.currencyPosition, .left)
    }

    func test_view_model_formats_percentage_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 100,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 100,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 200,
                                                          initialTotal: NSDecimalNumber(string: "10").decimalValue,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingLine)
        XCTAssertEqual(viewModel.feeOrDiscountType, .fixed)
        XCTAssertEqual(viewModel.amount, "10.00")
        XCTAssertEqual(viewModel.percentage, "5.00")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: true,
                                                          baseAmount: 200,
                                                          initialTotal: NSDecimalNumber(string: "-10").decimalValue,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isPercentageOptionAvailable)
        XCTAssertTrue(viewModel.isExistingLine)
        XCTAssertEqual(viewModel.feeOrDiscountType, .fixed)
        XCTAssertEqual(viewModel.amount, "-10.00")
        XCTAssertEqual(viewModel.percentage, "-5.00")
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 200,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 100,
                                                          initialTotal: NSDecimalNumber(string: "11.30").decimalValue,
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
                                                          baseAmount: 200,
                                                          initialTotal: NSDecimalNumber(string: "10").decimalValue,
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
        var savedFeeLine: Decimal?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
        XCTAssertEqual(savedFeeLine, NSDecimalNumber(string: "11.30").decimalValue)
    }

    func test_view_model_creates_fee_line_with_percentage_amount() {
        // Given
        var savedFeeLine: Decimal?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 200,
                                                          initialTotal: .zero,
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
        XCTAssertEqual(savedFeeLine, NSDecimalNumber(string: "20.00").decimalValue)
    }

    func test_view_model_creates_negative_fee_line() {
        // Given
        var savedFeeLine: Decimal?
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
        XCTAssertEqual(savedFeeLine, NSDecimalNumber(string: "-11.30").decimalValue)
    }

    func test_view_model_amount_placeholder_has_expected_value() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // Then
        XCTAssertEqual(viewModel.amountPlaceholder, "0.00")
    }

    func test_view_model_initializes_correctly_with_no_existing_fee_line() {
        // Given
        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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
                                                          baseAmount: 0,
                                                          initialTotal: .zero,
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

    func test_calculatePriceAfterDiscount_when_discount_has_thousands_separators_calculates_price_correctly() {
        // Given
        let baseAmount: Decimal = 1000
        let discountStringInInputField = "950.00"
        let expectedFormattedDiscountedPrice = "$50.00"

        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: baseAmount,
                                                          initialTotal: .zero,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })
        // When
        // Simulates the amount the merchant inputs in the discount input field
        viewModel.updateAmount(discountStringInInputField)

        let discountedPrice = viewModel.recalculateFormattedPriceAfterDiscount

        // Then
        XCTAssertEqual(discountedPrice, expectedFormattedDiscountedPrice)
    }

    func test_calculatePriceAfterDiscount_when_discount_is_smaller_than_price_then_discountExceedsProductPrice_returns_false() {
        // Given
        let baseAmount: Decimal = 1000
        let discountStringInInputField = "950.00"
        let expectedFormattedDiscountedPrice = "$50.00"

        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: baseAmount,
                                                          initialTotal: .zero,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // When
        // Simulates the amount the merchant inputs in the discount input field
        viewModel.updateAmount(discountStringInInputField)

        let discountedPrice = viewModel.recalculateFormattedPriceAfterDiscount

        XCTAssertEqual(discountedPrice, expectedFormattedDiscountedPrice)
        XCTAssertEqual(viewModel.discountExceedsProductPrice, false)
    }

    func test_calculatePriceAfterDiscount_when_discount_is_higher_than_price_then_discountExceedsProductPrice_returns_true() {
        // Given
        let baseAmount: Decimal = 1000
        let discountStringInInputField = "1050.00"
        let expectedFormattedDiscountedPrice = "-$50.00"

        let viewModel = FeeOrDiscountLineDetailsViewModel(isExistingLine: false,
                                                          baseAmount: baseAmount,
                                                          initialTotal: .zero,
                                                          lineType: .fee,
                                                          locale: usLocale,
                                                          storeCurrencySettings: usStoreSettings,
                                                          didSelectSave: { _ in })

        // When
        // Simulates the amount the merchant inputs in the discount input field
        viewModel.updateAmount(discountStringInInputField)

        let discountedPrice = viewModel.recalculateFormattedPriceAfterDiscount

        XCTAssertEqual(discountedPrice, expectedFormattedDiscountedPrice)
        XCTAssertEqual(viewModel.discountExceedsProductPrice, true)
    }
}

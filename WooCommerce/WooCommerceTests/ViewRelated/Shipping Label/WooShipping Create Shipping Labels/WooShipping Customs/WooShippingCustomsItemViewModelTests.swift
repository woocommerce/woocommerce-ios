import XCTest
@testable import WooCommerce

final class WooShippingCustomsItemViewModelTests: XCTestCase {
    private var viewModel: WooShippingCustomsItemViewModel!

    override func setUp() {
        super.setUp()
        viewModel = WooShippingCustomsItemViewModel(itemName: "Test",
                                                    itemProductID: 22,
                                                    itemQuantity: 1,
                                                    itemValue: 0,
                                                    itemWeight: 0,
                                                    currencySymbol: "$")
    }

    func test_when_tariff_number_is_empty_then_it_is_valid() {
        viewModel.hsTariffNumber = ""
        XCTAssertTrue(viewModel.isValidTariffNumber)
    }

    func test_when_tariff_number_has_six_digits_then_it_is_valid() {
        viewModel.hsTariffNumber = "123456"
        XCTAssertTrue(viewModel.isValidTariffNumber)
    }

    func test_when_tariff_number_has_twelve_digits_then_it_is_valid() {
        viewModel.hsTariffNumber = "123456789012"
        XCTAssertTrue(viewModel.isValidTariffNumber)
    }

    func test_when_tariff_number_has_less_than_six_digits_then_it_is_not_valid() {
        viewModel.hsTariffNumber = "12345"
        XCTAssertFalse(viewModel.isValidTariffNumber)
    }

    func test_when_tariff_number_has_more_than_twelve_digits_then_it_is_not_valid() {
        viewModel.hsTariffNumber = "1234567890123"
        XCTAssertFalse(viewModel.isValidTariffNumber, "A tariff number longer than 12 digits should be invalid.")
    }

    func test_when_tariff_number_has_non_digits_then_it_is_not_valid() {
        viewModel.hsTariffNumber = "12345A"
        XCTAssertFalse(viewModel.isValidTariffNumber)
    }

    func test_when_tariff_number_has_all_digits_more_than_six_and_less_than_twelve_then_it_is_valid() {
        viewModel.hsTariffNumber = "987654321098"
        XCTAssertTrue(viewModel.isValidTariffNumber)
    }

    func test_when_item_weight_is_zero_then_it_is_invalid() {
        // Given
        let viewModel = WooShippingCustomsItemViewModel(
            itemName: "Test",
            itemProductID: 22,
            itemQuantity: 1,
            itemValue: 10,
            itemWeight: 0,
            currencySymbol: "$",
            storageManager: MockStorageManager()
        )

        // Then
        XCTAssertTrue(viewModel.weightPerUnit.isEmpty, "Weight should be empty it the initial value is zero")
        XCTAssertFalse(viewModel.isValidWeight, "isValidWeight should be false when the weight is zero")
    }

    func test_hsTariffNumberTotalValue_when_currency_symbol_is_not_$_returns_nil() {
        // Given
        viewModel = WooShippingCustomsItemViewModel(itemName: "Test",
                                                    itemProductID: 22,
                                                    itemQuantity: 1,
                                                    itemValue: 0,
                                                    itemWeight: 0,
                                                    currencySymbol: "$")

        // Then
        XCTAssertNil(viewModel.hsTariffNumberTotalValue)
    }

    func test_hsTariffNumberTotalValue_when_currency_symbol_is_$_but_hsTariffNumber_is_empty_returns_nil() {
        //Given
        viewModel = WooShippingCustomsItemViewModel(itemName: "Test",
                                                    itemProductID: 22,
                                                    itemQuantity: 1,
                                                    itemValue: 0,
                                                    itemWeight: 0,
                                                    currencySymbol: "$")

        // When
        viewModel.valuePerUnit = "1000"
        viewModel.hsTariffNumber = ""

        // Then
        XCTAssertNil(viewModel.hsTariffNumberTotalValue)
    }

    func test_hsTariffNumberTotalValue_when_currency_symbol_is_$_but_invalid_hs_tariff_number_returns_nil() {
        // Given
        viewModel = WooShippingCustomsItemViewModel(itemName: "Test",
                                                    itemProductID: 22,
                                                    itemQuantity: 1,
                                                    itemValue: 0,
                                                    itemWeight: 0,
                                                    currencySymbol: "$")
        viewModel.hsTariffNumber = "123"
        viewModel.valuePerUnit = "1000"

        // Then
        XCTAssertNil(viewModel.hsTariffNumberTotalValue)
    }

    func test_hsTariffNumberTotalValue_when_currency_symbol_is_$_and_value_is_more_than_2500_and_valid_hs_tariff_number_returns_values() {
        // Given
        viewModel = WooShippingCustomsItemViewModel(itemName: "Test",
                                                    itemProductID: 22,
                                                    itemQuantity: 2,
                                                    itemValue: 0,
                                                    itemWeight: 0,
                                                    currencySymbol: "$")
        viewModel.valuePerUnit = "3000"
        viewModel.hsTariffNumber = "123456"

        // Then
        XCTAssertEqual(viewModel.hsTariffNumberTotalValue?.0, viewModel.hsTariffNumber)
        XCTAssertEqual(viewModel.hsTariffNumberTotalValue?.1, Decimal(string: viewModel.valuePerUnit)! * 2)
    }

    func test_isNumberValid_whenGivenValidTariffNumbers_shouldReturnTrue() {
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("123456"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("12.34.56"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("12.34.56.78"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("12.34.56.78.90"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("12.34.56.78.90.12"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("123456789012"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("12.345.678.90"))
        XCTAssertTrue(HSTariffNumberValidator.isNumberValid("1.2.3.4.5.6"))
    }

    func test_isNumberValid_whenGivenInvalidTariffNumbers_shouldReturnFalse() {
        // Less than 6 digits
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12345"))
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12.34.5"))

        // More than 12 digits
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("1234567890123"))
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12.34.56.78.90.123"))

        // Invalid characters
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12345a"))
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12.34.5a"))

        // Invalid structure
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid("12.34..56"))
        XCTAssertFalse(HSTariffNumberValidator.isNumberValid(".123456"))
    }

    func test_hsTariffNumber_sanitize_whenGivenStringWithNonDigits_shouldReturnOnlyDigits() {
        XCTAssertEqual(HSTariffNumberValidator.sanitize("12.34.56"), "123456")
        XCTAssertEqual(HSTariffNumberValidator.sanitize("12a34b56c"), "123456")
        XCTAssertEqual(HSTariffNumberValidator.sanitize("...123---456..."), "123456")
        XCTAssertEqual(HSTariffNumberValidator.sanitize("123456"), "123456")
        XCTAssertEqual(HSTariffNumberValidator.sanitize(""), "")
    }
}

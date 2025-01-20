import XCTest
@testable import WooCommerce

class WooShippingCustomsItemViewModelTests: XCTestCase {
    private var viewModel: WooShippingCustomsItemViewModel!

    override func setUp() {
        super.setUp()
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "$")
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

    func test_internationalTransactionNumberIsRequired_when_currency_symbol_is_not_$_returns_false() {
        // When
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "€")

        // Then
        XCTAssertFalse(viewModel.internationalTransactionNumberIsRequired)

    }

    func test_internationalTransactionNumberIsRequired_when_currency_symbol_is_$_but_value_is_less_than_2500_returns_false() {
        // When
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "$")
        viewModel.valuePerUnit = "1000"

        // Then
        XCTAssertFalse(viewModel.internationalTransactionNumberIsRequired)

    }

    func test_internationalTransactionNumberIsRequired_when_currency_symbol_is_$_and_value_is_more_than_2500_but_no_hs_tariff_number_returns_false() {
        // When
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "$")
        viewModel.valuePerUnit = "1000"
        viewModel.hsTariffNumber = ""

        // Then
        XCTAssertFalse(viewModel.internationalTransactionNumberIsRequired)

    }

    func test_internationalTransactionNumberIsRequired_when_currency_symbol_is_$_and_value_is_more_than_2500_but_invalid_hs_tariff_number_returns_false() {
        // When
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "$")
        viewModel.valuePerUnit = "1000"
        viewModel.hsTariffNumber = "123"

        // Then
        XCTAssertFalse(viewModel.internationalTransactionNumberIsRequired)
    }

    func test_internationalTransactionNumberIsRequired_when_currency_symbol_is_$_and_value_is_more_than_2500_and_valid_hs_tariff_number_returns_true() {
        // When
        viewModel = WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "", name: "United States"),
                                                    orderItem: MockOrderItem.sampleItem(), currencySymbol: "$")
        viewModel.valuePerUnit = "3000"
        viewModel.hsTariffNumber = "123456"

        // Then
        XCTAssertTrue(viewModel.internationalTransactionNumberIsRequired)
    }
}

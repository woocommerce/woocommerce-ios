import XCTest
import Combine
import Yosemite
import YosemiteTestHelpers
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

    func test_description_is_invalid_when_length_limit_is_required_and_description_exceeds_30_characters() {
        // Given
        let lengthLimitRequiredSubject = CurrentValueSubject<Bool, Never>(true)

        let viewModel = WooShippingCustomsItemViewModel(
            itemName: "Above The Clouds PET Kiss Cut Tape",
            itemProductID: 22,
            itemQuantity: 1,
            itemValue: 10,
            itemWeight: 1,
            currencySymbol: "$",
            isDescriptionLengthLimitRequired: lengthLimitRequiredSubject.eraseToAnyPublisher()
        )

        // Then
        XCTAssertTrue(viewModel.isDescriptionTooLong)
        XCTAssertFalse(viewModel.isValidDescription)
    }

    func test_description_is_valid_when_length_limit_is_not_required_and_description_exceeds_30_characters() {
        // Given
        let lengthLimitRequiredSubject = CurrentValueSubject<Bool, Never>(false)

        let viewModel = WooShippingCustomsItemViewModel(
            itemName: "Above The Clouds PET Kiss Cut Tape",
            itemProductID: 22,
            itemQuantity: 1,
            itemValue: 10,
            itemWeight: 1,
            currencySymbol: "$",
            isDescriptionLengthLimitRequired: lengthLimitRequiredSubject.eraseToAnyPublisher()
        )

        // Then
        XCTAssertFalse(viewModel.isDescriptionTooLong)
        XCTAssertTrue(viewModel.isValidDescription)
    }

    func test_requiredInformationIsEntered_is_false_when_length_limit_is_required_and_description_exceeds_30_characters() {
        // Given
        let storageManager = MockStorageManager()
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: "US", name: "United States", states: [])])
        let originCountryCodeSubject = CurrentValueSubject<String?, Never>("US")
        let lengthLimitRequiredSubject = CurrentValueSubject<Bool, Never>(true)

        let viewModel = WooShippingCustomsItemViewModel(
            itemName: "Above The Clouds PET Kiss Cut Tape",
            itemProductID: 22,
            itemQuantity: 1,
            itemValue: 10,
            itemWeight: 1,
            currencySymbol: "$",
            originCountryCode: originCountryCodeSubject.eraseToAnyPublisher(),
            isDescriptionLengthLimitRequired: lengthLimitRequiredSubject.eraseToAnyPublisher(),
            storageManager: storageManager
        )

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
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

    func test_requiredInformationIsEntered_when_EU_identifiers_are_not_required_then_identifiers_may_be_empty() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: false)

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
        XCTAssertNil(viewModel.skuValidationError)
        XCTAssertNil(viewModel.manufacturerPartNumberValidationError)
        XCTAssertNil(viewModel.gtinValidationError)
    }

    func test_identifierValidation_when_EU_identifiers_are_required_and_empty_then_returns_required_errors() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
        XCTAssertEqual(viewModel.skuValidationError, "Required for shipments to the EU")
        XCTAssertEqual(viewModel.manufacturerPartNumberValidationError, "Required for shipments to the EU")
        XCTAssertEqual(viewModel.gtinValidationError, "Enter the GTIN/EAN, or select \"No barcode\"")
    }

    func test_identifierValidation_when_values_exceed_64_characters_then_returns_length_errors() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)
        let tooLongValue = String(repeating: "a", count: WooShippingCustomsItemViewModel.maximumEUProductIdentifierLength + 1)

        // When
        viewModel.sku = tooLongValue
        viewModel.manufacturerPartNumber = tooLongValue
        viewModel.gtin = tooLongValue

        // Then
        let expectedError = "Must be 64 characters or fewer."
        XCTAssertEqual(viewModel.skuValidationError, expectedError)
        XCTAssertEqual(viewModel.manufacturerPartNumberValidationError, expectedError)
        XCTAssertEqual(viewModel.gtinValidationError, expectedError)
    }

    func test_identifierValidation_when_unicode_scalars_exceed_64_then_returns_length_error() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)
        let valueWith66Scalars = String(repeating: "e\u{301}", count: 33)
        XCTAssertEqual(valueWith66Scalars.count, 33)
        XCTAssertEqual(valueWith66Scalars.unicodeScalars.count, 66)

        // When
        viewModel.sku = valueWith66Scalars

        // Then
        XCTAssertEqual(viewModel.skuValidationError, "Must be 64 characters or fewer.")
    }

    func test_hasNoBarcode_when_enabled_then_clears_GTIN_and_satisfies_identifier_requirement() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)
        viewModel.sku = "item-sku"
        viewModel.manufacturerPartNumber = "part-number"
        viewModel.gtin = "0123456789012"

        // When
        viewModel.hasNoBarcode = true

        // Then
        XCTAssertTrue(viewModel.gtin.isEmpty)
        XCTAssertNil(viewModel.gtinValidationError)
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
    }

    func test_prefillEUProductIdentifiers_when_fields_are_blank_then_fills_only_blank_fields() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)
        viewModel.sku = "  existing-sku  "
        viewModel.gtin = "  existing-gtin  "
        let identifiers = WooShippingEUProductIdentifiers(productID: 22,
                                                          sku: "prefilled-sku",
                                                          manufacturerProductID: "prefilled-part-number",
                                                          standardizedProductID: "prefilled-gtin")

        // When
        viewModel.prefillEUProductIdentifiers(identifiers)

        // Then
        XCTAssertEqual(viewModel.sku, "  existing-sku  ")
        XCTAssertEqual(viewModel.manufacturerPartNumber, "prefilled-part-number")
        XCTAssertEqual(viewModel.gtin, "  existing-gtin  ")
    }

    func test_prefillEUProductIdentifiers_when_standardized_ID_is_Y081_then_selects_no_barcode() {
        // Given
        let viewModel = makeValidItemViewModel(areIdentifiersRequired: true)
        let identifiers = WooShippingEUProductIdentifiers(productID: 22,
                                                          sku: "prefilled-sku",
                                                          manufacturerProductID: "prefilled-part-number",
                                                          standardizedProductID: WooShippingCustomsItemViewModel.noBarcodeProductIdentifier)

        // When
        viewModel.prefillEUProductIdentifiers(identifiers)

        // Then
        XCTAssertTrue(viewModel.hasNoBarcode)
        XCTAssertTrue(viewModel.gtin.isEmpty)
    }

    private func makeValidItemViewModel(areIdentifiersRequired: Bool) -> WooShippingCustomsItemViewModel {
        let storageManager = MockStorageManager()
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: "US", name: "United States", states: [])])
        return WooShippingCustomsItemViewModel(itemName: "Test",
                                               itemProductID: 22,
                                               itemQuantity: 1,
                                               itemValue: 10,
                                               itemWeight: 1,
                                               currencySymbol: "$",
                                               originCountryCode: Just("US").eraseToAnyPublisher(),
                                               areEUProductIdentifiersRequired: Just(areIdentifiersRequired).eraseToAnyPublisher(),
                                               storageManager: storageManager)
    }
}

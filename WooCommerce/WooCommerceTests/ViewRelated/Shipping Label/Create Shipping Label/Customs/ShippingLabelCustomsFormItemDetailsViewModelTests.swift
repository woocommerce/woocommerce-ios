import XCTest
import Yosemite
@testable import WooCommerce

class ShippingLabelCustomsFormItemDetailsViewModelTests: XCTestCase {

    func test_description_validation_succeeds_if_description_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "Lorem Ipsum"

        // Then
        XCTAssertTrue(viewModel.hasValidDescription)
    }

    func test_description_validation_fails_if_description_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = ""

        // Then
        XCTAssertFalse(viewModel.hasValidDescription)
    }

    func test_description_validation_fails_if_description_contains_only_space() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "   \n"

        // Then
        XCTAssertFalse(viewModel.hasValidDescription)
    }

    func test_value_validation_succeeds_if_value_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.value = "10"

        // Then
        XCTAssertNotNil(viewModel.validatedValue)
    }

    func test_value_validation_fails_if_value_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When & then
        viewModel.value = "1..0"
        XCTAssertNil(viewModel.validatedValue)

        viewModel.value = "abc"
        XCTAssertNil(viewModel.validatedValue)
    }

    func test_weight_validation_succeeds_if_weight_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.weight = "240"

        // Then
        XCTAssertNotNil(viewModel.validatedWeight)
    }

    func test_weight_validation_fails_if_weight_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When & then
        viewModel.value = "1..0"
        XCTAssertNil(viewModel.validatedWeight)

        viewModel.value = "abc"
        XCTAssertNil(viewModel.validatedWeight)
    }

    func test_origin_country_validation_succeeds_if_country_has_non_empty_code() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.originCountry = Country(code: "VN", name: "Vietnam", states: [])

        // Then
        XCTAssertTrue(viewModel.hasValidOriginCountry)
    }

    func test_origin_country_validation_fails_if_country_has_empty_code() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.originCountry = Country(code: "", name: "", states: [])

        // Then
        XCTAssertFalse(viewModel.hasValidOriginCountry)
    }

    func test_HSTariffNumber_validation_succeeds_if_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.hsTariffNumber = ""

        // Then
        XCTAssertTrue(viewModel.hasValidHSTariffNumber)
    }

    func test_HSTariffNumber_validation_succeeds_if_contains_6_digits() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.hsTariffNumber = "123456"

        // Then
        XCTAssertTrue(viewModel.hasValidHSTariffNumber)
    }

    func test_HSTariffNumber_validation_fails_if_does_not_contain_6_digits() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When & then
        viewModel.hsTariffNumber = "12345"
        XCTAssertFalse(viewModel.hasValidHSTariffNumber)

        viewModel.hsTariffNumber = "1234@t"
        XCTAssertFalse(viewModel.hasValidHSTariffNumber)
    }

    func test_validatedHSTariffNumber_returns_correctly() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When & then
        viewModel.hsTariffNumber = ""
        XCTAssertEqual(viewModel.validatedHSTariffNumber, "")

        viewModel.hsTariffNumber = "123456"
        XCTAssertEqual(viewModel.validatedHSTariffNumber, "123456")

        viewModel.hsTariffNumber = "12345"
        XCTAssertNil(viewModel.validatedHSTariffNumber)
    }

    func test_validatedTotalValue_returns_correctly() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake().copy(quantity: 2),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When & then
        viewModel.value = "10"
        XCTAssertEqual(viewModel.validatedTotalValue, 20)

        viewModel.value = "1..0"
        XCTAssertNil(viewModel.validatedTotalValue)
    }

    func test_validItem_and_validatedItem_return_correctly_when_all_fields_are_valid() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake().copy(quantity: 2),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "Test description"
        viewModel.value = "10"
        viewModel.weight = "1.5"
        viewModel.hsTariffNumber = ""
        viewModel.originCountry = Country(code: "VN", name: "Vietnam", states: [])

        // Then
        XCTAssertTrue(viewModel.validItem)
        XCTAssertNotNil(viewModel.validatedItem)
    }

    func test_validItem_and_validatedItem_return_correctly_when_not_all_fields_are_valid() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake().copy(quantity: 2),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: false,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = ""
        viewModel.value = "10"
        viewModel.weight = "1.5"
        viewModel.hsTariffNumber = ""
        viewModel.originCountry = Country(code: "VN", name: "Vietnam", states: [])

        // Then
        XCTAssertFalse(viewModel.validItem)
        XCTAssertNil(viewModel.validatedItem)
    }

    func test_description_validation_fails_when_is_EU_Shipping_Scenario_if_description_is_not_long_enough() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: true,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "No"

        // Then
        XCTAssertFalse(viewModel.hasValidDescription)
    }

    func test_description_validation_succeeds_when_is_EU_Shipping_Scenario_if_description_is_long_enough() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: true,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "Yes"

        // Then
        XCTAssertTrue(viewModel.hasValidDescription)
    }

    func test_canDisplayTooltipInfoIcon_is_true_when_available_if_item_is_validated() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: true,
                                                                     isEUTooltipAvailable: true)

        // When
        viewModel.description = "Yes"
        viewModel.value = "10"
        viewModel.weight = "1.5"
        viewModel.hsTariffNumber = ""
        viewModel.originCountry = Country(code: "AT", name: "Austria", states: [])

        // Then
        XCTAssertTrue(viewModel.validatedItem != nil)
        XCTAssertTrue(viewModel.canDisplayTooltipInfoIcon)
    }

    func test_canDisplayTooltipInfoIcon_is_false_when_available_if_item_is_not_validated() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: true,
                                                                     isEUTooltipAvailable: true)

        // When
        viewModel.description = "No"
        viewModel.value = "10"
        viewModel.weight = "1.5"
        viewModel.hsTariffNumber = ""
        viewModel.originCountry = Country(code: "AT", name: "Austria", states: [])

        // Then
        XCTAssertTrue(viewModel.validatedItem == nil)
        XCTAssertFalse(viewModel.canDisplayTooltipInfoIcon)
    }

    func test_canDisplayTooltipInfoIcon_is_false_when_isEUTooltipAvailable_is_false() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(),
                                                                     countries: [],
                                                                     currency: "",
                                                                     shouldEnforceEUCustomsDescription: true,
                                                                     isEUTooltipAvailable: false)

        // When
        viewModel.description = "Yes"
        viewModel.value = "10"
        viewModel.weight = "1.5"
        viewModel.hsTariffNumber = ""
        viewModel.originCountry = Country(code: "AT", name: "Austria", states: [])

        // Then
        XCTAssertTrue(viewModel.validatedItem != nil)
        XCTAssertFalse(viewModel.canDisplayTooltipInfoIcon)
    }
}

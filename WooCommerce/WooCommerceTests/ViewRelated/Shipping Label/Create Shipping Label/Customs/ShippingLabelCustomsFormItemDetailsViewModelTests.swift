import XCTest
import Yosemite
@testable import WooCommerce

class ShippingLabelCustomsFormItemDetailsViewModelTests: XCTestCase {

    func test_description_validation_succeeds_if_description_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.description = "Lorem Ipsum"

        // Then
        XCTAssertTrue(viewModel.hasValidDescription)
    }

    func test_description_validation_fails_if_description_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.description = ""

        // Then
        XCTAssertFalse(viewModel.hasValidDescription)
    }

    func test_description_validation_fails_if_description_contains_only_space() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.description = "   \n"

        // Then
        XCTAssertFalse(viewModel.hasValidDescription)
    }

    func test_value_validation_succeeds_if_value_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.value = "10"

        // Then
        XCTAssertNotNil(viewModel.validatedValue)
    }

    func test_value_validation_fails_if_value_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When & then
        viewModel.value = "1..0"
        XCTAssertNil(viewModel.validatedValue)

        viewModel.value = "abc"
        XCTAssertNil(viewModel.validatedValue)
    }

    func test_weight_validation_succeeds_if_weight_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.weight = "240"

        // Then
        XCTAssertNotNil(viewModel.validatedWeight)
    }

    func test_weight_validation_fails_if_weight_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When & then
        viewModel.value = "1..0"
        XCTAssertNil(viewModel.validatedWeight)

        viewModel.value = "abc"
        XCTAssertNil(viewModel.validatedWeight)
    }

    func test_origin_country_validation_succeeds_if_country_has_non_empty_code() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.originCountry = Country(code: "VN", name: "Vietnam", states: [])

        // Then
        XCTAssertTrue(viewModel.hasValidOriginCountry)
    }

    func test_origin_country_validation_fails_if_country_has_empty_code() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.originCountry = Country(code: "", name: "", states: [])

        // Then
        XCTAssertFalse(viewModel.hasValidOriginCountry)
    }

    func test_HSTariffNumber_validation_succeeds_if_empty() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.hsTariffNumber = ""

        // Then
        XCTAssertTrue(viewModel.hasValidHSTariffNumber)
    }

    func test_HSTariffNumber_validation_succeeds_if_contains_6_digits() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When
        viewModel.hsTariffNumber = "123456"

        // Then
        XCTAssertTrue(viewModel.hasValidHSTariffNumber)
    }

    func test_HSTariffNumber_validation_fails_if_does_not_contain_6_digits() {
        // Given
        let viewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: ShippingLabelCustomsForm.Item.fake(), countries: [], currency: "")

        // When & then
        viewModel.hsTariffNumber = "12345"
        XCTAssertFalse(viewModel.hasValidHSTariffNumber)

        viewModel.hsTariffNumber = "1234@t"
        XCTAssertFalse(viewModel.hasValidHSTariffNumber)
    }
}

import XCTest
@testable import WooCommerce

class ShippingLabelCustomPackageFormViewModelTests: XCTestCase {

    func test_properties_return_expected_values_for_empty_form() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel(lengthUnit: "in", weightUnit: "oz")

        // Then
        XCTAssertEqual(viewModel.lengthUnit, "in")
        XCTAssertEqual(viewModel.weightUnit, "oz")
        XCTAssertEqual(viewModel.packageName, "")
        XCTAssertEqual(viewModel.packageType, .box)
        XCTAssertEqual(viewModel.packageLength, "")
        XCTAssertEqual(viewModel.packageWidth, "")
        XCTAssertEqual(viewModel.packageHeight, "")
        XCTAssertEqual(viewModel.emptyPackageWeight, "")
    }

    func test_package_name_validation_succeeds_if_name_is_not_empty() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = "Test"

        // Then
        XCTAssertTrue(viewModel.hasValidName)
    }

    func test_package_name_validation_fails_if_name_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = ""

        // Then
        XCTAssertFalse(viewModel.hasValidName)
    }

    func test_package_name_validation_fails_if_name_has_only_spaces() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = " "

        // Then
        XCTAssertFalse(viewModel.hasValidName)
    }

    func test_package_dimension_validation_succeeds_if_dimension_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageLength = "1.5"
        viewModel.packageWidth = "0.1"
        viewModel.packageHeight = "1"

        // Then
        XCTAssertTrue(viewModel.hasValidDimension(viewModel.packageLength))
        XCTAssertTrue(viewModel.hasValidDimension(viewModel.packageWidth))
        XCTAssertTrue(viewModel.hasValidDimension(viewModel.packageHeight))
    }

    func test_package_dimension_validation_fails_if_dimension_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageLength = "0"
        viewModel.packageWidth = "1..0"
        viewModel.packageHeight = "abc"

        // Then
        XCTAssertFalse(viewModel.hasValidDimension(viewModel.packageLength))
        XCTAssertFalse(viewModel.hasValidDimension(viewModel.packageWidth))
        XCTAssertFalse(viewModel.hasValidDimension(viewModel.packageHeight))
    }

    func test_package_weight_validation_succeeds_if_weight_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.emptyPackageWeight = "0"
        XCTAssertNotNil(viewModel.validatedWeight)

        viewModel.emptyPackageWeight = "1.5"
        XCTAssertNotNil(viewModel.validatedWeight)
    }

    func test_package_weight_validation_fails_if_weight_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.emptyPackageWeight = "-1"
        XCTAssertNil(viewModel.validatedWeight)

        viewModel.emptyPackageWeight = "1..0"
        XCTAssertNil(viewModel.validatedWeight)

        viewModel.emptyPackageWeight = "abc"
        XCTAssertNil(viewModel.validatedWeight)
    }
}

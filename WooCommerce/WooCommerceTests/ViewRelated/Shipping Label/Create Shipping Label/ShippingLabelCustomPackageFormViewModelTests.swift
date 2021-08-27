import XCTest
import Combine
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
        XCTAssertTrue(viewModel.isNameValidated)
    }

    func test_package_name_validation_fails_if_name_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = ""

        // Then
        XCTAssertFalse(viewModel.isNameValidated)
    }

    func test_package_name_validation_fails_if_name_has_only_spaces() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = " "

        // Then
        XCTAssertFalse(viewModel.isNameValidated)
    }

    func test_package_length_validation_succeeds_if_length_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageLength = "1.5"
        XCTAssertTrue(viewModel.isLengthValidated)

        viewModel.packageLength = "0.1"
        XCTAssertTrue(viewModel.isLengthValidated)

        viewModel.packageLength = "1"
        XCTAssertTrue(viewModel.isLengthValidated)
    }

    func test_package_length_validation_fails_if_length_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageLength = "0"

        // Then
        XCTAssertFalse(viewModel.isLengthValidated)
    }

    func test_package_width_validation_succeeds_if_width_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageWidth = "1.5"
        XCTAssertTrue(viewModel.isWidthValidated)

        viewModel.packageWidth = "0.1"
        XCTAssertTrue(viewModel.isWidthValidated)

        viewModel.packageWidth = "1"
        XCTAssertTrue(viewModel.isWidthValidated)
    }

    func test_package_width_validation_fails_if_width_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageWidth = "0"

        // Then
        XCTAssertFalse(viewModel.isWidthValidated)
    }

    func test_package_height_validation_succeeds_if_height_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageHeight = "1.5"
        XCTAssertTrue(viewModel.isHeightValidated)

        viewModel.packageHeight = "0.1"
        XCTAssertTrue(viewModel.isHeightValidated)

        viewModel.packageHeight = "1"
        XCTAssertTrue(viewModel.isHeightValidated)
    }

    func test_package_height_validation_fails_if_height_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageHeight = "0"

        // Then
        XCTAssertFalse(viewModel.isHeightValidated)
    }

    func test_package_weight_validation_succeeds_if_weight_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.emptyPackageWeight = "0"
        XCTAssertTrue(viewModel.isWeightValidated)

        viewModel.emptyPackageWeight = "1.5"
        XCTAssertTrue(viewModel.isWeightValidated)
    }

    func test_package_weight_validation_fails_if_weight_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.emptyPackageWeight = "-1"

        // Then
        XCTAssertFalse(viewModel.isWeightValidated)
    }

    func test_package_validation_succeeds_if_all_fields_are_valid() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = "Test"
        viewModel.packageLength = "1"
        viewModel.packageWidth = "1"
        viewModel.packageHeight = "1"
        viewModel.emptyPackageWeight = "1"

        // Then
        XCTAssertNotNil(viewModel.validatedCustomPackage)
    }

    func test_package_validation_fails_if_any_fields_are_invalid() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = ""
        viewModel.packageLength = "1"
        viewModel.packageWidth = "1"
        viewModel.packageHeight = "1"
        viewModel.emptyPackageWeight = "1"

        // Then
        XCTAssertNil(viewModel.validatedCustomPackage)
    }

    func test_sanitizeNumericInput_returns_expected_sanitized_values() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        var input = "1"
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), input)

        input = "1."
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), input)

        input = "1.5"
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), input)

        input = "a"
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), "")

        input = "1a"
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), "1")

        input = "1.5."
        XCTAssertEqual(viewModel.sanitizeNumericInput(input), "1.5")
    }

    func test_packageLength_is_sanitized() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageLength = "1.."

        // Then
        XCTAssertEqual(viewModel.packageLength, "1.")
    }

    func test_packageWidth_is_sanitized() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageWidth = "1.."

        // Then
        XCTAssertEqual(viewModel.packageWidth, "1.")
    }

    func test_packageHeight_is_sanitized() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageHeight = "1.."

        // Then
        XCTAssertEqual(viewModel.packageHeight, "1.")
    }

    func test_emptyPackageWeight_is_sanitized() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.emptyPackageWeight = "1.."

        // Then
        XCTAssertEqual(viewModel.emptyPackageWeight, "1.")
    }
}

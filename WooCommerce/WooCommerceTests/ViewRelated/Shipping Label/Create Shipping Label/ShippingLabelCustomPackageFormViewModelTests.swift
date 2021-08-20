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
        let _ = viewModel.packageNameValidation.sink { validated in
            XCTAssertTrue(validated)
        }
    }

    func test_package_name_validation_fails_if_name_is_empty() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = ""

        // Then
        let _ = viewModel.packageNameValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }

    func test_package_name_validation_fails_if_name_has_only_spaces() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When
        viewModel.packageName = " "

        // Then
        let _ = viewModel.packageNameValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }

    func test_package_length_validation_succeeds_if_length_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageLength = "1.5"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageLength = "0.1"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageLength = "1"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertTrue(validated)
        }
    }

    func test_package_length_validation_fails_if_length_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageLength = "0"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageLength = "1..0"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageLength = "abc"
        let _ = viewModel.packageLengthValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }

    func test_package_width_validation_succeeds_if_width_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageWidth = "1.5"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageWidth = "0.1"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageWidth = "1"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertTrue(validated)
        }
    }

    func test_package_width_validation_fails_if_width_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageWidth = "0"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageWidth = "1..0"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageWidth = "abc"
        let _ = viewModel.packageWidthValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }

    func test_package_height_validation_succeeds_if_height_is_valid_nonzero_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageHeight = "1.5"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageHeight = "0.1"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.packageHeight = "1"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertTrue(validated)
        }
    }

    func test_package_height_validation_fails_if_height_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.packageHeight = "0"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageHeight = "1..0"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.packageHeight = "abc"
        let _ = viewModel.packageHeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }

    func test_package_weight_validation_succeeds_if_weight_is_valid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.emptyPackageWeight = "0"
        let _ = viewModel.packageWeightValidation.sink { validated in
            XCTAssertTrue(validated)
        }

        viewModel.emptyPackageWeight = "1.5"
        let _ = viewModel.packageWeightValidation.sink { validated in
            XCTAssertTrue(validated)
        }
    }

    func test_package_weight_validation_fails_if_weight_is_invalid_double() {
        // Given
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        // When & Then
        viewModel.emptyPackageWeight = "-1"
        let _ = viewModel.packageWeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.emptyPackageWeight = "1..0"
        let _ = viewModel.packageWeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }

        viewModel.emptyPackageWeight = "abc"
        let _ = viewModel.packageWeightValidation.sink { validated in
            XCTAssertFalse(validated)
        }
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
        let _ = viewModel.packageValidation.sink { validated in
            XCTAssertTrue(validated)
        }
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
        let _ = viewModel.packageValidation.sink { validated in
            XCTAssertFalse(validated)
        }
    }
}

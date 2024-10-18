import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddPackageViewModelTests: XCTestCase {
    func test_it_inits_with_empty_field_values() {
        // Given/When
        let viewModel = WooShippingAddPackageViewModel()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.fieldValues.isEmpty, true)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_clear_field_values() {
        // Given
        let viewModel = WooShippingAddPackageViewModel()

        // When
        viewModel.clearFieldValues()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.fieldValues.isEmpty, true)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_it_with_not_all_field_values_set() {
        // Given
        let viewModel = WooShippingAddPackageViewModel()

        // When
        viewModel.clearFieldValues()

        // Then
        viewModel.fieldValues[.height] = "1"
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_it_with_all_field_values_set() {
        // Given
        let viewModel = WooShippingAddPackageViewModel()

        // When
        viewModel.clearFieldValues()
        for dimensionType in WooShippingAddPackageDimensionType.allCases {
            viewModel.fieldValues[dimensionType] = "1"
        }

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }
}

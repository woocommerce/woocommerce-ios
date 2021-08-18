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

}

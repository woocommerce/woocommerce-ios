import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelPackageListViewModelTests: XCTestCase {

    func test_didSelectCustomPackage_returns_the_expected_value() {
        // Given
        let customPackage = ShippingLabelCustomPackage(isUserDefined: true,
                                                       title: "Box",
                                                       isLetter: true,
                                                       dimensions: "3 x 10 x 4",
                                                       boxWeight: 10,
                                                       maxWeight: 11)
        let viewModel = ShippingLabelPackageListViewModel(state: .results, packagesResponse: nil)

        XCTAssertNil(viewModel.selectedCustomPackage)
        XCTAssertNil(viewModel.selectedPredefinedPackage)

        // When
        viewModel.didSelectCustomPackage(customPackage)

        // Then
        XCTAssertEqual(viewModel.selectedCustomPackage, customPackage)
        XCTAssertNil(viewModel.selectedPredefinedPackage)
    }

    func test_didSelectPredefinedPackage_returns_the_expected_value() {
        // Given
        let predefinedPackage = ShippingLabelPredefinedPackage(id: "package-1",
                                                               title: "Small",
                                                               isLetter: true,
                                                               dimensions: "3 x 4 x 5")
        let viewModel = ShippingLabelPackageListViewModel(state: .results, packagesResponse: nil)

        XCTAssertNil(viewModel.selectedPredefinedPackage)
        XCTAssertNil(viewModel.selectedCustomPackage)

        // When
        viewModel.didSelectPredefinedPackage(predefinedPackage)

        // Then
        XCTAssertEqual(viewModel.selectedPredefinedPackage, predefinedPackage)
        XCTAssertNil(viewModel.selectedCustomPackage)
    }

}

import XCTest
@testable import WooCommerce
import Yosemite

final class WooSavedPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_packages() {
        // Given/When
        let packages: [WooSavedPackageData] = testingPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packages: packages)

        // Then
        XCTAssertEqual(viewModel.packages.count, 2)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_selects_package() {
        // Given
        let packages: [WooSavedPackageData] = testingPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packages: packages)

        // When
        viewModel.selectedPackageId = packages.first?.id

        // Then
        XCTAssertNotNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedPackage)
    }
}

extension WooSavedPackagesSelectionViewModelTests {
    func testingPackages() -> [WooSavedPackageData] {
        return [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "DHL Express",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]
    }
}

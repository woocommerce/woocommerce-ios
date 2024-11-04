import XCTest
@testable import WooCommerce
import Yosemite

final class WooSavedPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_packages() {
        // Given/When
        let viewModel = WooSavedPackagesSelectionViewModel(customPackages: testingCustomPackages(),
                                                           predefinedPackages: testingPredefinedPackages())

        // Then
        XCTAssertEqual(viewModel.customPackages.count, 2)
        XCTAssertEqual(viewModel.predefinedPackages.count, 1)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_selects_package() {
        // Given
        let customPackages = testingCustomPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(customPackages: customPackages,
                                                           predefinedPackages: testingPredefinedPackages())

        // When
        viewModel.selectedPackageId = customPackages.first?.id

        // Then
        XCTAssertNotNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedPackage)
    }

    func test_it_removes_package() {
        // Given
        let customPackages = testingCustomPackages()
        let customPackagesCount = customPackages.count
        let viewModel = WooSavedPackagesSelectionViewModel(customPackages: customPackages,
                                                           predefinedPackages: testingPredefinedPackages())

        // When
        if let package = customPackages.first {
            viewModel.removePackage(package)
        }

        // Then
        XCTAssertEqual(viewModel.customPackages.count, customPackagesCount - 1)
    }

    func test_it_removes_selected_package() {
        // Given
        let customPackages = testingCustomPackages()
        let customPackagesCount = customPackages.count
        let viewModel = WooSavedPackagesSelectionViewModel(customPackages: customPackages,
                                                           predefinedPackages: testingPredefinedPackages())

        // When
        viewModel.selectedPackageId = customPackages.first?.id

        // Then
        XCTAssertNotNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedPackage)

        // When
        if let package = customPackages.first {
            viewModel.removePackage(package)
        }

        // Then
        XCTAssertEqual(viewModel.customPackages.count, customPackagesCount - 1)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedPackage)
    }
}

extension WooSavedPackagesSelectionViewModelTests {
    func testingCustomPackages() -> [WooSavedPackageData] {
        return [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg")
        ]
    }
    func testingPredefinedPackages() -> [WooSavedPackageData] {
        return [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "DHL Express",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]
    }
}

import XCTest
@testable import WooCommerce
import Yosemite

final class WooSavedPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_packages() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.customSavedPackages.count, 3)
        XCTAssertEqual(viewModel.predefinedSavedPackages.count, 2)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_selects_package() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)
        let customPackages = viewModel.customSavedPackages

        // When
        viewModel.selectedPackageId = customPackages.first?.id

        // Then
        XCTAssertNotNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedPackage)
    }

    func test_it_removes_package() async {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)
        let customPackages = viewModel.customSavedPackages
        let customPackagesCount = customPackages.count

        // When
        if let package = customPackages.first {
            let error = await viewModel.removePackage(package)
            XCTAssertNil(error)
        }

        // Then
        XCTAssertEqual(viewModel.customSavedPackages.count, customPackagesCount - 1)
    }

    func test_it_removes_selected_package() async {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)
        let customPackages = viewModel.customSavedPackages
        let customPackagesCount = customPackages.count

        // When
        viewModel.selectedPackageId = customPackages.first?.id

        // Then
        XCTAssertNotNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedPackage)

        // When
        if let package = customPackages.first {
            let error = await viewModel.removePackage(package)
            XCTAssertNil(error)
        }

        // Then
        XCTAssertEqual(viewModel.customSavedPackages.count, customPackagesCount - 1)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedPackage)
    }
}

final class MockWooShippingPackagesRepository: WooShippingPackagesRepositoryProtocol {
    private(set) var loadingSavedPackages: Bool = false
    private(set) var customSavedPackages: [any WooPackageDataRepresentable] = []
    private(set) var predefinedSavedPackages: [any WooPackageDataRepresentable] = []
    private(set) var loadingCarrierPackages: Bool = false
    private(set) var carrierPackages: [WooShippingCarrierPackages] = []

    func loadPackages() {
        loadSavedPackages()
        loadCarrierPackages()
    }

    func loadSavedPackages() {
        loadingSavedPackages = true

        customSavedPackages = [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]
        predefinedSavedPackages = [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "DHL Express",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "USPS Priority Mail Flat Rate Boxes",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]

        loadingSavedPackages = false
    }

    func loadCarrierPackages() {
        loadingCarrierPackages = true

        let uspsPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ])
        ]
        let dhlPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ])
        ]
        let uspsCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.usps, packageGroups: uspsPackageGroups)
        let dhlCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.dhlExpress, packageGroups: dhlPackageGroups)

        carrierPackages = [uspsCarrier, dhlCarrier]

        loadingCarrierPackages = false
    }

    // MARK: - Packages updates

    func deleteSavedPackage(_ packageToRemove: WooPackageDataRepresentable) async -> Error? {
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        return nil
    }

    func addCustomPackage(_ packageToAdd: WooPackageDataRepresentable) async -> Error? {
        customSavedPackages.append(packageToAdd)
        return nil
    }

    func addPredefinedPackage(_ packageToAdd: WooPackageDataRepresentable) async -> Error? {
        predefinedSavedPackages.append(packageToAdd)
        return nil
    }
}

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
    private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    private(set) var loadingPackages: Bool = false
    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { $carrierPackages }

    func loadPackages() {
        loadingPackages = true

        customSavedPackages = [
            WooShippingPackageData(id: UUID().uuidString,
                                name: "Small Flat Rate Box",
                                length: "21.92",
                                width: "13.67",
                                height: "4.14",
                                dimensionsUnit: "cm",
                                weight: "5",
                                weightUnit: "kg",
                                source: .custom,
                                packageType: "box"),
            WooShippingPackageData(id: UUID().uuidString,
                                name: "Small Flat Rate Box",
                                length: "21.92",
                                width: "13.67",
                                height: "4.14",
                                dimensionsUnit: "cm",
                                weight: "5",
                                weightUnit: "kg",
                                source: .custom,
                                packageType: "box"),
            WooShippingPackageData(id: UUID().uuidString,
                                name: "Small Flat Rate Box",
                                length: "21.92",
                                width: "13.67",
                                height: "4.14",
                                dimensionsUnit: "cm",
                                weight: "5",
                                weightUnit: "kg",
                                source: .custom,
                                packageType: "box"),
        ]
        predefinedSavedPackages = [
            WooShippingPackageData(name: "Small Flat Rate Box 2",
                                  length: "21.92",
                                  width: "13.67",
                                  height: "4.14",
                                  dimensionsUnit: "cm",
                                  weight: "5",
                                  weightUnit: "kg",
                                  source: .predefined("DHL Express"),
                                  packageType: "box"),
            WooShippingPackageData(name: "Small Flat Rate Box 3",
                                  length: "21.92",
                                  width: "13.67",
                                  height: "4.14",
                                  dimensionsUnit: "cm",
                                  weight: "5",
                                  weightUnit: "kg",
                                  source: .predefined("DHL Express"),
                                  packageType: "box"),
        ]

        let uspsPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 1",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box")
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 2",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 21",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 22",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
            ])
        ]
        let dhlPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 3", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 3",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 4", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 4",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ])
        ]
        let uspsCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.usps, packageGroups: uspsPackageGroups)
        let dhlCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.dhlExpress, packageGroups: dhlPackageGroups)

        carrierPackages = [uspsCarrier, dhlCarrier]

        loadingPackages = false
    }

    // MARK: - Packages updates

    @MainActor
    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        return nil
    }

    @MainActor
    func saveCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable,
                           dimensionsUnit: String,
                           weightUnit: String, siteID:
                           Int64, stores: StoresManager) async -> Error? {
        guard !customSavedPackages.contains(where: { package in
            return package.id == packageToAdd.id
        })  else {
            return WooShippingPackagesRepositoryError.customPackageWithSameIdAlreadyExists
        }
        customSavedPackages.append(packageToAdd)
        return nil
    }

    @MainActor
    func savePredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        guard !predefinedSavedPackages.contains(where: { package in
            return package.id == packageToAdd.id
        })  else {
            return WooShippingPackagesRepositoryError.predefinedPackageWithSameIdAlreadyExists
        }
        predefinedSavedPackages.append(packageToAdd)
        return nil
    }
}

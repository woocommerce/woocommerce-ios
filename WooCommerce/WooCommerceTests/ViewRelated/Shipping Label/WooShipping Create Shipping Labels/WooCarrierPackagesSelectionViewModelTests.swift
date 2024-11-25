import XCTest
@testable import WooCommerce
import Yosemite
import SwiftUI

final class WooCarrierPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_tabs() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 2)
        XCTAssertEqual(viewModel.tabs.count, 2)
        XCTAssertEqual(viewModel.selectedTabIndex, 0)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_inits_with_zero_tabs() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 0)
        XCTAssertEqual(viewModel.tabs.count, 0)
        XCTAssertNil(viewModel.selectedTabIndex)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_changes_selected_tab() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let carrierTabs = packagesRepository.carrierPackages
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.first?.carrier.name)
        // "select" second tab
        viewModel.selectedTabIndex = 1
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.last?.carrier.name)
    }
}

final class MockWooShippingPackagesRepository: WooShippingPackagesRepositoryProtocol {
    private(set) var loadingSavedPackages: Bool = false
    private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    private(set) var loadingCarrierPackages: Bool = false
    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { $carrierPackages }

    func loadPackages() {
        loadSavedPackages()
        loadCarrierPackages()
    }

    func loadSavedPackages() {
        loadingSavedPackages = true

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

        loadingSavedPackages = false
    }

    func loadCarrierPackages() {
        loadingCarrierPackages = true

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

        loadingCarrierPackages = false
    }

    // MARK: - Packages updates

    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        return nil
    }

    func addCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        customSavedPackages.append(packageToAdd)
        return nil
    }

    func addPredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        predefinedSavedPackages.append(packageToAdd)
        return nil
    }
}

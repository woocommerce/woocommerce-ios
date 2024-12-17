import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddPackageViewModelTests: XCTestCase {
    func test_it_fetches_and_transforms_packages_from_storage() throws {
        // Given
        let siteID: Int64 = 1
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: [.fake().copy(id: "Custom Package")],
                                                   savedPredefinedPackages: [sampleSavedPredefinedPackage()],
                                                   allPredefinedOptions: [sampleCarrierPredefinedOptions()])
        let storageManager = MockStorageManager()
        storageManager.insertSamplePackages(readOnlyPackages: packages)

        // When
        let viewModel = WooShippingAddPackageViewModel(siteID: siteID, storage: storageManager)

        // Then
        XCTAssertEqual(viewModel.customSavedPackages.count, 1)
        XCTAssertEqual(viewModel.predefinedSavedPackages.count, 1)
        XCTAssertEqual(viewModel.starredCarriersPackages.count, 1)
        XCTAssertEqual(viewModel.carrierPackages.count, 1)
        let carrierPackageGroups = try XCTUnwrap(viewModel.carrierPackages.first?.packageGroups)
        XCTAssertEqual(carrierPackageGroups.count, 3)
    }

    func test_it_handles_selected_custom_package() {
        // Given
        let siteID: Int64 = 1
        let selectedPackage = WooShippingPackageData(name: "",
                                                     length: "31.75",
                                                     width: "24.13",
                                                     height: "1.27",
                                                     weight: "",
                                                     source: .custom,
                                                     packageType: "envelope")
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: [.fake().copy(id: "Custom Envelope")],
                                                   savedPredefinedPackages: [sampleSavedPredefinedPackage()],
                                                   allPredefinedOptions: [sampleCarrierPredefinedOptions()])
        let storageManager = MockStorageManager()
        storageManager.insertSamplePackages(readOnlyPackages: packages)

        // When
        let viewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage, siteID: siteID, storage: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedPackageType, .custom)
        XCTAssertNil(viewModel.selectedSavedPackage)
        XCTAssertNil(viewModel.selectedCarriersPackage)
    }

    func test_it_handles_selected_saved_custom_package() {
        // Given
        let siteID: Int64 = 1
        let selectedPackage = WooShippingPackageData(name: "Custom Envelope",
                                                     length: "31.75",
                                                     width: "24.13",
                                                     height: "1.27",
                                                     weight: "0",
                                                     source: .custom,
                                                     packageType: "envelope")
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: [.fake().copy(id: "Custom Envelope")],
                                                   savedPredefinedPackages: [sampleSavedPredefinedPackage()],
                                                   allPredefinedOptions: [sampleCarrierPredefinedOptions()])
        let storageManager = MockStorageManager()
        storageManager.insertSamplePackages(readOnlyPackages: packages)

        // When
        let viewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage, siteID: siteID, storage: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedPackageType, .saved)
        XCTAssertNotNil(viewModel.selectedSavedPackage)
    }

    func test_it_handles_selected_predefined_package() {
        // Given
        let siteID: Int64 = 1
        let selectedPackage = WooShippingPackageData(name: "large_flat_box",
                                                     length: "31.11",
                                                     width: "31.11",
                                                     height: "15.24",
                                                     weight: "0",
                                                     source: .predefined(sourceTitle: "Large Flat Rate Box", sourceID: "usps"),
                                                     packageType: "box")
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: [.fake().copy(id: "Custom Envelope")],
                                                   savedPredefinedPackages: [sampleSavedPredefinedPackage()],
                                                   allPredefinedOptions: [sampleCarrierPredefinedOptions()])
        let storageManager = MockStorageManager()
        storageManager.insertSamplePackages(readOnlyPackages: packages)

        // When
        let viewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage, siteID: siteID, storage: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedPackageType, .carrier)
        XCTAssertNotNil(viewModel.selectedCarriersPackage)
    }

    func test_it_handles_selected_saved_predefined_package() {
        // Given
        let siteID: Int64 = 1
        let selectedPackage = WooShippingPackageData(name: "small_flat_box",
                                                     length: "8.63",
                                                     width: "5.38",
                                                     height: "1.63",
                                                     weight: "0",
                                                     source: .predefined(sourceTitle: "Small Flat Rate Box", sourceID: "usps"),
                                                     packageType: "box")
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: [.fake().copy(id: "Custom Envelope")],
                                                   savedPredefinedPackages: [sampleSavedPredefinedPackage()],
                                                   allPredefinedOptions: [sampleCarrierPredefinedOptions()])
        let storageManager = MockStorageManager()
        storageManager.insertSamplePackages(readOnlyPackages: packages)

        // When
        let viewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage, siteID: siteID, storage: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedPackageType, .saved)
        XCTAssertNotNil(viewModel.selectedSavedPackage)
    }
}

private extension WooShippingAddPackageViewModelTests {
    func sampleSavedPredefinedPackage() -> WooShippingSavedPredefinedPackage {
        WooShippingSavedPredefinedPackage(groupTitle: "pri_flat_boxes",
                                          providerID: "usps",
                                          package: .init(id: "small_flat_box",
                                                         name: "Small Flat Rate Box",
                                                         isLetter: false,
                                                         dimensions: "8.63 x 5.38 x 1.63",
                                                         boxWeight: "",
                                                         groupId: "pri_flat_boxes"))
    }

    func sampleCarrierPredefinedOptions() -> WooShippingCarrierPredefinedOptions {
        WooShippingCarrierPredefinedOptions(carrierID: "usps",
                                            predefinedOptions: [.init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "small_flat_box",
                                                                                                 name: "Small Flat Rate Box",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "8.63 x 5.38 x 1.63",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "pri_flat_boxes")]),
                                                                .init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "large_flat_box",
                                                                                                 name: "",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")]),
                                                                .init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "medium_flat_box_top",
                                                                                                 name: "",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")])])
    }
}

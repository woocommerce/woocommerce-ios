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
}

private extension WooShippingAddPackageViewModelTests {
    func sampleSavedPredefinedPackage() -> WooShippingSavedPredefinedPackage {
        WooShippingSavedPredefinedPackage(groupTitle: "pri_flat_boxes",
                                          providerID: "usps",
                                          package: .init(id: "small_flat_box",
                                                         name: "",
                                                         isLetter: false,
                                                         dimensions: "",
                                                         boxWeight: "",
                                                         groupId: ""))
    }

    func sampleCarrierPredefinedOptions() -> WooShippingCarrierPredefinedOptions {
        WooShippingCarrierPredefinedOptions(carrierID: "usps",
                                            predefinedOptions: [.init(title: "pri_flat_boxes",
                                                                      providerID: "usps",
                                                                      predefinedPackages: [.init(id: "small_flat_box",
                                                                                                 name: "",
                                                                                                 isLetter: false,
                                                                                                 dimensions: "",
                                                                                                 boxWeight: "",
                                                                                                 groupId: "")]),
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

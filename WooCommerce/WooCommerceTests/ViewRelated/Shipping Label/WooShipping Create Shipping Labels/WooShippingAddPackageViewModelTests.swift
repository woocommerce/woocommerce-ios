import XCTest
import TestKit
@testable import WooCommerce
import Yosemite

final class WooShippingAddPackageViewModelTests: XCTestCase {
    @MainActor
    func test_it_inits() {
        // Given/When
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddPackageViewModel(siteID: siteID,
                                                       stores: mockStores)

        // Then
        XCTAssertNotNil(viewModel)

        XCTAssertEqual(viewModel.isLoadingPackages, false)
        XCTAssertEqual(viewModel.selectedSavedPackageId, nil)
        XCTAssertEqual(viewModel.customSavedPackages.count, 0)
        XCTAssertEqual(viewModel.predefinedSavedPackages.count, 0)
        XCTAssertEqual(viewModel.hasSavedPackages, false)
        XCTAssertNil(viewModel.selectedSavedPackage)

        XCTAssertEqual(viewModel.carrierPackages.count, 0)
        XCTAssertEqual(viewModel.selectedCarriersTabIndex, nil)
        XCTAssertEqual(viewModel.selectedCarriersPackageId, nil)
        XCTAssertEqual(viewModel.starredCarriersPackages.count, 0)
        XCTAssertEqual(viewModel.carrierTabs.count, 0)
        XCTAssertNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedCarriersPackage)
    }

    @MainActor
    func test_star_unstar_package() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddPackageViewModel(siteID: siteID,
                                                       stores: mockStores)

        // When
        // Star
        viewModel.starUnstarPackage("1", carrierID: "usps")

        // Then
        XCTAssertEqual(viewModel.starredCarriersPackages.count, 1)

        // When
        // Unstar
        viewModel.starUnstarPackage("1", carrierID: "usps")

        // Then
        XCTAssertEqual(viewModel.starredCarriersPackages.count, 0)
    }

    @MainActor
    func test_load_packages_dispatches_loadPackages_action() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddPackageViewModel(siteID: siteID,
                                                       stores: mockStores)

        mockStores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadPackages(receivedSiteID, completion):
                XCTAssertEqual(receivedSiteID, siteID)
                completion(.success(.fake()))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When
        viewModel.loadPackages()

        // Then
        XCTAssertEqual(mockStores.receivedActions.count, 1)
        assertThat(mockStores.receivedActions.first, isAnInstanceOf: WooShippingAction.self)
    }

    @MainActor
    func test_remove_saved_package_dispatches_deletePackage_action() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddPackageViewModel(siteID: siteID,
                                                       stores: mockStores)

        let customPackage = WooShippingCustomPackage.fake().copy(id: "custom")
        let predefinedPackage = WooShippingPredefinedPackage(id: "predefined",
                                                             name: "name",
                                                             isLetter: false,
                                                             dimensions: "",
                                                             boxWeight: "",
                                                             groupId: "")
        let predefinedSavedPackage = WooShippingSavedPredefinedPackage(groupTitle: "group",
                                                                       providerID: "usps",
                                                                       package: predefinedPackage)

        mockStores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .deletePackage(receivedSiteID, packageID, completion):
                XCTAssertEqual(receivedSiteID, siteID)
                XCTAssert(packageID == customPackage.id || packageID == predefinedSavedPackage.id)
                completion(.success(.fake()))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When/Then
        viewModel.removeSavedPackage(customPackage.toPackageData())
        XCTAssertEqual(mockStores.receivedActions.count, 1)
        assertThat(mockStores.receivedActions.first, isAnInstanceOf: WooShippingAction.self)

        // When/Then
        viewModel.removeSavedPackage(predefinedSavedPackage.toPackageData())
        XCTAssertEqual(mockStores.receivedActions.count, 2)
        assertThat(mockStores.receivedActions.first, isAnInstanceOf: WooShippingAction.self)
    }

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

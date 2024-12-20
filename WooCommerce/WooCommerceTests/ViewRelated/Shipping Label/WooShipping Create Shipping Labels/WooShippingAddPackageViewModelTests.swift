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

    @MainActor
    func test_it_keeps_order_after_reloads() async {
        // Given
        let siteID: Int64 = 1
        let customPackages: [WooShippingCustomPackage] = [
            .fake().copy(id: "Custom1"),
            .fake().copy(id: "Custom2"),
            .fake().copy(id: "Custom3"),
           ]
        let allPredefinedOptions = [sampleCarrierPredefinedOptions()]
        let savedPredefinedPackages: [WooShippingSavedPredefinedPackage] = [
            .init(groupTitle: "pri_flat_boxes",
                  providerID: "usps",
                  package: .init(id: "small_flat_box",
                                 name: "Small Flat Rate Box",
                                 isLetter: false,
                                 dimensions: "",
                                 boxWeight: "",
                                 groupId: "pri_flat_boxes")),
            .init(groupTitle: "pri_flat_boxes",
                  providerID: "usps",
                  package: .init(id: "large_flat_box",
                                 name: "Large Flat Rate Box",
                                 isLetter: false,
                                 dimensions: "",
                                 boxWeight: "",
                                 groupId: "pri_flat_boxes")),
            .init(groupTitle: "pri_flat_boxes",
                  providerID: "usps",
                  package: .init(id: "medium_flat_box_top",
                                 name: "Medium Flat Rate Box",
                                 isLetter: false,
                                 dimensions: "",
                                 boxWeight: "",
                                 groupId: "pri_flat_boxes"))
        ]
        let packages = WooShippingPackagesResponse(siteID: siteID,
                                                   customPackages: customPackages,
                                                   savedPredefinedPackages: savedPredefinedPackages,
                                                   allPredefinedOptions: allPredefinedOptions)
        let storageManager = MockStorageManager()

        storageManager.insertSamplePackages(readOnlyPackages: packages)

        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        mockStores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .loadPackages(receivedSiteID, completion):
                XCTAssertEqual(receivedSiteID, siteID)
                completion(.success(packages))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        let viewModel = WooShippingAddPackageViewModel(selectedPackage: nil, siteID: siteID, stores: mockStores, storage: storageManager)

        // Do first load to get it sorted once
        await viewModel.loadPackages()
        let sortedPredefinedSavedPackages = viewModel.predefinedSavedPackages
        let sortedCustomSavedPackages = viewModel.customSavedPackages

        for _ in 0..<5 {
            // When
            await viewModel.loadPackages()
            // Then
            // check order
            XCTAssertEqual(sortedPredefinedSavedPackages.count, viewModel.predefinedSavedPackages.count)
            for (index, package) in sortedPredefinedSavedPackages.enumerated() {
                XCTAssertEqual(package.id, viewModel.predefinedSavedPackages[index].id)
            }
            XCTAssertEqual(sortedCustomSavedPackages.count, viewModel.customSavedPackages.count)
            for (index, package) in sortedCustomSavedPackages.enumerated() {
                XCTAssertEqual(package.id, viewModel.customSavedPackages[index].id)
            }
        }
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

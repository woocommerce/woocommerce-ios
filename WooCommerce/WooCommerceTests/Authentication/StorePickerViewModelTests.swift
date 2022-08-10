import XCTest
import Yosemite
import protocol Storage.StorageManagerType
@testable import WooCommerce

final class StorePickerViewModelTests: XCTestCase {
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        super.tearDown()
        storageManager = nil
    }

    func test_multipleStoresAvailable_is_correct_for_single_store() {
        // Given
        let testSite = Site.fake()
        storageManager.insertSampleSite(readOnlySite: testSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertFalse(viewModel.multipleStoresAvailable)
    }

    func test_multipleStoresAvailable_is_correct_for_multiple_stores() {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123)
        let testSite2 = Site.fake().copy(siteID: 243)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertTrue(viewModel.multipleStoresAvailable)
    }

    func test_table_view_configs_are_correct_for_empty_store_list() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertEqual(viewModel.separatorStyle, .none)
        XCTAssertEqual(viewModel.numberOfSections, 1)
        XCTAssertNil(viewModel.titleForSection(at: 0))
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 1)
    }

    func test_table_view_configs_are_correct_for_list_with_only_woo_stores() {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertEqual(viewModel.separatorStyle, .singleLine)
        XCTAssertEqual(viewModel.numberOfSections, 1)
        XCTAssertEqual(viewModel.titleForSection(at: 0), Localization.connectedStore)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(viewModel.site(at: IndexPath(row: 0, section: 0))?.siteID, testSite1.siteID)
        XCTAssertEqual(viewModel.indexPath(for: testSite1.siteID), IndexPath(row: 0, section: 0))
    }

    func test_table_view_configs_are_correct_for_list_with_both_woo_and_non_woo_sites() {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 124, name: "def", isWooCommerceActive: true)
        let testSite3 = Site.fake().copy(siteID: 055, name: "hello", isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        storageManager.insertSampleSite(readOnlySite: testSite3)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertEqual(viewModel.separatorStyle, .singleLine)
        XCTAssertEqual(viewModel.numberOfSections, 2)
        XCTAssertEqual(viewModel.titleForSection(at: 0), Localization.pickStore)
        XCTAssertEqual(viewModel.titleForSection(at: 1), Localization.otherSites)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 1), 1)
        XCTAssertEqual(viewModel.site(at: IndexPath(row: 1, section: 0))?.siteID, testSite2.siteID)
        XCTAssertEqual(viewModel.site(at: IndexPath(row: 0, section: 1))?.siteID, testSite3.siteID)
        XCTAssertEqual(viewModel.indexPath(for: testSite3.siteID), IndexPath(row: 0, section: 1))
    }

    func test_trackScreenView_tracks_both_number_of_woo_and_non_woo_sites() throws {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 124, name: "def", isWooCommerceActive: true)
        let testSite3 = Site.fake().copy(siteID: 055, name: "hello", isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        storageManager.insertSampleSite(readOnlySite: testSite3)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)
        viewModel.trackScreenView()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_picker_stores_shown" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["num_of_stores"] as? Int, 2)
        XCTAssertEqual(properties["num_of_non_woo_sites"] as? Int, 1)
    }
}

private extension StorePickerViewModelTests {
    enum Localization {
        static let pickStore = NSLocalizedString(
            "Pick Store to Connect",
            comment: "Store Picker's Section Title: Displayed whenever there are multiple Stores.")
        static let connectedStore = NSLocalizedString(
            "Connected Store",
            comment: "Store Picker's Section Title: Displayed when there's a single pre-selected Store."
        )
        static let otherSites = NSLocalizedString(
            "Other Sites",
            comment: "Store Picker's Section Title: Displayed when there are sites without WooCommerce"
        )
    }
}

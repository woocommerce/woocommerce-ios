import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import YosemiteTestHelpers
@testable import WooCommerce

final class StorePickerViewModelTests: XCTestCase {
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_siteToPreselect_when_multiple_woo_stores_have_no_matching_site_address_then_returns_nil() {
        // Given
        let firstSite = Site.fake().copy(siteID: 123, url: "https://first.example.com", isWooCommerceActive: true)
        let secondSite = Site.fake().copy(siteID: 456, url: "https://second.example.com", isWooCommerceActive: true)
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        sessionManager.defaultCredentials = .wpcom(username: "merchant", authToken: "token", siteAddress: "https://wordpress.com")
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .login, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [firstSite, secondSite])

        // Then
        XCTAssertNil(selectedSite)
    }

    func test_siteToPreselect_when_multiple_mixed_sites_have_no_matching_site_address_then_returns_nil() {
        // Given
        let wooSite = Site.fake().copy(siteID: 123, url: "https://store.example.com", isWooCommerceActive: true)
        let nonWooSite = Site.fake().copy(siteID: 456, url: "https://blog.example.com", isWooCommerceActive: false)
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        sessionManager.defaultCredentials = .wpcom(username: "merchant", authToken: "token", siteAddress: "https://wordpress.com")
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .login, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [wooSite, nonWooSite])

        // Then
        XCTAssertNil(selectedSite)
    }

    func test_siteToPreselect_when_one_woo_store_is_the_only_site_then_returns_it() {
        // Given
        let wooSite = Site.fake().copy(siteID: 123, url: "https://store.example.com", isWooCommerceActive: true)
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        sessionManager.defaultCredentials = .wpcom(username: "merchant", authToken: "token", siteAddress: "https://wordpress.com")
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .login, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [wooSite])

        // Then
        XCTAssertEqual(selectedSite, wooSite)
    }

    func test_siteToPreselect_when_site_address_matches_a_woo_store_then_returns_it() {
        // Given
        let firstSite = Site.fake().copy(siteID: 123, url: "https://first.example.com", isWooCommerceActive: true)
        let matchingSite = Site.fake().copy(siteID: 456, url: "https://matching.example.com", isWooCommerceActive: true)
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        sessionManager.defaultCredentials = .wpcom(username: "merchant", authToken: "token", siteAddress: matchingSite.url)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .login, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [firstSite, matchingSite])

        // Then
        XCTAssertEqual(selectedSite, matchingSite)
    }

    func test_siteToPreselect_when_switching_stores_has_a_default_site_then_returns_it() {
        // Given
        let firstSite = Site.fake().copy(siteID: 123, url: "https://first.example.com", isWooCommerceActive: true)
        let defaultSite = Site.fake().copy(siteID: 456, url: "https://default.example.com", isWooCommerceActive: true)
        let sessionManager = SessionManager.makeForTesting(defaultSite: defaultSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .switchingStores, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [firstSite, defaultSite])

        // Then
        XCTAssertEqual(selectedSite, defaultSite)
    }

    func test_siteToPreselect_when_switching_stores_has_no_default_site_then_returns_the_first_woo_store() {
        // Given
        let firstSite = Site.fake().copy(siteID: 123, url: "https://first.example.com", isWooCommerceActive: true)
        let secondSite = Site.fake().copy(siteID: 456, url: "https://second.example.com", isWooCommerceActive: true)
        let sessionManager = SessionManager.makeForTesting(authenticated: true)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .switchingStores, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [firstSite, secondSite])

        // Then
        XCTAssertEqual(selectedSite, firstSite)
    }

    func test_siteToPreselect_when_switching_stores_has_only_non_woo_sites_then_returns_nil() {
        // Given
        let defaultSite = Site.fake().copy(siteID: 123, url: "https://store.example.com", isWooCommerceActive: true)
        let nonWooSite = Site.fake().copy(siteID: 456, url: "https://blog.example.com", isWooCommerceActive: false)
        let sessionManager = SessionManager.makeForTesting(defaultSite: defaultSite)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = StorePickerViewModel(configuration: .switchingStores, stores: stores, storageManager: storageManager)

        // When
        let selectedSite = viewModel.siteToPreselect(from: [nonWooSite])

        // Then
        XCTAssertNil(selectedSite)
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
            case let .synchronizeSites(_, onCompletion):
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
            case let .synchronizeSites(_, onCompletion):
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
            case let .synchronizeSites(_, onCompletion):
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
            case let .synchronizeSites(_, onCompletion):
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
            case let .synchronizeSites(_, onCompletion):
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
            case let .synchronizeSites(_, onCompletion):
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

    @MainActor
    func test_shouldEnableHidingStores_returns_false_if_feature_flag_is_disabled() async {
        // Given
        let featureFlagService = MockFeatureFlagService(hideSitesInStorePicker: false)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = StorePickerViewModel(configuration: .switchingStores,
                                             stores: stores,
                                             storageManager: storageManager,
                                             featureFlagService: featureFlagService)

        // When
        await viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertFalse(viewModel.shouldEnableHidingStores)
    }

    @MainActor
    func test_shouldEnableHidingStores_returns_false_if_configuration_is_not_switchingStores() async {
        // Given
        let featureFlagService = MockFeatureFlagService(hideSitesInStorePicker: true)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = StorePickerViewModel(configuration: .standard,
                                             stores: stores,
                                             storageManager: storageManager,
                                             featureFlagService: featureFlagService)

        // When
        await viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertFalse(viewModel.shouldEnableHidingStores)
    }

    @MainActor
    func test_shouldEnableHidingStores_returns_false_if_there_is_only_one_fetched_store() async {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: testSite1)

        let featureFlagService = MockFeatureFlagService(hideSitesInStorePicker: true)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = StorePickerViewModel(configuration: .switchingStores,
                                             stores: stores,
                                             storageManager: storageManager,
                                             featureFlagService: featureFlagService)

        // When
        await viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertFalse(viewModel.shouldEnableHidingStores)
    }

    @MainActor
    func test_shouldEnableHidingStores_returns_true_with_enabled_feature_flag_and_switchingStore_config_and_more_than_one_fetched_store() async {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 124, name: "def", isWooCommerceActive: true)
        let testSite3 = Site.fake().copy(siteID: 055, name: "hello", isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        storageManager.insertSampleSite(readOnlySite: testSite3)

        let featureFlagService = MockFeatureFlagService(hideSitesInStorePicker: true)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = StorePickerViewModel(configuration: .switchingStores,
                                             stores: stores,
                                             storageManager: storageManager,
                                             featureFlagService: featureFlagService)

        // When
        await viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertTrue(viewModel.shouldEnableHidingStores)
    }

    @MainActor
    func test_displayedStores_filters_out_hidden_stores() async throws {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 124, name: "def", isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let viewModel = StorePickerViewModel(configuration: .switchingStores,
                                             stores: stores,
                                             storageManager: storageManager,
                                             userDefaults: userDefaults)

        // When
        userDefaults.saveHiddenStoreIDs([testSite1.siteID])
        await viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertEqual(viewModel.displayedStores, [testSite2])
    }

    @MainActor
    func test_unhideStoreIfNeeded_removes_store_from_hidden_list_and_updates_displayedStores() async throws {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123, name: "abc", isWooCommerceActive: true)
        let testSite2 = Site.fake().copy(siteID: 124, name: "def", isWooCommerceActive: true)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        userDefaults.saveHiddenStoreIDs([testSite1.siteID])

        let viewModel = StorePickerViewModel(configuration: .switchingStores,
                                             stores: stores,
                                             storageManager: storageManager,
                                             userDefaults: userDefaults)
        await viewModel.refreshSites(currentlySelectedSiteID: nil)
        XCTAssertEqual(viewModel.displayedStores, [testSite2])

        // When
        viewModel.unhideStoreIfNeeded(testSite1.siteID)

        // Then
        XCTAssertTrue(userDefaults.hiddenStoreIDs.isEmpty)
        XCTAssertEqual(viewModel.displayedStores, [testSite1, testSite2])
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

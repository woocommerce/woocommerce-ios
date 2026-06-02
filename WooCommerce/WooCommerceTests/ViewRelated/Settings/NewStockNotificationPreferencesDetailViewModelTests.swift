import Foundation
import Testing
import Yosemite
import YosemiteTestHelpers
import protocol Storage.StorageManagerType
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct NewStockNotificationPreferencesDetailViewModelTests {

    private static let siteID: Int64 = 123
    private static let lowStockSettingID = "woocommerce_notify_low_stock_amount"

    // MARK: - Low stock threshold: initial state

    @Test func test_initial_lowStockThresholdState_when_cached_value_present_then_publishes_value() async {
        // Given
        let storageManager = MockStorageManager()
        await insertLowStock(value: "5", into: storageManager)

        // When
        let sut = makeSUT(storageManager: storageManager)

        // Then
        #expect(sut.lowStockThresholdState == .value(5))
    }

    @Test func test_initial_lowStockThresholdState_when_no_cached_value_then_is_loading() {
        // Given / When
        let sut = makeSUT(storageManager: MockStorageManager())

        // Then
        #expect(sut.lowStockThresholdState == .loading)
    }

    @Test func test_initial_lowStockThresholdState_when_setting_value_is_not_int_then_is_value_nil() async {
        // Given
        let storageManager = MockStorageManager()
        await insertLowStock(value: "abc", into: storageManager)

        // When
        let sut = makeSUT(storageManager: storageManager)

        // Then
        #expect(sut.lowStockThresholdState == .value(nil))
    }

    // MARK: - Low stock threshold: refresh

    @Test func test_refreshLowStockThreshold_when_sync_succeeds_with_no_cache_then_state_is_value_nil() async {
        // Given
        let stores = makeStores()
        stubSyncProductSettings(stores, result: nil)
        let sut = makeSUT(stores: stores)

        // When
        await sut.refreshLowStockThreshold()

        // Then
        #expect(sut.lowStockThresholdState == .value(nil))
    }

    @Test func test_refreshLowStockThreshold_when_sync_fails_with_cached_value_then_state_falls_back_to_cache() async {
        // Given
        let storageManager = MockStorageManager()
        await insertLowStock(value: "7", into: storageManager)
        let stores = makeStores()
        stubSyncProductSettings(stores, result: SyncError.network)
        let sut = makeSUT(stores: stores, storageManager: storageManager)

        // When
        await sut.refreshLowStockThreshold()

        // Then
        #expect(sut.lowStockThresholdState == .value(7))
    }

    @Test func test_refreshLowStockThreshold_when_sync_fails_with_no_cache_then_state_is_value_nil() async {
        // Given
        let stores = makeStores()
        stubSyncProductSettings(stores, result: SyncError.network)
        let sut = makeSUT(stores: stores)

        // When
        await sut.refreshLowStockThreshold()

        // Then
        #expect(sut.lowStockThresholdState == .value(nil))
    }

    // MARK: - Low stock threshold: predicate tightness + reactive updates

    @Test func test_storage_write_to_another_settingID_does_not_change_lowStockThresholdState() async {
        // Given
        let storageManager = MockStorageManager()
        let sut = makeSUT(storageManager: storageManager)
        #expect(sut.lowStockThresholdState == .loading)

        // When — write an unrelated setting.
        await insert(settingID: "woocommerce_currency", value: "USD", into: storageManager)

        // Then
        #expect(sut.lowStockThresholdState == .loading)
    }

    @Test func test_storage_update_to_low_stock_setting_after_load_propagates_to_state() async {
        // Given
        let storageManager = MockStorageManager()
        await insertLowStock(value: "3", into: storageManager)
        let sut = makeSUT(storageManager: storageManager)
        #expect(sut.lowStockThresholdState == .value(3))

        // When — webview edit results in the store-wide value being updated.
        await insertLowStock(value: "12", into: storageManager)

        // Then
        #expect(sut.lowStockThresholdState == .value(12))
    }

    // MARK: - editStoreWideThresholdURL

    @Test func test_editStoreWideThresholdURL_when_admin_url_present_then_returns_inventory_wp_admin_url() {
        // Given
        let sut = makeSUT(siteAdminURL: URL(string: "https://example.test/wp-admin/"))

        // When / Then
        #expect(sut.editStoreWideThresholdURL?.absoluteString ==
                "https://example.test/wp-admin/admin.php?page=wc-settings&tab=products&section=inventory")
    }

    @Test func test_editStoreWideThresholdURL_when_no_admin_url_then_is_nil() {
        // Given
        let sut = makeSUT(siteAdminURL: nil)

        // When / Then
        #expect(sut.editStoreWideThresholdURL == nil)
    }
}

// MARK: - Helpers

private extension NewStockNotificationPreferencesDetailViewModelTests {
    enum SyncError: Error { case network }

    func makeStores() -> MockStoresManager {
        MockStoresManager(sessionManager: .testingInstance)
    }

    func makeSUT(stores: MockStoresManager? = nil,
                 storageManager: MockStorageManager = MockStorageManager(),
                 siteAdminURL: URL? = URL(string: "https://example.test/wp-admin/"))
    -> NewStockNotificationPreferencesDetailViewModel {
        NewStockNotificationPreferencesDetailViewModel(
            siteID: Self.siteID,
            siteAdminURL: siteAdminURL,
            stores: stores ?? makeStores(),
            storageManager: storageManager)
    }

    func stubSyncProductSettings(_ stores: MockStoresManager, result error: Error?) {
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case let .synchronizeProductSiteSettings(_, onCompletion) = action {
                onCompletion(error)
            }
        }
    }

    func insertLowStock(value: String, into storageManager: MockStorageManager) async {
        await insert(settingID: Self.lowStockSettingID, value: value, into: storageManager)
    }

    func insert(settingID: String, value: String, into storageManager: MockStorageManager) async {
        let setting = SiteSetting.fake().copy(siteID: Self.siteID,
                                              settingID: settingID,
                                              value: value,
                                              settingGroupKey: SiteSettingGroup.product.rawValue)
        await withCheckedContinuation { continuation in
            storageManager.performAndSave({ [storageManager] _ in
                if let existing = storageManager.viewStorage
                    .loadSiteSetting(siteID: Self.siteID, settingID: settingID) {
                    storageManager.viewStorage.deleteObject(existing)
                }
                storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }
}

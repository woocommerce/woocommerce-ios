import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class DefaultStoreCreationStoreSwitchSchedulerTests: XCTestCase {
    func test_isPendingStoreSwitch_is_true_when_there_is_a_pending_store_switch() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults)
        // When
        sut.savePendingStoreSwitch(siteID: 123, expectedStoreName: "My Woo store")

        // Then
        XCTAssertTrue(sut.isPendingStoreSwitch)
    }

    func test_isPendingStoreSwitch_is_false_when_there_is_no_pending_store_switch() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults)

        // Then
        XCTAssertFalse(sut.isPendingStoreSwitch)
    }

    func test_isPendingStoreSwitch_is_false_if_store_already_switched() async throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, name: "My Woo store")
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.updateDefaultStore(storeID: testSite.siteID)
        stores.updateDefaultStore(testSite)
        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults)

        // Then
        XCTAssertFalse(sut.isPendingStoreSwitch)
    }

    func test_removePendingStoreSwitch_clears_pending_store_switch_info() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults)
        sut.savePendingStoreSwitch(siteID: 123, expectedStoreName: "My Woo store")

        // When
        sut.removePendingStoreSwitch()

        // Then
        XCTAssertFalse(sut.isPendingStoreSwitch)
    }

    func test_waitUntilStoreIsReady_returns_nil_when_there_is_no_pending_store_switch() async throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults)

        // When
        let siteID = try await sut.listenToPendingStoreAndReturnSiteIDOnceReady()

        // Then
        XCTAssertNil(siteID)
    }

    func test_waitUntilStoreIsReady_returns_site_once_ready() async throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())

        let sut = DefaultStoreCreationStoreSwitchScheduler(stores: stores,
                                                           userDefaults: userDefaults,
                                                           jetpackCheckRetryInterval: 0.1)
        sut.savePendingStoreSwitch(siteID: 123, expectedStoreName: "My Woo store")

        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            let site: Site = .fake().copy(siteID: 123,
                                          name: "My Woo store",
                                          isJetpackThePluginInstalled: true,
                                          isJetpackConnected: true,
                                          isWooCommerceActive: true,
                                          isWordPressComStore: true)

            guard case let .syncSite(_, completion) = action else {
                return
            }
            completion(.success(site))
        }

        // When
        let siteID = try await sut.listenToPendingStoreAndReturnSiteIDOnceReady()

        // Then
        XCTAssertEqual(siteID, 123)
    }
}

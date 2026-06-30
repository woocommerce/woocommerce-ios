import XCTest
import YosemiteTestHelpers
@testable import Networking
@testable import Yosemite

final class FeatureFlagStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses.
    private var network: MockNetwork!

    private var remote: MockFeatureFlagRemote!
    private var store: FeatureFlagStore!
    private var currentDate: Date!
    private var currentSiteID: Int64?
    private var activePluginVersions: [String: String]!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockFeatureFlagRemote()
        currentDate = Date()
        currentSiteID = nil
        activePluginVersions = [:]
        store = FeatureFlagStore(dispatcher: dispatcher,
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote,
                                 currentDate: { self.currentDate },
                                 currentSiteIDProvider: { self.currentSiteID },
                                 activePluginVersionsProvider: { _ in self.activePluginVersions })
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        currentDate = nil
        currentSiteID = nil
        activePluginVersions = nil
        super.tearDown()
    }

    func test_isRemoteFeatureFlagEnabled_returns_value_from_remote_on_success() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_isRemoteFeatureFlagEnabled_returns_default_value_on_failure() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .failure(NetworkError.timeout()))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_isRemoteFeatureFlagEnabled_when_useCache_is_true_returns_cached_value_without_remote_call() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // First call to populate the cache
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { _ in
                    promise(())
                })
        }

        // Change the remote response to verify cache is used
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }

        // Then - should return cached value (true), not the new remote value (false)
        XCTAssertTrue(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 1)
    }

    func test_isRemoteFeatureFlagEnabled_when_useCache_is_false_fetches_from_remote() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // First call to populate the cache
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { _ in
                    promise(())
                })
        }

        // Change the remote response
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When - use useCache: false to force remote fetch
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: false) { result in
                    promise(result)
                })
        }

        // Then - should return the new remote value (false)
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 2)
    }

    func test_isRemoteFeatureFlagEnabled_when_cache_is_expired_fetches_from_remote() throws {
        // Given
        let cacheMaxAge: TimeInterval = 24 * 60 * 60
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // First call to populate the cache
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { _ in
                    promise(())
                })
        }

        // Advance time past the 24-hour limit
        currentDate = currentDate.addingTimeInterval(cacheMaxAge + 1)

        // Change the remote response
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When - useCache is true but cache is expired
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: true) { result in
                    promise(result)
                })
        }

        // Then - should fetch from remote and return the new value (false)
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 2)
    }

    func test_isRemoteFeatureFlagEnabled_when_site_changes_does_not_return_previous_site_cached_value() throws {
        // Given
        currentSiteID = 1
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))
        let firstSiteValue = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }
        XCTAssertTrue(firstSiteValue)

        // When
        currentSiteID = 2
        remote.whenLoadingAllFeatureFlags(thenReturn: .failure(NetworkError.timeout()))
        let secondSiteValue = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(secondSiteValue)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 2)
    }

    func test_isRemoteFeatureFlagEnabled_when_active_plugin_versions_change_uses_separate_cache_context() throws {
        // Given
        currentSiteID = 1
        activePluginVersions = ["woocommerce/woocommerce.php": "10.9.2"]
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))
        let firstVersionValue = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }
        XCTAssertTrue(firstVersionValue)

        // When
        activePluginVersions = ["woocommerce/woocommerce.php": "9.9.0"]
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))
        let secondVersionValue = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: true) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(secondVersionValue)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 2)
        XCTAssertEqual(remote.activePluginVersions, [
            ["woocommerce/woocommerce.php": "10.9.2"],
            ["woocommerce/woocommerce.php": "9.9.0"]
        ])
    }

    func test_refreshRemoteFeatureFlags_with_empty_plugin_versions_keeps_selected_site_context_empty_for_lazy_reads() throws {
        // Given
        currentSiteID = 1
        activePluginVersions = ["woocommerce/woocommerce.php": "10.9.2"]
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .refreshRemoteFeatureFlags(siteID: 1, activePluginVersions: [:]) { result in
                    if case let .failure(error) = result {
                        XCTFail("Expected refresh to succeed, received \(error)")
                    }
                    promise(())
                })
        }

        // When
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: true) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 1)
        XCTAssertEqual(remote.activePluginVersions, [[:]])
    }

    func test_isRemoteFeatureFlagEnabled_when_cache_is_not_expired_returns_cached_value() throws {
        // Given
        let cacheMaxAge: TimeInterval = 24 * 60 * 60
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // First call to populate the cache
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { _ in
                    promise(())
                })
        }

        // Advance time but stay within the 24-hour limit
        currentDate = currentDate.addingTimeInterval(cacheMaxAge - 1)

        // Change the remote response
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { result in
                    promise(result)
                })
        }

        // Then - should return cached value (true), not the new remote value (false)
        XCTAssertTrue(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 1)
    }

    func test_isRemoteFeatureFlagEnabled_when_useCache_is_false_updates_cache() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // First call to populate the cache
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: true) { _ in
                    promise(())
                })
        }

        // Change the remote response and fetch with useCache: false
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))
        waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: false) { _ in
                    promise(())
                })
        }

        // When - fetch with useCache: true, should use updated cache
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: true, useCache: true) { result in
                    promise(result)
                })
        }

        // Then - should return the updated cached value (false)
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(remote.loadAllFeatureFlagsCallCount, 2)
    }
}

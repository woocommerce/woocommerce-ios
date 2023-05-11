import XCTest
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

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockFeatureFlagRemote()
        store = FeatureFlagStore(dispatcher: dispatcher,
                                 storageManager: storageManager,
                                 network: network,
                                 remote: remote)
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    func test_isRemoteFeatureFlagEnabled_returns_value_from_remote_on_success() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_isRemoteFeatureFlagEnabled_returns_default_value_on_failure() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .failure(NetworkError.timeout))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.storeCreationCompleteNotification, defaultValue: false) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_isRemoteFeatureFlagEnabled_returns_default_value_when_remote_response_does_not_include_input_flag() throws {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // When
        let isEnabled = waitFor { promise in
            self.store.onAction(FeatureFlagAction
                .isRemoteFeatureFlagEnabled(.oneDayAfterFreeTrialExpiresNotification, defaultValue: false) { result in
                    promise(result)
                })
        }

        // Then
        XCTAssertFalse(isEnabled)
    }
}

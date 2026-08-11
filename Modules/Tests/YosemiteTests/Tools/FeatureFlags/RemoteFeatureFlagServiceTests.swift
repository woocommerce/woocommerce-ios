import Testing
import YosemiteTestHelpers
@testable import Networking
@testable import Yosemite

/// RemoteFeatureFlagService Unit Tests
///
/// The service is wired to a real `FeatureFlagStore` so the async interface is verified
/// against the actual resolution behavior (cache → network → default on failure).
///
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct RemoteFeatureFlagServiceTests {
    private let remote: MockFeatureFlagRemote
    private let service: RemoteFeatureFlagService

    init() {
        let remote = MockFeatureFlagRemote()
        let store = FeatureFlagStore(dispatcher: Dispatcher(),
                                     storageManager: MockStorageManager(),
                                     network: MockNetwork(),
                                     remote: remote)
        self.remote = remote
        self.service = RemoteFeatureFlagService(dispatch: { store.onAction($0) })
    }

    @Test func test_isEnabled_when_remote_returns_value_then_returns_remote_value() async {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))

        // When
        let isEnabled = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: false)

        // Then
        #expect(isEnabled == true)
    }

    @Test func test_isEnabled_when_remote_fails_then_returns_default_value() async {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .failure(NetworkError.timeout()))

        // When
        let isEnabled = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: true)

        // Then
        #expect(isEnabled == true)
    }

    @Test func test_isEnabled_when_called_twice_then_reuses_cached_value() async {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))
        _ = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: false)
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When
        let isEnabled = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: false)

        // Then
        #expect(isEnabled == true)
        #expect(remote.loadAllFeatureFlagsCallCount == 1)
    }

    @Test func test_isEnabled_when_useCache_is_false_then_fetches_from_remote() async {
        // Given
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: true]))
        _ = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: false)
        remote.whenLoadingAllFeatureFlags(thenReturn: .success([.storeCreationCompleteNotification: false]))

        // When
        let isEnabled = await service.isEnabled(.storeCreationCompleteNotification, defaultValue: false, useCache: false)

        // Then
        #expect(isEnabled == false)
        #expect(remote.loadAllFeatureFlagsCallCount == 2)
    }
}

import Testing
import Yosemite
@testable import WooCommerce

/// RemoteFeatureFlagService Unit Tests
///
/// The service is a thin async bridge over `FeatureFlagAction` dispatch, so these tests verify
/// the wrapper contract: parameter forwarding and completion bridging. The resolution behavior
/// (override store → cache → network → default) is covered by `FeatureFlagStoreTests`.
///
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct RemoteFeatureFlagServiceTests {
    private let stores: MockStoresManager
    private let service: RemoteFeatureFlagService

    init() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        service = RemoteFeatureFlagService(stores: stores)
    }

    @Test func test_isEnabled_when_dispatching_then_forwards_flag_defaultValue_and_useCache() async {
        // Given
        var received: (featureFlag: RemoteFeatureFlag, defaultValue: Bool, useCache: Bool)?
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(featureFlag, defaultValue, useCache, completion) = action {
                received = (featureFlag, defaultValue, useCache)
                completion(false)
            }
        }

        // When
        _ = await service.isEnabled(.pointOfSale, defaultValue: true, useCache: false)

        // Then
        #expect(received?.featureFlag == .pointOfSale)
        #expect(received?.defaultValue == true)
        #expect(received?.useCache == false)
    }

    @Test func test_isEnabled_when_useCache_is_not_specified_then_uses_cache() async {
        // Given
        var receivedUseCache: Bool?
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(_, _, useCache, completion) = action {
                receivedUseCache = useCache
                completion(false)
            }
        }

        // When
        _ = await service.isEnabled(.pointOfSale, defaultValue: false)

        // Then
        #expect(receivedUseCache == true)
    }

    @Test func test_isEnabled_when_store_resolves_flag_then_returns_resolved_value() async {
        // Given
        stores.resolveRemoteFeatureFlag(returning: true)

        // When
        let isEnabled = await service.isEnabled(.pointOfSale, defaultValue: false)

        // Then
        #expect(isEnabled == true)
    }
}

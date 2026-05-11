import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class WooPushNotificationEligibilityCheckTests: XCTestCase {
    private var storesManager: MockStoresManager!
    private var featureFlagService: MockFeatureFlagService!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .testingInstance)
        featureFlagService = MockFeatureFlagService()
    }

    override func tearDown() {
        storesManager = nil
        featureFlagService = nil
        super.tearDown()
    }

    // MARK: - checkEligibility

    func test_checkEligibility_returns_true_when_both_local_and_remote_flags_are_enabled() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: true)

        // When
        let result = await checker.checkEligibility()

        // Then
        XCTAssertTrue(result)
    }

    func test_checkEligibility_returns_false_when_remote_flag_is_disabled() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: false)

        // When
        let result = await checker.checkEligibility()

        // Then
        XCTAssertFalse(result)
    }

    func test_checkEligibility_returns_false_when_local_flag_is_disabled() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushToken: false)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: true)

        // When
        let result = await checker.checkEligibility()

        // Then
        XCTAssertFalse(result)
    }

    func test_checkEligibility_returns_false_when_both_flags_are_disabled() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushToken: false)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: false)

        // When
        let result = await checker.checkEligibility()

        // Then
        XCTAssertFalse(result)
    }

    func test_checkEligibility_passes_false_as_default_value() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )

        var capturedDefaultValue: Bool?
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, defaultValue, _, completion):
                capturedDefaultValue = defaultValue
                completion(true)
            }
        }

        // When
        _ = await checker.checkEligibility()

        // Then
        XCTAssertEqual(capturedDefaultValue, false)
    }

    func test_checkEligibility_passes_correct_remote_feature_flag_key() async {
        // Given
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )

        var capturedFeatureFlag: RemoteFeatureFlag?
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(featureFlag, _, _, completion):
                capturedFeatureFlag = featureFlag
                completion(false)
            }
        }

        // When
        _ = await checker.checkEligibility()

        // Then
        XCTAssertEqual(capturedFeatureFlag, .selfDrivenPushNotificationsM1)
    }

    func test_checkEligibility_uses_cache() async {
        // Given
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )

        var capturedUseCache: Bool?
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, useCache, completion):
                capturedUseCache = useCache
                completion(false)
            }
        }

        // When
        _ = await checker.checkEligibility()

        // Then
        XCTAssertEqual(capturedUseCache, true)
    }
}

// MARK: - Helpers

private extension WooPushNotificationEligibilityCheckTests {
    func mockRemoteFeatureFlagAction(isEnabled: Bool) {
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, completion):
                completion(isEnabled)
            }
        }
    }
}

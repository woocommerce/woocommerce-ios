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

    // MARK: - checkM1Eligibility

    func test_checkM1Eligibility_returns_true_when_remote_flag_is_enabled() async {
        // Given
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: true)

        // When
        let result = await checker.checkM1Eligibility()

        // Then
        XCTAssertTrue(result)
    }

    func test_checkM1Eligibility_returns_false_when_remote_flag_is_disabled() async {
        // Given
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )
        mockRemoteFeatureFlagAction(isEnabled: false)

        // When
        let result = await checker.checkM1Eligibility()

        // Then
        XCTAssertFalse(result)
    }

    func test_checkM1Eligibility_passes_local_feature_flag_as_default_value() async {
        // Given
        featureFlagService = MockFeatureFlagService(selfDrivenPushTokenWPCom: true)
        let checker = WooPushNotificationEligibilityCheck(
            featureFlagService: featureFlagService,
            stores: storesManager
        )

        var capturedDefaultValue: Bool?
        storesManager.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, defaultValue, _, completion):
                capturedDefaultValue = defaultValue
                completion(defaultValue)
            }
        }

        // When
        _ = await checker.checkM1Eligibility()

        // Then
        XCTAssertEqual(capturedDefaultValue, true)
    }

    func test_checkM1Eligibility_passes_correct_remote_feature_flag_key() async {
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
        _ = await checker.checkM1Eligibility()

        // Then
        XCTAssertEqual(capturedFeatureFlag, .selfDrivenPushNotificationsM1)
    }

    func test_checkM1Eligibility_uses_cache() async {
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
        _ = await checker.checkM1Eligibility()

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

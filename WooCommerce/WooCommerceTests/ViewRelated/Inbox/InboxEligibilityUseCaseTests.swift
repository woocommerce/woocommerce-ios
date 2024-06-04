import XCTest
@testable import WooCommerce
import Yosemite

final class InboxEligibilityUseCaseTests: XCTestCase {

    @MainActor
    func test_async_isEligibleForInbox_returns_true_if_stored_woo_plugin_is_found_and_version_is_eligible_and_feature_flag_is_on() async {
        // Given
        let siteID: Int64 = 132
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = InboxEligibilityUseCase(stores: stores, featureFlagService: featureFlagService)

        var triggeredSyncingSystemInformation = false

        // When
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(SystemPlugin.fake().copy(siteID: siteID, name: "WooCommerce", version: "6.0.0", active: true))
            case .synchronizeSystemInformation:
                triggeredSyncingSystemInformation = true
            default:
                break
            }
        }
        let result = await useCase.isEligibleForInbox(siteID: siteID)

        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(triggeredSyncingSystemInformation)
    }

    @MainActor
    func test_async_isEligibleForInbox_returns_true_if_remote_woo_plugin_is_found_and_version_is_eligible_and_feature_flag_is_on() async {
        // Given
        let siteID: Int64 = 132
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = InboxEligibilityUseCase(stores: stores, featureFlagService: featureFlagService)

        var triggeredSyncingSystemInformation = false

        // When
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(nil)
            case let .synchronizeSystemInformation(_, onCompletion):
                let wooPlugin = SystemPlugin.fake().copy(siteID: siteID, name: "WooCommerce", version: "6.0.0", active: true)
                let systemInfo = SystemInformation.fake().copy(systemPlugins: [wooPlugin])
                triggeredSyncingSystemInformation = true
                onCompletion(.success(systemInfo))
            default:
                break
            }
        }
        let result = await useCase.isEligibleForInbox(siteID: siteID)

        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(triggeredSyncingSystemInformation)
    }

    @MainActor
    func test_async_isEligibleForInbox_returns_false_if_stored_woo_plugin_is_found_and_version_is_eligible_and_feature_flag_is_off() async {
        // Given
        let siteID: Int64 = 132
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = InboxEligibilityUseCase(stores: stores, featureFlagService: featureFlagService)

        var triggeredSyncingSystemInformation = false

        // When
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(SystemPlugin.fake().copy(siteID: siteID, name: "WooCommerce", version: "6.0.0"))
            case .synchronizeSystemInformation:
                triggeredSyncingSystemInformation = true
            default:
                break
            }
        }
        let result = await useCase.isEligibleForInbox(siteID: siteID)

        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(triggeredSyncingSystemInformation)
    }

    @MainActor
    func test_async_isEligibleForInbox_returns_false_if_stored_woo_plugin_is_found_and_version_is_ineligible_and_feature_flag_is_on() async {
        // Given
        let siteID: Int64 = 132
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = InboxEligibilityUseCase(stores: stores, featureFlagService: featureFlagService)

        var triggeredSyncingSystemInformation = false

        // When
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(SystemPlugin.fake().copy(siteID: siteID, name: "WooCommerce", version: "4.5.0"))
            case .synchronizeSystemInformation:
                triggeredSyncingSystemInformation = true
            default:
                break
            }
        }
        let result = await useCase.isEligibleForInbox(siteID: siteID)

        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(triggeredSyncingSystemInformation)
    }
}

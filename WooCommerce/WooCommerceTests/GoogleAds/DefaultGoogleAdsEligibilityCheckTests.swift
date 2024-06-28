import XCTest
import Yosemite
@testable import WooCommerce

final class DefaultGoogleAdsEligibilityCheckerTests: XCTestCase {

    @MainActor
    func test_isSiteEligible_returns_false_if_feature_flag_is_disabled() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: false)
        let checker = DefaultGoogleAdsEligibilityChecker(featureFlagService: featureFlagService)

        // When
        let result = await checker.isSiteEligible(siteID: 123)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_plugin_is_not_installed() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = DefaultGoogleAdsEligibilityChecker(featureFlagService: featureFlagService)

        // When
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                let systemInfo = SystemInformation.fake().copy(systemPlugins: [])
                onCompletion(.success(systemInfo))
            case let .fetchSystemPluginWithPath(_, _, onCompletion):
                onCompletion(nil)
            default:
                break
            }
        }
        let result = await checker.isSiteEligible(siteID: 123)

        // Then
        XCTAssertFalse(result)
    }
}

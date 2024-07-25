import XCTest
import Yosemite
@testable import WooCommerce

final class DefaultGoogleAdsEligibilityCheckerTests: XCTestCase {
    private let sampleSite: Int64 = 325
    private let pluginSlug = "google-listings-and-ads/google-listings-and-ads.php"

    private var stores: MockStoresManager!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        super.setUp()
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_feature_flag_is_disabled() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: false)
        let checker = DefaultGoogleAdsEligibilityChecker(featureFlagService: featureFlagService)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_checking_connection_fails() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "incomplete")
        mockRequests(adsConnection: nil)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_google_ads_account_is_not_connected() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "incomplete")
        mockRequests(adsConnection: connection)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_plugin_version_is_not_satisfied() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let plugin = SystemPlugin.fake().copy(siteID: sampleSite,
                                              plugin: pluginSlug,
                                              version: "2.7.6",
                                              active: true)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "connected")
        mockRequests(syncedPlugins: [plugin], adsConnection: connection)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_true_if_plugin_is_satisfied_and_ads_account_is_connected() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let plugin = SystemPlugin.fake().copy(siteID: sampleSite,
                                              plugin: pluginSlug,
                                              version: "2.7.7",
                                              active: true)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "connected")
        mockRequests(syncedPlugins: [plugin], adsConnection: connection)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertTrue(result)
    }
}

// MARK: - Helpers
private extension DefaultGoogleAdsEligibilityCheckerTests {
    func mockRequests(syncedPlugins: [SystemPlugin] = [],
                      adsConnection: GoogleAdsConnection? = nil) {
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                let systemInfo = SystemInformation.fake().copy(systemPlugins: syncedPlugins)
                onCompletion(.success(systemInfo))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .checkConnection(_, onCompletion):
                if let adsConnection {
                    onCompletion(.success(adsConnection))
                } else {
                    onCompletion(.failure(NSError(domain: "Test", code: 404)))
                }
            default:
                break
            }
        }
    }
}

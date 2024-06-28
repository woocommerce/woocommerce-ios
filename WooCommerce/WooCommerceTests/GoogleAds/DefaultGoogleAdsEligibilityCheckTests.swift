import XCTest
import Yosemite
@testable import WooCommerce

final class DefaultGoogleAdsEligibilityCheckerTests: XCTestCase {
    private let sampleSite: Int64 = 325
    private let pluginSlug = "google-listings-and-ads/google-listings-and-ads"

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
    func test_isSiteEligible_returns_false_if_plugin_is_not_installed() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        mockRequests(syncedPlugins: [], fetchedPluginWithPath: nil)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_plugin_is_not_active() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let plugin = SystemPlugin.fake().copy(siteID: sampleSite,
                                              plugin: pluginSlug,
                                              active: false)
        mockRequests(syncedPlugins: [plugin])

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_plugin_is_active_but_has_older_version() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let plugin = SystemPlugin.fake().copy(siteID: sampleSite,
                                              plugin: pluginSlug,
                                              version: "2.7.4",
                                              active: true)
        mockRequests(fetchedPluginWithPath: plugin)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertFalse(result)
    }

    @MainActor
    func test_isSiteEligible_returns_false_if_plugin_is_satisfied_but_connection_is_not() async {
        // Given
        let featureFlagService = MockFeatureFlagService(googleAdsCampaignCreationOnWebView: true)
        let checker = DefaultGoogleAdsEligibilityChecker(stores: stores, featureFlagService: featureFlagService)
        let plugin = SystemPlugin.fake().copy(siteID: sampleSite,
                                              plugin: pluginSlug,
                                              version: "2.7.5",
                                              active: true)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "incomplete")
        mockRequests(fetchedPluginWithPath: plugin, adsConnection: connection)

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
                                              version: "2.7.5",
                                              active: true)
        let connection = GoogleAdsConnection.fake().copy(rawStatus: "connected")
        mockRequests(fetchedPluginWithPath: plugin, adsConnection: connection)

        // When
        let result = await checker.isSiteEligible(siteID: sampleSite)

        // Then
        XCTAssertTrue(result)
    }
}

// MARK: - Helpers
private extension DefaultGoogleAdsEligibilityCheckerTests {
    func mockRequests(syncedPlugins: [SystemPlugin] = [],
                      fetchedPluginWithPath: SystemPlugin? = nil,
                      adsConnection: GoogleAdsConnection? = nil) {
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                let systemInfo = SystemInformation.fake().copy(systemPlugins: syncedPlugins)
                onCompletion(.success(systemInfo))
            case let .fetchSystemPluginWithPath(_, _, onCompletion):
                onCompletion(fetchedPluginWithPath)
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

import XCTest
import Combine
import Fakes
import UIKit
@testable import WooCommerce
@testable import Yosemite
import enum Networking.RemoteFeatureFlag

@MainActor
final class ClientSideBannerProviderTests: XCTestCase {

    private let testSiteID: Int64 = 123
    private var stores: MockStoresManager!
    private var analytics: MockAnalyticsProvider!
    private var featureFlagService: MockFeatureFlagService!
    private var siteSettings: MockSelectedSiteSettings!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        analytics = MockAnalyticsProvider()
        featureFlagService = MockFeatureFlagService()
        siteSettings = MockSelectedSiteSettings()

        // Set up mock handlers for actions dispatched during the provider's operations
        setUpBasicMocks()
    }

    override func tearDown() {
        stores = nil
        analytics = nil
        featureFlagService = nil
        siteSettings = nil
        super.tearDown()
    }

    private func setUpBasicMocks() {
        // Default: remote feature flag disabled
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, onCompletion):
                onCompletion(false)
            }
        }

        // Default: banner not dismissed (visible)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getFeatureAnnouncementVisibility(_, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
    }

    // MARK: - Device Type Tests

    func test_loadBanner_returns_nil_on_iPad() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        let sut = makeSUT(userInterfaceIdiom: .pad)

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown on iPad")
    }

    // MARK: - Connection Type Tests

    func test_loadBanner_returns_nil_for_fullJetpack_site() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown for full Jetpack sites")
    }

    func test_loadBanner_returns_nil_for_jetpackConnectionPackage_site() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown for JCP sites")
    }

    // MARK: - Feature Flag Tests

    func test_loadBanner_returns_nil_when_local_feature_flag_disabled() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = false
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown when local feature flag is disabled")
    }

    func test_loadBanner_returns_nil_when_remote_feature_flag_disabled() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        // Remote flag is disabled by default in setUpBasicMocks()
        setUpUSCountrySettings()

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown when remote feature flag is disabled")
    }

    // MARK: - Country Targeting Tests

    func test_loadBanner_returns_nil_when_store_country_is_not_US_or_GB() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpCountrySettings(countryCode: "CA") // Canada

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown for stores outside US/GB")
    }

    func test_loadBanner_returns_banner_for_US_store() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNotNil(result, "Banner should be shown for non-Jetpack US stores with both flags enabled")
    }

    func test_loadBanner_returns_banner_for_GB_store() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpCountrySettings(countryCode: "GB")

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNotNil(result, "Banner should be shown for non-Jetpack GB stores with both flags enabled")
    }

    // MARK: - Dismissal Tests

    func test_loadBanner_returns_nil_when_banner_previously_dismissed() async {
        // Given
        let site = Site.fake().copy(siteID: testSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: false)
        featureFlagService.isFeatureFlagEnabledReturnValue[.clientSideDashboardBanner] = true
        enableRemoteFeatureFlag()
        setUpUSCountrySettings()

        // Override to return false (banner was dismissed)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getFeatureAnnouncementVisibility(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let sut = makeSUT()

        // When
        let result = await sut.loadBanner(for: site)

        // Then
        XCTAssertNil(result, "Banner should not be shown when previously dismissed")
    }

    // MARK: - Helpers

    private func makeSUT(userInterfaceIdiom: UIUserInterfaceIdiom = .phone) -> ClientSideBannerProvider {
        ClientSideBannerProvider(
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: analytics),
            featureFlagService: featureFlagService,
            siteSettings: siteSettings,
            userInterfaceIdiom: userInterfaceIdiom
        )
    }

    private func enableRemoteFeatureFlag() {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(flag, _, onCompletion):
                if flag == .wooPosTabletPromoBanner {
                    onCompletion(true)
                } else {
                    onCompletion(false)
                }
            }
        }
    }

    private func setUpUSCountrySettings() {
        setUpCountrySettings(countryCode: "US")
    }

    private func setUpCountrySettings(countryCode: String) {
        let countrySetting = SiteSetting.fake().copy(
            settingID: "woocommerce_default_country",
            value: countryCode
        )
        // Set the siteSettings property directly for the fast path
        siteSettings.siteSettings = [countrySetting]
        // Also set up the stream as a fallback
        siteSettings.mockSettingsStream = [
            (siteID: testSiteID, settings: [countrySetting], source: .refresh)
        ].publisher.eraseToAnyPublisher()
    }
}

import Foundation
import PointOfSale
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct POSTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var mockSystemStatusService: MockPOSSystemStatusService!
    private var mockSiteSettingService: MockPOSSiteSettingService!
    private let site = Site.fake().copy(siteID: 2)
    private var siteID: Int64 { site.siteID }

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        mockSystemStatusService = MockPOSSystemStatusService()
        mockSiteSettingService = MockPOSSiteSettingService()
        setupWooCommerceVersion()
    }

    // MARK: - `checkEligibility`

    @Test func is_eligible_when_plugin_version_is_above_minimum() async throws {
        // Given
        setupWooCommerceVersion("9.6.0")
        let checker = makeChecker()

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func is_eligible_when_plugin_version_is_well_above_minimum() async throws {
        // Given
        setupWooCommerceVersion("10.0.0")
        let checker = makeChecker()

        // When
        let result = await checker.checkEligibility()

        // Then — feature switch is no longer consulted, so a recent plugin is always eligible.
        #expect(result == .eligible)
    }

    @Test func is_ineligible_when_plugin_version_is_below_minimum() async throws {
        // Given
        setupWooCommerceVersion("9.5.0")
        let checker = makeChecker()

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    @Test func is_ineligible_when_plugin_not_found() async throws {
        // Given
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil))
        let checker = makeChecker()

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
    }

    @Test func is_ineligible_when_system_status_request_fails() async throws {
        // Given
        mockSystemStatusService.resultToReturn = .failure(NSError(domain: "test", code: 500))
        let checker = makeChecker()

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
    }

    // MARK: - `refreshEligibility`

    @Test func refreshEligibility_for_selfDeallocated_rechecks_eligibility() async throws {
        // Given
        setupWooCommerceVersion("9.6.0")
        let checker = makeChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .selfDeallocated)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_eligible_when_plugin_now_meets_requirements(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "9.9.9")
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))
        let checker = makeChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_ineligible_when_plugin_still_below_minimum(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "9.5.0")
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))
        let checker = makeChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }
}

// MARK: - Test Helpers

private extension POSTabEligibilityCheckerTests {
    func makeChecker() -> POSTabEligibilityChecker {
        POSTabEligibilityChecker(siteID: siteID,
                                 stores: stores,
                                 systemStatusService: mockSystemStatusService,
                                 siteSettingService: mockSiteSettingService)
    }

    func setupWooCommerceVersion(_ version: String = "9.6.0-beta") {
        let wcPlugin = createWooCommercePlugin(version: version)
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))
    }

    func createWooCommercePlugin(version: String) -> SystemPlugin {
        SystemPlugin.fake().copy(
            siteID: siteID,
            plugin: "woocommerce/woocommerce.php",
            version: version,
            active: true
        )
    }
}

private final class MockPOSSystemStatusService: POSSystemStatusServiceProtocol {
    var resultToReturn: Result<POSPluginAndFeatureInfo, Error> = .success(POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil))

    func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        switch resultToReturn {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}

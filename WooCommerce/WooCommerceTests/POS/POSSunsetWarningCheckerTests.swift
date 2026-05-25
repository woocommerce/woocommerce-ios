import Testing
import Foundation
@testable import WooCommerce
import Yosemite
import Storage
import Experiments

struct POSSunsetWarningCheckerTests {

    private let siteID: Int64 = 123

    // MARK: - Feature Flag

    @Test func shouldShowSunsetWarning_when_featureFlag_disabled_then_returns_false() async {
        // Given
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleCatalogAPI] = false
        let sut = makeSUT(featureFlagService: featureFlags)

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    // MARK: - Version Checks

    @Test func shouldShowSunsetWarning_when_version_below_minimum_then_returns_true() async {
        // Given
        let sut = makeSUT(wcVersion: "10.4.0")

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == true)
    }

    @Test func shouldShowSunsetWarning_when_version_meets_minimum_then_returns_false() async {
        // Given
        let sut = makeSUT(wcVersion: "10.5.0")

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowSunsetWarning_when_version_above_minimum_then_returns_false() async {
        // Given
        let sut = makeSUT(wcVersion: "11.0.0")

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowSunsetWarning_when_plugin_inactive_then_returns_false() async {
        // Given
        let sut = makeSUT(wcVersion: "10.4.0", pluginActive: false)

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowSunsetWarning_when_plugin_nil_then_returns_false() async {
        // Given
        let systemStatusService = MockPOSSystemStatusService()
        systemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil))
        let sut = makeSUT(systemStatusService: systemStatusService)

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowSunsetWarning_when_service_throws_then_returns_false() async {
        // Given
        let systemStatusService = MockPOSSystemStatusService()
        systemStatusService.resultToReturn = .failure(NSError(domain: "test", code: 1))
        let sut = makeSUT(systemStatusService: systemStatusService)

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    // MARK: - Dismissal Throttling

    @Test func shouldShowSunsetWarning_when_dismissed_within_14_days_then_returns_false() async {
        // Given
        let now = Date()
        let dismissedDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let siteSettings = MockSunsetSiteSettings(lastDismissedDate: dismissedDate)
        let sut = makeSUT(wcVersion: "10.4.0", siteSettings: siteSettings, currentDate: { now })

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == false)
    }

    @Test func shouldShowSunsetWarning_when_dismissed_over_14_days_ago_then_returns_true() async {
        // Given
        let now = Date()
        let dismissedDate = Calendar.current.date(byAdding: .day, value: -15, to: now)!
        let siteSettings = MockSunsetSiteSettings(lastDismissedDate: dismissedDate)
        let sut = makeSUT(wcVersion: "10.4.0", siteSettings: siteSettings, currentDate: { now })

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == true)
    }

    @Test func shouldShowSunsetWarning_when_never_dismissed_then_returns_true() async {
        // Given
        let siteSettings = MockSunsetSiteSettings(lastDismissedDate: nil)
        let sut = makeSUT(wcVersion: "10.4.0", siteSettings: siteSettings)

        // When
        let result = await sut.shouldShowSunsetWarning(siteID: siteID)

        // Then
        #expect(result == true)
    }

    // MARK: - Record Dismissal

    @Test func recordDismissal_persists_current_date() {
        // Given
        let now = Date()
        let siteSettings = MockSunsetSiteSettings()
        let sut = makeSUT(siteSettings: siteSettings, currentDate: { now })

        // When
        sut.recordDismissal(siteID: siteID)

        // Then
        #expect(siteSettings.lastDismissedDate == now)
        #expect(siteSettings.lastDismissedSiteID == siteID)
    }
}

// MARK: - Helpers

private extension POSSunsetWarningCheckerTests {
    func makeSUT(
        featureFlagService: MockFeatureFlagService? = nil,
        wcVersion: String = "10.4.0",
        pluginActive: Bool = true,
        systemStatusService: MockPOSSystemStatusService? = nil,
        siteSettings: MockSunsetSiteSettings = MockSunsetSiteSettings(),
        currentDate: @escaping () -> Date = { Date() }
    ) -> POSSunsetWarningChecker {
        let flags = featureFlagService ?? {
            let service = MockFeatureFlagService()
            service.isFeatureFlagEnabledReturnValue[.pointOfSaleCatalogAPI] = true
            return service
        }()

        let statusService = systemStatusService ?? {
            let service = MockPOSSystemStatusService()
            let plugin = SystemPlugin.fake().copy(version: wcVersion, active: pluginActive)
            service.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: plugin, featureValue: nil))
            return service
        }()

        return POSSunsetWarningChecker(
            featureFlagService: flags,
            systemStatusService: statusService,
            siteSettings: siteSettings,
            currentDate: currentDate
        )
    }
}

// MARK: - Mocks

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

private final class MockSunsetSiteSettings: SiteSpecificAppSettingsStoreMethodsProtocol {
    var lastDismissedDate: Date?
    var lastDismissedSiteID: Int64?

    init(lastDismissedDate: Date? = nil) {
        self.lastDismissedDate = lastDismissedDate
    }

    func getSunsetWarningLastDismissedDate(siteID: Int64) -> Date? {
        lastDismissedDate
    }

    func setSunsetWarningLastDismissedDate(siteID: Int64, date: Date) {
        lastDismissedSiteID = siteID
        lastDismissedDate = date
    }

    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings { .init() }
    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)?) {}
    func resetStoreSettings() {}
    func setStoreID(siteID: Int64, id: String?) {}
    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {}
    func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String] { [] }
    func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64) {}
    func getPOSLastOpenedDate(siteID: Int64) -> Date? { nil }
    func setPOSLastOpenedDate(siteID: Int64, date: Date) {}
    func getFirstPOSCatalogSyncDate(siteID: Int64) -> Date? { nil }
    func setFirstPOSCatalogSyncDate(siteID: Int64, date: Date) {}
    func setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool) {}
    func getPOSLocalCatalogCellularDataAllowed(siteID: Int64) -> Bool { false }
    func loadCardPresentPaymentsCountryExpansionEligibility(siteID: Int64) -> Bool? { nil }
    func saveCardPresentPaymentsCountryExpansionEligibility(siteID: Int64, isEligible: Bool) {}
}

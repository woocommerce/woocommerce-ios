import Testing
import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking

@MainActor
struct AnalyticsOrderDateTypeCacheTests {
    private let siteID: Int64 = 134

    @Test
    func cachedValue_when_no_setting_persisted_then_returns_nil() {
        // Given — empty storage.
        let storageManager = MockStorageManager()

        // When
        let cached = AnalyticsOrderDateType.cachedValue(siteID: siteID, storageManager: storageManager)

        // Then
        #expect(cached == nil)
    }

    @Test
    func cachedValue_when_setting_persisted_then_returns_matching_case() {
        // Given
        let storageManager = MockStorageManager()
        let stored = SiteSetting.fake().copy(siteID: siteID,
                                             settingID: "woocommerce_date_type",
                                             value: AnalyticsOrderDateType.completed.rawValue,
                                             settingGroupKey: "wc_admin")
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: stored)

        // When
        let cached = AnalyticsOrderDateType.cachedValue(siteID: siteID, storageManager: storageManager)

        // Then
        #expect(cached == .completed)
    }

    @Test
    func cachedValue_when_persisted_value_is_unknown_then_returns_nil() {
        // Given — a stored setting whose raw value can't be mapped to a known case.
        let storageManager = MockStorageManager()
        let stored = SiteSetting.fake().copy(siteID: siteID,
                                             settingID: "woocommerce_date_type",
                                             value: "garbage_value",
                                             settingGroupKey: "wc_admin")
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: stored)

        // When
        let cached = AnalyticsOrderDateType.cachedValue(siteID: siteID, storageManager: storageManager)

        // Then
        #expect(cached == nil)
    }

    @Test
    func cachedValue_when_setting_belongs_to_other_site_then_returns_nil() {
        // Given
        let storageManager = MockStorageManager()
        let stored = SiteSetting.fake().copy(siteID: siteID + 1,
                                             settingID: "woocommerce_date_type",
                                             value: AnalyticsOrderDateType.allOrders.rawValue,
                                             settingGroupKey: "wc_admin")
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: stored)

        // When
        let cached = AnalyticsOrderDateType.cachedValue(siteID: siteID, storageManager: storageManager)

        // Then
        #expect(cached == nil)
    }
}

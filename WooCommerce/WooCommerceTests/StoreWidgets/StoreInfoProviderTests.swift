import Foundation
import Testing
import WooFoundationCore
@testable import WooCommerce

struct StoreInfoProviderTests {

    @Test func selectedStoreMetadata_when_mirror_has_currency_then_uses_mirror_currency_over_cache() {
        // Given
        let userDefaults = makeUserDefaults()
        let cache = WidgetSiteCurrencyCache(userDefaults: userDefaults)
        cache.save(makeCurrencySettings(currencyCode: .EUR), forSiteID: 2)
        let mirrorCurrency = makeCurrencySettings(currencyCode: .GBP)
        let defaultStore = makeStoreMetadata(siteID: 1, currencySettings: makeCurrencySettings(currencyCode: .USD))
        let sites = [
            makeWidgetSite(siteID: 2, currencySettings: mirrorCurrency)
        ]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "2",
                                                               sites: sites,
                                                               currencyCache: cache)

        // Then
        #expect(metadata.storeCurrencySettings == mirrorCurrency)
        #expect(metadata.siteIDNeedingCurrencySettingsRefresh == nil)
    }

    @Test func selectedStoreMetadata_when_cache_has_currency_then_uses_cache_currency() {
        // Given
        let userDefaults = makeUserDefaults()
        let cache = WidgetSiteCurrencyCache(userDefaults: userDefaults)
        let cachedCurrency = makeCurrencySettings(currencyCode: .EUR)
        cache.save(cachedCurrency, forSiteID: 2)
        let defaultStore = makeStoreMetadata(siteID: 1, currencySettings: makeCurrencySettings(currencyCode: .USD))
        let sites = [
            makeWidgetSite(siteID: 2, currencySettings: nil)
        ]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "2",
                                                               sites: sites,
                                                               currencyCache: cache)

        // Then
        #expect(metadata.storeCurrencySettings == cachedCurrency)
        #expect(metadata.siteIDNeedingCurrencySettingsRefresh == nil)
    }

    @Test func selectedStoreMetadata_when_cache_and_mirror_miss_then_uses_default_currency_and_marks_refresh() {
        // Given
        let cache = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let defaultCurrency = makeCurrencySettings(currencyCode: .USD)
        let defaultStore = makeStoreMetadata(siteID: 1, currencySettings: defaultCurrency)
        let sites = [
            makeWidgetSite(siteID: 2, currencySettings: nil)
        ]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "2",
                                                               sites: sites,
                                                               currencyCache: cache)

        // Then
        #expect(metadata.storeCurrencySettings == defaultCurrency)
        #expect(metadata.siteIDNeedingCurrencySettingsRefresh == 2)
    }

    @Test func selectedStoreMetadata_when_selected_site_is_default_site_then_does_not_mark_refresh() {
        // Given
        let cache = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let defaultCurrency = makeCurrencySettings(currencyCode: .USD)
        let defaultStore = makeStoreMetadata(siteID: 1, currencySettings: defaultCurrency)
        let sites = [
            makeWidgetSite(siteID: 1, currencySettings: nil)
        ]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "1",
                                                               sites: sites,
                                                               currencyCache: cache)

        // Then
        #expect(metadata.storeCurrencySettings == defaultCurrency)
        #expect(metadata.siteIDNeedingCurrencySettingsRefresh == nil)
    }

    @Test func selectedStoreMetadata_when_selection_is_default_entity_then_returns_default_store() {
        // Given
        let cache = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let defaultStore = makeStoreMetadata(siteID: 1, currencySettings: makeCurrencySettings(currencyCode: .USD))
        let sites = [
            makeWidgetSite(siteID: 2, currencySettings: nil)
        ]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: StoreStatsStoreSelection.defaultStoreEntityID,
                                                               sites: sites,
                                                               currencyCache: cache)

        // Then
        #expect(metadata.storeID == defaultStore.storeID)
        #expect(metadata.siteIDNeedingCurrencySettingsRefresh == nil)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "StoreInfoProviderTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeStoreMetadata(siteID: Int64, currencySettings: CurrencySettings) -> StoreInfoProvider.StoreMetadata {
        StoreInfoProvider.StoreMetadata(storeID: siteID,
                                        storeName: "Default",
                                        storeCurrencySettings: currencySettings,
                                        storeTimeZone: .current,
                                        siteIDNeedingCurrencySettingsRefresh: nil)
    }

    private func makeWidgetSite(siteID: Int64, currencySettings: CurrencySettings?) -> WidgetSite {
        WidgetSite(siteID: siteID,
                   name: "Store \(siteID)",
                   timezoneIdentifier: "UTC",
                   gmtOffset: 0,
                   currencySettings: currencySettings)
    }

    private func makeCurrencySettings(currencyCode: CurrencyCode) -> CurrencySettings {
        CurrencySettings(currencyCode: currencyCode,
                         currencyPosition: .left,
                         thousandSeparator: ",",
                         decimalSeparator: ".",
                         numberOfDecimals: 2)
    }
}

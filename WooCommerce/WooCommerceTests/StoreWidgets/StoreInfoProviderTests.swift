import Foundation
@testable import Networking
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

    @Test func storeMetadataByRefreshingCurrencySettingsIfNeeded_when_refresh_succeeds_then_returns_fetched_currency_and_saves_cache() async {
        // Given
        let userDefaults = makeUserDefaults()
        let cache = WidgetSiteCurrencyCache(userDefaults: userDefaults)
        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")
        let service = StoreInfoDataService(network: network)
        let store = makeStoreMetadata(siteID: 1234,
                                      currencySettings: makeCurrencySettings(currencyCode: .EUR),
                                      siteIDNeedingCurrencySettingsRefresh: 1234)

        // When
        let refreshedStore = await StoreInfoProvider.storeMetadataByRefreshingCurrencySettingsIfNeeded(store,
                                                                                                       service: service,
                                                                                                       currencyCache: cache)

        // Then
        #expect(refreshedStore.storeCurrencySettings.currencyCode == .USD)
        #expect(refreshedStore.siteIDNeedingCurrencySettingsRefresh == nil)
        #expect(cache.currencySettings(forSiteID: 1234)?.currencyCode == .USD)
        #expect(network.requestsForResponseData.count == 1)
    }

    @Test func storeMetadataByRefreshingCurrencySettingsIfNeeded_when_refresh_fails_then_returns_original_store_and_does_not_cache() async {
        // Given
        let userDefaults = makeUserDefaults()
        let cache = WidgetSiteCurrencyCache(userDefaults: userDefaults)
        let service = StoreInfoDataService(network: MockNetwork())
        let currencySettings = makeCurrencySettings(currencyCode: .EUR)
        let store = makeStoreMetadata(siteID: 1234,
                                      currencySettings: currencySettings,
                                      siteIDNeedingCurrencySettingsRefresh: 1234)

        // When
        let refreshedStore = await StoreInfoProvider.storeMetadataByRefreshingCurrencySettingsIfNeeded(store,
                                                                                                       service: service,
                                                                                                       currencyCache: cache)

        // Then
        #expect(refreshedStore.storeCurrencySettings == currencySettings)
        #expect(refreshedStore.siteIDNeedingCurrencySettingsRefresh == 1234)
        #expect(cache.currencySettings(forSiteID: 1234) == nil)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "StoreInfoProviderTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeStoreMetadata(siteID: Int64,
                                   currencySettings: CurrencySettings,
                                   siteIDNeedingCurrencySettingsRefresh: Int64? = nil) -> StoreInfoProvider.StoreMetadata {
        StoreInfoProvider.StoreMetadata(storeID: siteID,
                                        storeName: "Default",
                                        storeCurrencySettings: currencySettings,
                                        storeTimeZone: .current,
                                        siteIDNeedingCurrencySettingsRefresh: siteIDNeedingCurrencySettingsRefresh)
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

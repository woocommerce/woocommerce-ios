import Foundation
import Testing
import WooFoundationCore
@testable import WooCommerce

struct WidgetSiteListStoreTests {

    @Test func sites_when_no_data_is_persisted_then_returns_empty_list() {
        // Given
        let userDefaults = makeUserDefaults()
        let sut = WidgetSiteListStore(userDefaults: userDefaults)

        // When
        let sites = sut.sites()

        // Then
        #expect(sites.isEmpty)
    }

    @Test func sites_when_persisted_data_is_invalid_then_returns_empty_list() {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Data([0xFF, 0xFE]), forKey: .widgetSelectableSites)
        let sut = WidgetSiteListStore(userDefaults: userDefaults)

        // When
        let sites = sut.sites()

        // Then
        #expect(sites.isEmpty)
    }

    @Test func save_then_sites_returns_round_tripped_sites() {
        // Given
        let userDefaults = makeUserDefaults()
        let sut = WidgetSiteListStore(userDefaults: userDefaults)
        let sites = [
            WidgetSite(siteID: 1,
                       name: "Default",
                       timezoneIdentifier: "UTC",
                       gmtOffset: 0,
                       currencySettings: nil),
            WidgetSite(siteID: 2,
                       name: "Other",
                       timezoneIdentifier: "Europe/Madrid",
                       gmtOffset: 1,
                       currencySettings: CurrencySettings())
        ]

        // When
        sut.save(sites)
        let loaded = sut.sites()

        // Then
        #expect(loaded.map(\.siteID) == [1, 2])
        #expect(loaded.map(\.name) == ["Default", "Other"])
    }

    @Test func clear_when_data_is_persisted_then_removes_data() {
        // Given
        let userDefaults = makeUserDefaults()
        let sut = WidgetSiteListStore(userDefaults: userDefaults)
        sut.save([
            WidgetSite(siteID: 1, name: "Default", timezoneIdentifier: "UTC", gmtOffset: 0, currencySettings: nil)
        ])

        // When
        sut.clear()

        // Then
        #expect(sut.sites().isEmpty)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "WidgetSiteListStoreTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}

struct StoreStatsStoreQueryTests {

    @Test func suggested_entities_when_site_list_store_has_sites_then_returns_widget_site_entities() async throws {
        // Given
        let userDefaults = makeUserDefaults()
        let siteListStore = WidgetSiteListStore(userDefaults: userDefaults)
        siteListStore.save([
            makeSite(siteID: 1, name: "Default"),
            makeSite(siteID: 2, name: "Other")
        ])
        let sut = StoreStatsStoreQuery(siteListStore: siteListStore)

        // When
        let entities = try await sut.suggestedEntities()

        // Then
        #expect(entities.map(\.id) == ["1", "2"])
        #expect(entities.map(\.name) == ["Default", "Other"])
    }

    @Test func entities_when_identifiers_include_default_store_then_returns_default_store_and_matching_sites() async throws {
        // Given
        let userDefaults = makeUserDefaults()
        let siteListStore = WidgetSiteListStore(userDefaults: userDefaults)
        siteListStore.save([
            makeSite(siteID: 1, name: "Default"),
            makeSite(siteID: 2, name: "Other")
        ])
        let sut = StoreStatsStoreQuery(siteListStore: siteListStore)

        // When
        let entities = try await sut.entities(for: [
            StoreStatsStoreSelection.defaultStoreEntityID,
            "2"
        ])

        // Then
        #expect(entities.map(\.id) == [StoreStatsStoreSelection.defaultStoreEntityID, "2"])
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "StoreStatsStoreQueryTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeSite(siteID: Int64, name: String, currencySettings: CurrencySettings? = nil) -> WidgetSite {
        WidgetSite(siteID: siteID,
                   name: name,
                   timezoneIdentifier: "UTC",
                   gmtOffset: 0,
                   currencySettings: currencySettings)
    }
}

struct StoreInfoProviderStoreSelectionTests {

    @Test func selected_store_metadata_when_default_store_entity_is_selected_then_returns_default_store() {
        // Given
        let defaultStore = makeDefaultStore(currencyCode: .USD)
        let sites = [makeSite(siteID: 2, name: "Other", currencyCode: .EUR)]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: StoreStatsStoreSelection.defaultStoreEntityID,
                                                               sites: sites)

        // Then
        #expect(metadata.storeID == defaultStore.storeID)
        #expect(metadata.storeName == defaultStore.storeName)
        #expect(metadata.storeCurrencySettings.currencyCode == .USD)
    }

    @Test func selected_store_metadata_when_selected_store_id_is_stale_then_returns_default_store() {
        // Given
        let defaultStore = makeDefaultStore(currencyCode: .USD)
        let sites = [makeSite(siteID: 2, name: "Other", currencyCode: .EUR)]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "999",
                                                               sites: sites)

        // Then
        #expect(metadata.storeID == defaultStore.storeID)
        #expect(metadata.storeName == defaultStore.storeName)
        #expect(metadata.storeCurrencySettings.currencyCode == .USD)
    }

    @Test func selected_store_metadata_when_non_default_store_is_selected_then_uses_widget_site_details() {
        // Given
        let defaultStore = makeDefaultStore(currencyCode: .USD)
        let sites = [makeSite(siteID: 2,
                              name: "Madrid",
                              timezoneIdentifier: "Europe/Madrid",
                              gmtOffset: 1,
                              currencyCode: .EUR)]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "2",
                                                               sites: sites)

        // Then
        #expect(metadata.storeID == 2)
        #expect(metadata.storeName == "Madrid")
        #expect(metadata.storeCurrencySettings.currencyCode == .EUR)
        #expect(metadata.storeTimeZone.identifier == "Europe/Madrid")
    }

    @Test func selected_store_metadata_when_non_default_store_has_no_currency_settings_then_uses_default_currency_settings() {
        // Given
        let defaultStore = makeDefaultStore(currencyCode: .USD)
        let sites = [makeSite(siteID: 2, name: "Other", currencyCode: nil)]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "2",
                                                               sites: sites)

        // Then
        #expect(metadata.storeID == 2)
        #expect(metadata.storeCurrencySettings.currencyCode == .USD)
    }

    @Test func selected_store_metadata_when_default_store_site_is_selected_then_uses_default_currency_settings() {
        // Given
        let defaultStore = makeDefaultStore(currencyCode: .USD)
        let sites = [makeSite(siteID: 1, name: "Default From List", currencyCode: .EUR)]

        // When
        let metadata = StoreInfoProvider.selectedStoreMetadata(defaultStore: defaultStore,
                                                               selectedStoreID: "1",
                                                               sites: sites)

        // Then
        #expect(metadata.storeID == 1)
        #expect(metadata.storeName == "Default From List")
        #expect(metadata.storeCurrencySettings.currencyCode == .USD)
    }

    private func makeDefaultStore(currencyCode: CurrencyCode) -> StoreInfoProvider.StoreMetadata {
        StoreInfoProvider.StoreMetadata(storeID: 1,
                                        storeName: "Default",
                                        storeCurrencySettings: currencySettings(for: currencyCode),
                                        storeTimeZone: TimeZone(identifier: "UTC")!)
    }

    private func makeSite(siteID: Int64,
                          name: String,
                          timezoneIdentifier: String = "UTC",
                          gmtOffset: Double = 0,
                          currencyCode: CurrencyCode?) -> WidgetSite {
        WidgetSite(siteID: siteID,
                   name: name,
                   timezoneIdentifier: timezoneIdentifier,
                   gmtOffset: gmtOffset,
                   currencySettings: currencyCode.map { currencySettings(for: $0) })
    }

    private func currencySettings(for currencyCode: CurrencyCode) -> CurrencySettings {
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = currencyCode
        return currencySettings
    }
}

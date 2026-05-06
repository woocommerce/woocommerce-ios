@testable import WooCommerce
import Foundation
import Testing
import WooFoundationCore

struct StoreStatsSnapshotTests {
    @Test func snapshots_whenStorePickerIsExposed_thenKeepsWooStoresWithDefaultFirst() throws {
        // Given
        let defaultCurrencySettingsData = try currencySettingsData(for: .USD)
        let alphaCurrencySettingsData = try currencySettingsData(for: .EUR)
        let betaCurrencySettingsData = try currencySettingsData(for: .GBP)
        let storedSites = [
            StoreStatsStoredSite(siteID: 2,
                                 name: "Beta",
                                 timeZoneIdentifier: "Europe/Madrid",
                                 gmtOffset: 1,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: true),
            StoreStatsStoredSite(siteID: 4,
                                 name: "No Woo",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: false,
                                 supportsVisitorStats: true),
            StoreStatsStoredSite(siteID: 2,
                                 name: "Beta Duplicate",
                                 timeZoneIdentifier: "Europe/Madrid",
                                 gmtOffset: 1,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: true),
            StoreStatsStoredSite(siteID: 1,
                                 name: "Alpha",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: false)
        ]
        let defaultSite = StoreStatsStoredSite(siteID: 3,
                                               name: "Default",
                                               timeZoneIdentifier: "America/New_York",
                                               gmtOffset: -5,
                                               isWooCommerceActive: true,
                                               supportsVisitorStats: true)

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: defaultSite,
                                                            defaultSiteID: 3,
                                                            defaultCurrencySettingsData: defaultCurrencySettingsData,
                                                            currencySettingsDataBySiteID: [
                                                                1: alphaCurrencySettingsData,
                                                                2: betaCurrencySettingsData,
                                                                3: defaultCurrencySettingsData
                                                            ],
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [3, 1, 2])
        #expect(snapshots.map(\.name) == ["Default", "Alpha", "Beta"])
        #expect(snapshots[0].isSelectableInStorePicker)
        #expect(snapshots[0].currencySettingsData == defaultCurrencySettingsData)
        #expect(snapshots[1].currencySettingsData == alphaCurrencySettingsData)
        #expect(snapshots[2].currencySettingsData == betaCurrencySettingsData)
        #expect(snapshots[1].supportsVisitorStats == false)
        #expect(snapshots[2].timeZone == TimeZone(identifier: "Europe/Madrid"))
    }

    @Test func snapshots_whenNonDefaultStoreHasNoCurrencySettings_thenExcludesStore() throws {
        // Given
        let defaultCurrencySettingsData = try currencySettingsData(for: .USD)
        let storedSites = [
            StoreStatsStoredSite(siteID: 1,
                                 name: "Default",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: true),
            StoreStatsStoredSite(siteID: 2,
                                 name: "Other",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: true)
        ]

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: storedSites[0],
                                                            defaultSiteID: 1,
                                                            defaultCurrencySettingsData: defaultCurrencySettingsData,
                                                            currencySettingsDataBySiteID: [1: defaultCurrencySettingsData],
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [1])
    }

    @Test func snapshots_whenStorePickerIsNotExposed_thenReturnsEmptyList() {
        // Given
        let storedSites = [
            StoreStatsStoredSite(siteID: 1,
                                 name: "Default",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true,
                                 supportsVisitorStats: false)
        ]

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: storedSites[0],
                                                            defaultSiteID: 1,
                                                            defaultCurrencySettingsData: nil,
                                                            exposesStorePicker: false)

        // Then
        #expect(snapshots.isEmpty)
    }

    @Test func snapshots_whenListIsAbsent_thenFallsBackToDefaultStoreForRendering() {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Int64(123), forKey: .defaultStoreID)
        userDefaults.set("Default Store", forKey: .defaultStoreName)
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)

        // When
        let snapshots = store.snapshots()
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(snapshots.map(\.siteID) == [123])
        #expect(snapshots[0].name == "Default Store")
        #expect(snapshots[0].isSelectableInStorePicker == false)
        #expect(pickerSnapshots.isEmpty)
    }

    @Test func storePickerSnapshots_whenSavedListIsEmpty_thenReturnsNoSelectableStores() {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Int64(123), forKey: .defaultStoreID)
        userDefaults.set("Default Store", forKey: .defaultStoreName)
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)
        store.save([])

        // When
        let snapshots = store.snapshots()
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(snapshots.isEmpty)
        #expect(pickerSnapshots.isEmpty)
    }

    @Test func storePickerSnapshots_whenSavedListHasSelectableStores_thenReturnsThoseStores() {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Int64(1), forKey: .defaultStoreID)
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)
        let snapshots = [
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Hidden",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: false,
                               currencySettingsData: nil)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1])
    }

    @Test func storePickerSnapshots_whenSavedNonDefaultStoreHasNoCurrencySettings_thenExcludesStore() throws {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Int64(1), forKey: .defaultStoreID)
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)
        let otherCurrencySettingsData = try currencySettingsData(for: .EUR)
        let snapshots = [
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Other",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 3,
                               name: "Other with currency",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: otherCurrencySettingsData)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1, 3])
    }

    @Test func selectedStoreSnapshot_whenDefaultStoreEntityIsSelected_thenReturnsDefaultSnapshot() {
        // Given
        let snapshots = [
            StoreStatsSnapshot(siteID: 2,
                               name: "Other",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil)
        ]

        // When
        let selectedStore = StoreInfoProvider.selectedStoreSnapshot(from: snapshots,
                                                                    selectedStoreID: StoreStatsStoreEntity.defaultStore.id,
                                                                    defaultStoreID: 1)

        // Then
        #expect(selectedStore?.siteID == 1)
    }

    @Test func defaultResult_thenReturnsDefaultStoreEntity() async {
        // When
        let defaultResult = await StoreStatsStoreQuery().defaultResult()

        // Then
        #expect(defaultResult?.id == StoreStatsStoreEntity.defaultStore.id)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "StoreStatsSnapshotTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func currencySettingsData(for currencyCode: CurrencyCode) throws -> Data {
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = currencyCode
        return try JSONEncoder().encode(currencySettings)
    }
}

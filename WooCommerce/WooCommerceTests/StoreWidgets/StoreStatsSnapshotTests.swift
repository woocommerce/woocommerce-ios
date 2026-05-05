@testable import WooCommerce
import Foundation
import Testing
import WooFoundationCore

struct StoreStatsSnapshotTests {
    @Test func snapshots_whenStorePickerIsExposed_thenKeepsWooStoresWithDefaultFirst() throws {
        // Given
        let currencySettingsData = try JSONEncoder().encode(CurrencySettings())
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
                                                            defaultCurrencySettingsData: currencySettingsData,
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [3, 1, 2])
        #expect(snapshots.map(\.name) == ["Default", "Alpha", "Beta"])
        #expect(snapshots[0].isDefault)
        #expect(snapshots[0].isSelectableInStorePicker)
        #expect(snapshots[0].currencySettingsData == currencySettingsData)
        #expect(snapshots[1].supportsVisitorStats == false)
        #expect(snapshots[2].timeZone == TimeZone(identifier: "Europe/Madrid"))
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
        #expect(snapshots[0].isDefault)
        #expect(snapshots[0].isSelectableInStorePicker == false)
        #expect(pickerSnapshots.map(\.siteID) == [123])
        #expect(pickerSnapshots[0].name == "Default Store")
        #expect(pickerSnapshots[0].isSelectableInStorePicker == false)
    }

    @Test func storePickerSnapshots_whenSavedListIsEmpty_thenReturnsDefaultStoreFallback() {
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
        #expect(pickerSnapshots.map(\.siteID) == [123])
        #expect(pickerSnapshots[0].name == "Default Store")
        #expect(pickerSnapshots[0].isSelectableInStorePicker == false)
    }

    @Test func storePickerSnapshots_whenSavedListHasSelectableStores_thenReturnsThoseStores() {
        // Given
        let userDefaults = makeUserDefaults()
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)
        let snapshots = [
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isDefault: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Hidden",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isDefault: false,
                               isSelectableInStorePicker: false,
                               currencySettingsData: nil)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1])
    }

    @Test func selectedStoreSnapshot_whenDefaultStoreEntityIsSelected_thenReturnsDefaultSnapshot() {
        // Given
        let snapshots = [
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isDefault: true,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Other",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               supportsVisitorStats: true,
                               isDefault: false,
                               isSelectableInStorePicker: true,
                               currencySettingsData: nil)
        ]

        // When
        let selectedStore = StoreInfoProvider.selectedStoreSnapshot(from: snapshots,
                                                                    selectedStoreID: StoreStatsStoreEntity.defaultStore.id)

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
}

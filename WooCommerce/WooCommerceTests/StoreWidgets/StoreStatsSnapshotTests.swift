@testable import WooCommerce
import Foundation
import Testing

struct StoreStatsSnapshotTests {
    @Test func snapshots_whenStorePickerIsExposed_thenKeepsWooStoresWithDefaultFirst() {
        // Given
        let storedSites = [
            StoreStatsStoredSite(siteID: 2,
                                 name: "Beta",
                                 timeZoneIdentifier: "Europe/Madrid",
                                 gmtOffset: 1,
                                 isWooCommerceActive: true),
            StoreStatsStoredSite(siteID: 4,
                                 name: "No Woo",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: false),
            StoreStatsStoredSite(siteID: 2,
                                 name: "Beta Duplicate",
                                 timeZoneIdentifier: "Europe/Madrid",
                                 gmtOffset: 1,
                                 isWooCommerceActive: true),
            StoreStatsStoredSite(siteID: 1,
                                 name: "Alpha",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true)
        ]
        let defaultSite = StoreStatsStoredSite(siteID: 3,
                                               name: "Default",
                                               timeZoneIdentifier: "America/New_York",
                                               gmtOffset: -5,
                                               isWooCommerceActive: true)

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: defaultSite,
                                                            defaultSiteID: 3,
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [3, 1, 2])
        #expect(snapshots.map(\.name) == ["Default", "Alpha", "Beta"])
        #expect(snapshots[0].isSelectableInStorePicker)
        #expect(snapshots[2].timeZone == TimeZone(identifier: "Europe/Madrid"))
    }

    @Test func snapshots_whenStoreIsHidden_thenExcludesHiddenStore() {
        // Given
        let storedSites = [
            StoreStatsStoredSite(siteID: 1,
                                 name: "Default",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true),
            StoreStatsStoredSite(siteID: 2,
                                 name: "Hidden",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true),
            StoreStatsStoredSite(siteID: 3,
                                 name: "Visible",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true)
        ]

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: storedSites[0],
                                                            defaultSiteID: 1,
                                                            hiddenStoreIDs: [2],
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [1, 3])
    }

    @Test func snapshots_whenStorePickerIsNotExposed_thenReturnsEmptyList() {
        // Given
        let storedSites = [
            StoreStatsStoredSite(siteID: 1,
                                 name: "Default",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true)
        ]

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: storedSites[0],
                                                            defaultSiteID: 1,
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
        #expect(snapshots[0].timeZone.identifier == TimeZone.current.identifier)
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
                               isSelectableInStorePicker: true),
            StoreStatsSnapshot(siteID: 2,
                               name: "Hidden",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: false)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1])
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "StoreStatsSnapshotTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}

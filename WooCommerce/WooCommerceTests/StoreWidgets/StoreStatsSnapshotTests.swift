@testable import WooCommerce
import Foundation
import Testing
import WooFoundationCore

struct StoreStatsSnapshotTests {
    @Test func snapshots_whenStorePickerIsExposed_thenKeepsWooStoresWithDefaultFirst() {
        // Given
        let defaultCurrencySettings = currencySettings(for: .USD)
        let alphaCurrencySettings = currencySettings(for: .EUR)
        let betaCurrencySettings = currencySettings(for: .GBP)
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
                                                            currencySettingsBySiteID: [
                                                                1: alphaCurrencySettings,
                                                                2: betaCurrencySettings,
                                                                3: defaultCurrencySettings
                                                            ],
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [3, 1, 2])
        #expect(snapshots.map(\.name) == ["Default", "Alpha", "Beta"])
        #expect(snapshots[0].isSelectableInStorePicker)
        #expect(snapshots[0].currencySettings == defaultCurrencySettings)
        #expect(snapshots[1].currencySettings == alphaCurrencySettings)
        #expect(snapshots[2].currencySettings == betaCurrencySettings)
        #expect(snapshots[2].timeZone == TimeZone(identifier: "Europe/Madrid"))
    }

    @Test func snapshots_whenNonDefaultStoreHasNoCurrencySettings_thenKeepsCurrencySettingsNil() {
        // Given
        let defaultCurrencySettings = currencySettings(for: .USD)
        let storedSites = [
            StoreStatsStoredSite(siteID: 1,
                                 name: "Default",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true),
            StoreStatsStoredSite(siteID: 2,
                                 name: "Other",
                                 timeZoneIdentifier: "UTC",
                                 gmtOffset: 0,
                                 isWooCommerceActive: true)
        ]

        // When
        let snapshots = StoreStatsSnapshotFactory.snapshots(storedSites: storedSites,
                                                            defaultSite: storedSites[0],
                                                            defaultSiteID: 1,
                                                            currencySettingsBySiteID: [1: defaultCurrencySettings],
                                                            exposesStorePicker: true)

        // Then
        #expect(snapshots.map(\.siteID) == [1, 2])
        #expect(snapshots[1].currencySettings == nil)
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
                               isSelectableInStorePicker: true,
                               currencySettings: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Hidden",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: false,
                               currencySettings: nil)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1])
    }

    @Test func storePickerSnapshots_whenSavedNonDefaultStoreHasNoCurrencySettings_thenIncludesStore() {
        // Given
        let userDefaults = makeUserDefaults()
        userDefaults.set(Int64(1), forKey: .defaultStoreID)
        let store = StoreStatsSnapshotStore(userDefaults: userDefaults)
        let otherCurrencySettings = currencySettings(for: .EUR)
        let snapshots = [
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: true,
                               currencySettings: nil),
            StoreStatsSnapshot(siteID: 2,
                               name: "Other",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: true,
                               currencySettings: nil),
            StoreStatsSnapshot(siteID: 3,
                               name: "Other with currency",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: true,
                               currencySettings: otherCurrencySettings)
        ]
        store.save(snapshots)

        // When
        let pickerSnapshots = store.storePickerSnapshots()

        // Then
        #expect(pickerSnapshots.map(\.siteID) == [1, 2, 3])
    }

    @Test func currencySettings_whenSelectedStoreIsDefault_thenUsesDefaultCurrencySettings() {
        // Given
        let staleSnapshotCurrencySettings = currencySettings(for: .USD)
        let defaultCurrencySettings = currencySettings(for: .EUR)
        let selectedStore = StoreStatsSnapshot(siteID: 1,
                                               name: "Default",
                                               timeZoneIdentifier: nil,
                                               gmtOffset: 0,
                                               isSelectableInStorePicker: true,
                                               currencySettings: staleSnapshotCurrencySettings)

        // When
        let resolvedCurrencySettings = StoreInfoProvider.currencySettings(for: selectedStore,
                                                                          defaultStoreID: 1,
                                                                          defaultCurrencySettings: defaultCurrencySettings)

        // Then
        #expect(resolvedCurrencySettings.currencyCode == .EUR)
    }

    @Test func currencySettings_whenSelectedStoreHasNoCurrencySettings_thenUsesDefaultCurrencySettings() {
        // Given
        let defaultCurrencySettings = currencySettings(for: .EUR)
        let selectedStore = StoreStatsSnapshot(siteID: 2,
                                               name: "Other",
                                               timeZoneIdentifier: nil,
                                               gmtOffset: 0,
                                               isSelectableInStorePicker: true,
                                               currencySettings: nil)

        // When
        let resolvedCurrencySettings = StoreInfoProvider.currencySettings(for: selectedStore,
                                                                          defaultStoreID: 1,
                                                                          defaultCurrencySettings: defaultCurrencySettings)

        // Then
        #expect(resolvedCurrencySettings.currencyCode == .EUR)
    }

    @Test func selectedStoreSnapshot_whenDefaultStoreEntityIsSelected_thenReturnsDefaultSnapshot() {
        // Given
        let snapshots = [
            StoreStatsSnapshot(siteID: 2,
                               name: "Other",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: true,
                               currencySettings: nil),
            StoreStatsSnapshot(siteID: 1,
                               name: "Default",
                               timeZoneIdentifier: nil,
                               gmtOffset: 0,
                               isSelectableInStorePicker: true,
                               currencySettings: nil)
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

    private func currencySettings(for currencyCode: CurrencyCode) -> CurrencySettings {
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = currencyCode
        return currencySettings
    }
}

import Testing
import Yosemite
import YosemiteTestHelpers
import Storage
import WooFoundation
@testable import WooCommerce

/// Tests for `SelectedSiteSettings`.
///
@MainActor
struct SelectedSiteSettingsTests {
    private let siteID: Int64 = 1_234

    @Test func isUsingFallbackCurrency_is_false_when_the_currency_setting_is_stored() {
        // Given
        let storageManager = MockStorageManager()
        let stores = makeStores()
        insertCurrencySetting(into: storageManager)

        // When
        let sut = SelectedSiteSettings(stores: stores, storageManager: storageManager)

        // Then
        #expect(sut.isUsingFallbackCurrency == false)
    }

    @Test func isUsingFallbackCurrency_is_true_when_the_currency_setting_is_missing() {
        // Given — no general settings stored (e.g. the settings sync failed)
        let storageManager = MockStorageManager()
        let stores = makeStores()

        // When
        let sut = SelectedSiteSettings(stores: stores, storageManager: storageManager)

        // Then
        #expect(sut.isUsingFallbackCurrency == true)
    }
}

private extension SelectedSiteSettingsTests {
    func makeStores() -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(siteID)
        return stores
    }

    func insertCurrencySetting(into storageManager: MockStorageManager) {
        storageManager.performAndSave({ [siteID] storage in
            let setting = storage.insertNewObject(ofType: StorageSiteSetting.self)
            setting.siteID = siteID
            setting.settingID = CurrencySettings.Constants.currencyCodeKey
            setting.settingGroupKey = SiteSettingGroup.general.rawValue
            setting.label = ""
            setting.settingDescription = ""
            setting.value = "USD"
        }, completion: {}, on: .main)
    }
}

import Foundation
import Testing
import WooFoundationCore
@testable import WooCommerce

struct WidgetSiteCurrencyCacheTests {

    @Test func currencySettings_when_no_data_is_persisted_then_returns_nil() {
        // Given
        let sut = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())

        // When
        let settings = sut.currencySettings(forSiteID: 1)

        // Then
        #expect(settings == nil)
    }

    @Test func save_then_currencySettings_returns_round_tripped_settings() {
        // Given
        let sut = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let settings = makeCurrencySettings(currencyCode: .EUR)

        // When
        sut.save(settings, forSiteID: 1)

        // Then
        #expect(sut.currencySettings(forSiteID: 1) == settings)
    }

    @Test func save_then_uses_site_specific_key() {
        // Given
        let userDefaults = makeUserDefaults()
        let sut = WidgetSiteCurrencyCache(userDefaults: userDefaults)

        // When
        sut.save(makeCurrencySettings(currencyCode: .EUR), forSiteID: 1)

        // Then
        let perSiteData = userDefaults.object(forKey: perSiteKey(forSiteID: 1)) as? Data
        #expect(perSiteData != nil)
    }

    @Test func save_when_multiple_sites_are_persisted_then_keeps_entries_separate() {
        // Given
        let sut = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let firstSiteSettings = makeCurrencySettings(currencyCode: .EUR)
        let secondSiteSettings = makeCurrencySettings(currencyCode: .GBP)

        // When
        sut.save(firstSiteSettings, forSiteID: 1)
        sut.save(secondSiteSettings, forSiteID: 2)

        // Then
        #expect(sut.currencySettings(forSiteID: 1) == firstSiteSettings)
        #expect(sut.currencySettings(forSiteID: 2) == secondSiteSettings)
    }

    @Test func currencySettings_when_entry_data_is_corrupt_then_returns_nil_without_dropping_other_entries() throws {
        // Given
        let userDefaults = makeUserDefaults()
        let validSettings = makeCurrencySettings(currencyCode: .CAD)
        userDefaults.set(Data([0xFF, 0xFE]), forKey: perSiteKey(forSiteID: 1))
        userDefaults.set(try JSONEncoder().encode(validSettings), forKey: perSiteKey(forSiteID: 2))
        let sut = WidgetSiteCurrencyCache(userDefaults: userDefaults)

        // When
        let corruptSettings = sut.currencySettings(forSiteID: 1)
        let validSettingsRead = sut.currencySettings(forSiteID: 2)

        // Then
        #expect(corruptSettings == nil)
        #expect(validSettingsRead == validSettings)
    }

    @Test func clear_when_data_is_persisted_then_removes_all_entries() {
        // Given
        let userDefaults = makeUserDefaults()
        let sut = WidgetSiteCurrencyCache(userDefaults: userDefaults)
        sut.save(makeCurrencySettings(currencyCode: .EUR), forSiteID: 1)
        sut.save(makeCurrencySettings(currencyCode: .GBP), forSiteID: 2)

        // When
        sut.clear()

        // Then
        #expect(sut.currencySettings(forSiteID: 1) == nil)
        #expect(sut.currencySettings(forSiteID: 2) == nil)
    }

    @Test func removeCurrencySettings_when_data_is_persisted_then_removes_only_matching_site() {
        // Given
        let sut = WidgetSiteCurrencyCache(userDefaults: makeUserDefaults())
        let keptSettings = makeCurrencySettings(currencyCode: .GBP)
        sut.save(makeCurrencySettings(currencyCode: .EUR), forSiteID: 1)
        sut.save(keptSettings, forSiteID: 2)

        // When
        sut.removeCurrencySettings(forSiteID: 1)

        // Then
        #expect(sut.currencySettings(forSiteID: 1) == nil)
        #expect(sut.currencySettings(forSiteID: 2) == keptSettings)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "WidgetSiteCurrencyCacheTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeCurrencySettings(currencyCode: CurrencyCode) -> CurrencySettings {
        CurrencySettings(currencyCode: currencyCode,
                         currencyPosition: .left,
                         thousandSeparator: ",",
                         decimalSeparator: ".",
                         numberOfDecimals: 2)
    }

    private func perSiteKey(forSiteID siteID: Int64) -> String {
        "\(UserDefaults.Key.widgetSiteCurrencySettingsCache.rawValue).\(siteID)"
    }
}

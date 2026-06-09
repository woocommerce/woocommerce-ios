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

import Testing
import struct WooFoundation.WooAnalyticsEvent
@testable import PointOfSale

struct POSIneligibleAnalyticsEventTests {
    @Test(arguments: [
        (POSIneligibleReason.siteSettingsNotAvailable, "site_settings_unavailable"),
        (.selfDeallocated, "self_deallocated"),
        (.unsupportedCountry, "store_country"),
        (.noInternetConnection, "no_internet_connection"),
        (.unsupportedCurrency(countryCode: .US, supportedCurrencies: [.USD]), "store_currency"),
        (.unsupportedWooCommerceVersion(minimumVersion: "9.6.0"), "wc_plugin_version"),
        (.featureSwitchDisabled, "feature_switch_disabled"),
        (.wooCommercePluginNotFound, "unknown_wc_plugin")
    ])
    func test_ineligible_events_when_reason_is_known_then_report_specific_reason(reason: POSIneligibleReason, expected: String) {
        // Given / When
        let events = [
            WooAnalyticsEvent.PointOfSaleIneligibleUI.ineligibleUIShown(reason: reason),
            WooAnalyticsEvent.PointOfSaleIneligibleUI.ineligibleUIRetryTapped(reason: reason),
            WooAnalyticsEvent.PointOfSaleIneligibleUI.ineligibleUILearnMoreTapped(reason: reason)
        ]

        // Then
        for event in events {
            #expect(event.properties["reason"] as? String == expected)
        }
    }
}

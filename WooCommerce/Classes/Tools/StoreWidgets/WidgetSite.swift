import Foundation
import WooFoundationCore

/// Lightweight representation of a WooCommerce site, shared between the host app and the
/// `StoreWidgetsExtension` via app-group `UserDefaults`.
///
/// Carries the minimum data the widget needs to render and refresh stats for a selected site:
/// identification, display name, timezone, and currency settings. `currencySettings` may be
/// `nil` when general site settings have not been synced yet — the widget should fall back
/// to the default site's currency settings in that case.
struct WidgetSite: Codable, Equatable {
    let siteID: Int64
    let name: String
    let timezoneIdentifier: String
    let gmtOffset: Double
    let currencySettings: CurrencySettings?

    /// Resolves a usable `TimeZone` from the persisted identifier, falling back to a fixed-offset
    /// timezone derived from `gmtOffset`, then `.current` if neither yields a valid zone.
    var timezone: TimeZone {
        if let timezone = TimeZone(identifier: timezoneIdentifier) {
            return timezone
        }
        return TimeZone(secondsFromGMT: Int(gmtOffset * 3600)) ?? .current
    }
}

extension WidgetSite: Identifiable {
    var id: Int64 {
        return siteID
    }
}

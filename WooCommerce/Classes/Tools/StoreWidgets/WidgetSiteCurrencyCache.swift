import Foundation
import WooFoundationCore

/// Read/write wrapper around per-site currency settings fetched by the widget extension.
///
/// The host-app mirrored `WidgetSite.currencySettings` remains the authoritative source when
/// present. This cache only fills gaps for selectable sites whose general settings have not
/// been fetched into the host app's storage yet.
struct WidgetSiteCurrencyCache {
    private let userDefaults: UserDefaults?

    init(userDefaults: UserDefaults? = .group) {
        self.userDefaults = userDefaults
    }

    func currencySettings(forSiteID siteID: Int64) -> CurrencySettings? {
        guard let data = persistedMap()[String(siteID)] else {
            return nil
        }
        return try? JSONDecoder().decode(CurrencySettings.self, from: data)
    }

    func save(_ settings: CurrencySettings, forSiteID siteID: Int64) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        var map = persistedMap()
        map[String(siteID)] = data
        persist(map)
    }

    func removeCurrencySettings(forSiteID siteID: Int64) {
        var map = persistedMap()
        map.removeValue(forKey: String(siteID))
        persist(map)
    }

    func clear() {
        userDefaults?.removeObject(forKey: .widgetSiteCurrencySettingsCache)
    }
}

private extension WidgetSiteCurrencyCache {
    func persistedMap() -> [String: Data] {
        guard let data: Data = userDefaults?.object(forKey: .widgetSiteCurrencySettingsCache),
              let map = try? JSONDecoder().decode([String: Data].self, from: data) else {
            return [:]
        }
        return map
    }

    func persist(_ map: [String: Data]) {
        guard let data = try? JSONEncoder().encode(map) else {
            return
        }
        userDefaults?.set(data, forKey: .widgetSiteCurrencySettingsCache)
    }
}

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
        guard let data = userDefaults?.object(forKey: key(forSiteID: siteID)) as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(CurrencySettings.self, from: data)
    }

    func save(_ settings: CurrencySettings, forSiteID siteID: Int64) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        userDefaults?.set(data, forKey: key(forSiteID: siteID))
    }

    func removeCurrencySettings(forSiteID siteID: Int64) {
        userDefaults?.removeObject(forKey: key(forSiteID: siteID))
    }

    func clear() {
        guard let userDefaults else {
            return
        }
        userDefaults
            .dictionaryRepresentation()
            .keys
            .filter { $0.hasPrefix(Constants.perSiteKeyPrefix) }
            .forEach { userDefaults.removeObject(forKey: $0) }
        userDefaults.removeObject(forKey: .widgetSiteCurrencySettingsCache)
    }
}

private extension WidgetSiteCurrencyCache {
    func key(forSiteID siteID: Int64) -> String {
        "\(Constants.perSiteKeyPrefix)\(siteID)"
    }

    enum Constants {
        static let perSiteKeyPrefix = "\(UserDefaults.Key.widgetSiteCurrencySettingsCache.rawValue)."
    }
}

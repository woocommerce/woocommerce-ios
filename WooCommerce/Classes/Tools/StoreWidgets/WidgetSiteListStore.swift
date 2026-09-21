import Foundation

/// Read/write wrapper around the shared app-group `UserDefaults` entry that holds the list
/// of sites available for selection in the configurable Store Stats widget picker.
///
/// Used by:
/// - The host app (write side) via `WidgetSiteListSyncManager`.
/// - The widget extension (read side) when populating the picker and resolving the selected site.
///
/// Returns an empty list when the key is absent or fails to decode. The widget extension is
/// expected to fall back to the existing default-site keys in that case.
struct WidgetSiteListStore {
    private let userDefaults: UserDefaults?

    init(userDefaults: UserDefaults? = .group) {
        self.userDefaults = userDefaults
    }

    func sites() -> [WidgetSite] {
        guard let data: Data = userDefaults?.object(forKey: .widgetSelectableSites),
              let sites = try? JSONDecoder().decode([WidgetSite].self, from: data) else {
            return []
        }
        return sites
    }

    func save(_ sites: [WidgetSite]) {
        guard let data = try? JSONEncoder().encode(sites) else {
            return
        }
        userDefaults?.set(data, forKey: .widgetSelectableSites)
    }

    func clear() {
        userDefaults?.removeObject(forKey: .widgetSelectableSites)
    }
}

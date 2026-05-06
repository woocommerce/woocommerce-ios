import Foundation
import WooFoundationCore

struct StoreStatsSnapshot: Codable, Hashable, Identifiable {
    let siteID: Int64
    let name: String
    let timeZoneIdentifier: String?
    let gmtOffset: Double
    let supportsVisitorStats: Bool
    let isSelectableInStorePicker: Bool
    let currencySettingsData: Data?

    var id: Int64 {
        siteID
    }

    var appEntityID: String {
        String(siteID)
    }

    var timeZone: TimeZone {
        if let timeZoneIdentifier,
           !timeZoneIdentifier.isEmpty,
           let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            return timeZone
        }
        return TimeZone(secondsFromGMT: Int(gmtOffset * 3600)) ?? .current
    }

    var currencySettings: CurrencySettings? {
        guard let currencySettingsData else {
            return nil
        }
        return try? JSONDecoder().decode(CurrencySettings.self, from: currencySettingsData)
    }
}

struct StoreStatsStoredSite: Equatable {
    let siteID: Int64
    let name: String
    let timeZoneIdentifier: String?
    let gmtOffset: Double
    let isWooCommerceActive: Bool
    let supportsVisitorStats: Bool
}

enum StoreStatsSnapshotFactory {
    static func snapshots(storedSites: [StoreStatsStoredSite],
                          defaultSite: StoreStatsStoredSite?,
                          defaultSiteID: Int64?,
                          defaultCurrencySettingsData: Data?,
                          currencySettingsDataBySiteID: [Int64: Data] = [:],
                          exposesStorePicker: Bool) -> [StoreStatsSnapshot] {
        guard exposesStorePicker else {
            return []
        }

        let defaultID = defaultSiteID ?? defaultSite?.siteID
        var candidates = storedSites.filter { $0.isWooCommerceActive }
        if let defaultSite,
           defaultSite.isWooCommerceActive,
           candidates.contains(where: { $0.siteID == defaultSite.siteID }) == false {
            candidates.append(defaultSite)
        }

        var seenSiteIDs = Set<Int64>()
        return candidates
            .filter { site in
                guard seenSiteIDs.contains(site.siteID) == false else {
                    return false
                }
                seenSiteIDs.insert(site.siteID)
                return true
            }
            .compactMap { site in
                let isDefaultStore = site.siteID == defaultID
                let currencySettingsData = currencySettingsDataBySiteID[site.siteID] ?? (isDefaultStore ? defaultCurrencySettingsData : nil)
                guard isDefaultStore || currencySettingsData != nil else {
                    return nil
                }
                return StoreStatsSnapshot(
                    siteID: site.siteID,
                    name: site.name,
                    timeZoneIdentifier: site.timeZoneIdentifier,
                    gmtOffset: site.gmtOffset,
                    supportsVisitorStats: site.supportsVisitorStats,
                    isSelectableInStorePicker: true,
                    currencySettingsData: currencySettingsData
                )
            }
            .sorted { lhs, rhs in
                let lhsIsDefault = lhs.siteID == defaultID
                let rhsIsDefault = rhs.siteID == defaultID
                if lhsIsDefault != rhsIsDefault {
                    return lhsIsDefault
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}

struct StoreStatsSnapshotStore {
    private let userDefaults: UserDefaults?

    init(userDefaults: UserDefaults? = .group) {
        self.userDefaults = userDefaults
    }

    func snapshots() -> [StoreStatsSnapshot] {
        guard let data: Data = userDefaults?.object(forKey: .configurableStoreStatsWidgetStores) else {
            return defaultStoreSnapshot().map { [$0] } ?? []
        }

        guard let snapshots = try? JSONDecoder().decode([StoreStatsSnapshot].self, from: data) else {
            return defaultStoreSnapshot().map { [$0] } ?? []
        }

        return snapshots
    }

    func storePickerSnapshots() -> [StoreStatsSnapshot] {
        let defaultStoreID = defaultStoreID()
        return snapshots().filter { $0.isSelectableInStorePicker && ($0.siteID == defaultStoreID || $0.currencySettings != nil) }
    }

    func save(_ snapshots: [StoreStatsSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else {
            return
        }
        userDefaults?.set(data, forKey: .configurableStoreStatsWidgetStores)
    }

    func defaultStoreName() -> String? {
        defaultStoreSnapshot()?.name
    }

    func defaultStoreID() -> Int64? {
        userDefaults?.object(forKey: .defaultStoreID)
    }

    private func defaultStoreSnapshot() -> StoreStatsSnapshot? {
        guard let storeID: Int64 = userDefaults?.object(forKey: .defaultStoreID),
              let storeName: String = userDefaults?.object(forKey: .defaultStoreName) else {
            return nil
        }

        let currencySettingsData: Data? = userDefaults?.object(forKey: .defaultStoreCurrencySettings)
        return StoreStatsSnapshot(
            siteID: storeID,
            name: storeName,
            timeZoneIdentifier: nil,
            gmtOffset: 0,
            supportsVisitorStats: true,
            isSelectableInStorePicker: false,
            currencySettingsData: currencySettingsData
        )
    }
}

import Foundation
import WidgetKit

protocol WidgetSnapshotPersisting {
    var lastSnapshot: WidgetSnapshot? { get set }
}

struct UserDefaultsWidgetSnapshotPersistence: WidgetSnapshotPersisting {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var lastSnapshot: WidgetSnapshot? {
        get {
            guard let data = userDefaults.data(forKey: UserDefaults.Key.lastWidgetSnapshot.rawValue),
                  let dto = try? JSONDecoder().decode(PersistedSnapshot.self, from: data) else {
                return nil
            }
            return dto.toSnapshot()
        }
        nonmutating set {
            guard let newValue,
                  let data = try? JSONEncoder().encode(PersistedSnapshot(snapshot: newValue)) else {
                userDefaults.removeObject(forKey: UserDefaults.Key.lastWidgetSnapshot.rawValue)
                return
            }
            userDefaults.set(data, forKey: UserDefaults.Key.lastWidgetSnapshot.rawValue)
        }
    }
}

private struct PersistedSnapshot: Codable {
    let tiles: [PersistedTile]

    init(snapshot: WidgetSnapshot) {
        self.tiles = snapshot.tiles.map(PersistedTile.init(tile:))
    }

    func toSnapshot() -> WidgetSnapshot {
        WidgetSnapshot(tiles: tiles.compactMap { $0.toTile() })
    }
}

private struct PersistedTile: Codable {
    let kind: String
    let familyRawValue: Int
    let dateRange: String?
    let metrics: [String]?

    init(tile: WidgetSnapshot.Tile) {
        self.kind = tile.kind
        self.familyRawValue = tile.family.rawValue
        switch tile.configuration {
        case .storeStats(let dateRange, let metrics):
            self.dateRange = dateRange.rawValue
            self.metrics = metrics.map(\.rawValue)
        case .unconfigured:
            self.dateRange = nil
            self.metrics = nil
        }
    }

    func toTile() -> WidgetSnapshot.Tile? {
        guard let family = WidgetFamily(rawValue: familyRawValue) else {
            return nil
        }
        let configuration: WidgetSnapshot.Configuration
        if let dateRangeRaw = dateRange,
           let dateRange = StoreStatsWidgetDateRange(rawValue: dateRangeRaw),
           let metrics = metrics?.compactMap(StoreInfoMetricType.init(rawValue:)) {
            configuration = .storeStats(dateRange: dateRange, metrics: metrics)
        } else {
            configuration = .unconfigured
        }
        return WidgetSnapshot.Tile(kind: kind, family: family, configuration: configuration)
    }
}

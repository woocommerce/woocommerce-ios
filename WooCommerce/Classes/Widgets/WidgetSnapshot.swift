import Foundation
import WidgetKit

struct WidgetSnapshot: Equatable, Hashable {
    let tiles: [Tile]
}

extension WidgetSnapshot {
    init(from infos: [WidgetInfo]) {
        self.init(tiles: infos.compactMap(Tile.init(widgetInfo:)))
    }

    struct Tile: Equatable, Hashable {
        let kind: String
        let family: WidgetFamily
        let configuration: Configuration
    }

    enum Configuration: Equatable, Hashable {
        case storeStats(dateRange: StoreStatsWidgetDateRange, metrics: [StoreInfoMetricType])
        case unconfigured
    }
}

extension WidgetSnapshot.Tile {
    init(kind: String, family: WidgetFamily, intent: StoreStatsConfigurationIntent) {
        self.init(
            kind: kind,
            family: family,
            dateRange: intent.dateRange,
            metrics: StoreStatsConfigurationIntent.resolveMetricSelection(
                requested: intent.metrics,
                family: family
            )
        )
    }

    init(kind: String, family: WidgetFamily, intent: StoreTrendsConfigurationIntent) {
        self.init(
            kind: kind,
            family: family,
            dateRange: intent.dateRange,
            metrics: StoreTrendsConfigurationIntent.resolveMetricSelection(requested: intent.metrics)
        )
    }
}

private extension WidgetSnapshot.Tile {
    init?(widgetInfo info: WidgetInfo) {
        switch info.kind {
        case WooConstants.storeInfoWidgetKind:
            guard let intent = info.widgetConfigurationIntent(of: StoreStatsConfigurationIntent.self) else {
                return nil
            }
            self.init(kind: info.kind, family: info.family, intent: intent)
        case WooConstants.storeTrendsWidgetKind:
            guard let intent = info.widgetConfigurationIntent(of: StoreTrendsConfigurationIntent.self) else {
                return nil
            }
            self.init(kind: info.kind, family: info.family, intent: intent)
        default:
            return nil
        }
    }

    init(kind: String, family: WidgetFamily, dateRange: StoreStatsWidgetDateRange, metrics: [StoreInfoMetricType]) {
        self.init(kind: kind, family: family, configuration: .storeStats(dateRange: dateRange, metrics: metrics))
    }
}

extension WidgetSnapshot.Configuration {
    var isDefault: Bool? {
        switch self {
        case .storeStats(let dateRange, let metrics):
            let prefix = Array(StoreStatsConfigurationIntent.defaultMetrics.prefix(metrics.count))
            return dateRange == StoreStatsConfigurationIntent.defaultDateRange && metrics == prefix
        case .unconfigured:
            return nil
        }
    }
}

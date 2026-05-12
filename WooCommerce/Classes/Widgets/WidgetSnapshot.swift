import Foundation
import WidgetKit

struct WidgetSnapshot: Equatable, Hashable {
    let tiles: [Tile]
}

extension WidgetSnapshot {
    init(from infos: [WidgetInfo]) {
        self.init(tiles: infos.compactMap { info -> Tile? in
            guard Self.isStoreStatsWidgetKind(info.kind),
                  let intent = info.widgetConfigurationIntent(of: StoreStatsConfigurationIntent.self) else {
                return nil
            }
            let visibleMetrics = StoreStatsConfigurationIntent.resolveMetricSelection(
                requested: intent.metrics,
                family: info.family
            )
            return Tile(
                kind: info.kind,
                family: info.family,
                configuration: .storeStats(dateRange: intent.dateRange, metrics: visibleMetrics)
            )
        })
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

private extension WidgetSnapshot {
    static func isStoreStatsWidgetKind(_ kind: String) -> Bool {
        kind == WooConstants.storeInfoWidgetKind || kind == WooConstants.storeTrendsWidgetKind
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

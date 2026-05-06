import Foundation
import WidgetKit

struct WidgetSnapshot: Equatable, Hashable {
    let tiles: [Tile]
}

extension WidgetSnapshot {
    init(from result: Result<[WidgetInfo], Error>) {
        switch result {
        case .success(let infos):
            self.init(from: infos)
        case .failure:
            self.init(tiles: [])
        }
    }

    init(from infos: [WidgetInfo]) {
        self.init(tiles: infos.compactMap { info -> Tile? in
            guard info.kind == WooConstants.storeInfoWidgetKind,
                  let intent = info.widgetConfigurationIntent(of: StoreStatsConfigurationIntent.self) else {
                return nil
            }
            let slotCount = StoreStatsConfigurationIntent.metricsSlotCounts[info.family] ?? intent.metrics.count
            let visibleMetrics = Array(intent.metrics.prefix(slotCount))
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

import Foundation

extension WidgetSnapshot {
    var analyticsProperties: [String: String] {
        [
            "widget_count": "\(tiles.count)",
            "widget_customized_count": "\(tiles.filter { $0.configuration.isDefault == false }.count)",
            "widget_default_count": "\(tiles.filter { $0.configuration.isDefault == true }.count)",
            "info_widget_date_ranges_in_use": Self.uniqueStoreInfoDateRanges(in: tiles),
            "info_widget_metrics_in_use_combined": Self.uniqueStoreInfoMetrics(in: tiles)
        ]
    }

    private static func uniqueStoreInfoDateRanges(in tiles: [Tile]) -> String {
        let values = tiles.compactMap { tile -> String? in
            if case .storeStats(let dateRange, _) = tile.configuration {
                return dateRange.rawValue
            }
            return nil
        }
        return Set(values).sorted().joined(separator: ",")
    }

    private static func uniqueStoreInfoMetrics(in tiles: [Tile]) -> String {
        let values = tiles.flatMap { tile -> [String] in
            if case .storeStats(_, let metrics) = tile.configuration {
                return metrics.map(\.rawValue)
            }
            return []
        }
        return Set(values).sorted().joined(separator: ",")
    }
}

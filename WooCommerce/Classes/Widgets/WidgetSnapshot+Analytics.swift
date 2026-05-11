import Foundation

extension WidgetSnapshot.Tile {
    var analyticsName: String {
        "\(kind)-\(family)"
    }
}

extension WidgetSnapshot {
    var storeInfoDateRangesInUse: [String] {
        tiles.compactMap { tile -> String? in
            if case .storeStats(let dateRange, _) = tile.configuration {
                return dateRange.rawValue
            }
            return nil
        }
    }

    var storeInfoMetricsInUse: [String] {
        tiles.flatMap { tile -> [String] in
            if case .storeStats(_, let metrics) = tile.configuration {
                return metrics.map(\.rawValue)
            }
            return []
        }
    }

    var analyticsProperties: [String: String] {
        [
            "widget_count": "\(tiles.count)",
            "widget_customized_count": "\(tiles.filter { $0.configuration.isDefault == false }.count)",
            "widget_default_count": "\(tiles.filter { $0.configuration.isDefault == true }.count)",
            "info_widget_date_ranges_in_use": storeInfoDateRangesInUse.sorted().joined(separator: ","),
            "info_widget_metrics_in_use": storeInfoMetricsInUse.sorted().joined(separator: ",")
        ]
    }
}

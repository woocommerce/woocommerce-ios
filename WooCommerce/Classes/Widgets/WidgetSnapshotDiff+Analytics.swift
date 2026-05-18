import Foundation

extension WidgetSnapshotDiff {
    /// Conditional payload merged into `application_opened` when the widget setup changed
    /// since the last persisted snapshot. Empty `*_added` / `*_removed` properties are omitted.
    var analyticsProperties: [String: String] {
        var properties: [String: String] = [
            "widget_setup_change_type": changeType.rawValue,
            "previous_widget_count": "\(previous.tiles.count)"
        ]
        let dateRangesAdded = addedDateRanges.joined(separator: ",")
        if !dateRangesAdded.isEmpty {
            properties["info_widget_date_ranges_added"] = dateRangesAdded
        }
        let dateRangesRemoved = removedDateRanges.joined(separator: ",")
        if !dateRangesRemoved.isEmpty {
            properties["info_widget_date_ranges_removed"] = dateRangesRemoved
        }
        let metricsAdded = addedMetrics.joined(separator: ",")
        if !metricsAdded.isEmpty {
            properties["info_widget_metrics_added"] = metricsAdded
        }
        let metricsRemoved = removedMetrics.joined(separator: ",")
        if !metricsRemoved.isEmpty {
            properties["info_widget_metrics_removed"] = metricsRemoved
        }
        let widgetsAdded = addedWidgets.joined(separator: ",")
        if !widgetsAdded.isEmpty {
            properties["widgets_added"] = widgetsAdded
        }
        let widgetsRemoved = removedWidgets.joined(separator: ",")
        if !widgetsRemoved.isEmpty {
            properties["widgets_removed"] = widgetsRemoved
        }
        return properties
    }
}

import Foundation
import WooFoundationCore

extension WooAnalyticsEvent.Widgets {
    static func setupChanged(diff: WidgetSnapshotDiff) -> WooAnalyticsEvent {
        var properties: [String: WooAnalyticsEventPropertyType] = [
            "previous_widget_count": diff.previous.tiles.count,
            "current_widget_count": diff.current.tiles.count,
            "change_type": diff.changeType.rawValue
        ]

        let dateRangesAdded = diff.addedDateRanges.joined(separator: ",")
        if !dateRangesAdded.isEmpty {
            properties["info_widget_date_ranges_added"] = dateRangesAdded
        }
        let dateRangesRemoved = diff.removedDateRanges.joined(separator: ",")
        if !dateRangesRemoved.isEmpty {
            properties["info_widget_date_ranges_removed"] = dateRangesRemoved
        }
        let metricsAdded = diff.addedMetrics.joined(separator: ",")
        if !metricsAdded.isEmpty {
            properties["info_widget_metrics_added"] = metricsAdded
        }
        let metricsRemoved = diff.removedMetrics.joined(separator: ",")
        if !metricsRemoved.isEmpty {
            properties["info_widget_metrics_removed"] = metricsRemoved
        }
        let widgetsAdded = diff.addedWidgets.joined(separator: ",")
        if !widgetsAdded.isEmpty {
            properties["widgets_added"] = widgetsAdded
        }
        let widgetsRemoved = diff.removedWidgets.joined(separator: ",")
        if !widgetsRemoved.isEmpty {
            properties["widgets_removed"] = widgetsRemoved
        }

        return WooAnalyticsEvent(statName: .widgetSetupChanged, properties: properties)
    }
}

import WidgetKit
import Foundation

enum StatsWidgetEntry: TimelineEntry {
    case error
    case siteSelected(siteName: String, data: StatsWidgetData)
    case noSite

    var date: Date {
        Date()
    }
}

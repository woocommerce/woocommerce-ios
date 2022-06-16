import WidgetKit
import Foundation

/// Different types of entry with which we can populate a widget
enum StatsWidgetEntry: TimelineEntry {
    // There was an error when loading the data
    case error
    // The user already selected a store. We encapsulate the data to be shown with this case
    case siteSelected(siteName: String, data: StatsWidgetData)
    // The user did not choose any store yet
    case noSite

    var date: Date {
        Date()
    }
}

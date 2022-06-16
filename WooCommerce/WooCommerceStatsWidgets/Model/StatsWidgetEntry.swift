import WidgetKit
import Foundation

/// Different types of entry with which we can populate a widget
enum StatsWidgetEntry: TimelineEntry {
    // There was an error when loading the data
    case error
    // The user already selected a store. We encapsulate the data to be shown with this case
    case storeSelected(storeName: String, data: StatsWidgetData)
    // The user did not choose any store yet
    case noStoreSelected

    var date: Date {
        Date()
    }
}

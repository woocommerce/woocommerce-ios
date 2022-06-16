import Foundation

// Encapsulates the stats to be shown on the widget
struct StatsWidgetData {
    let revenue: Decimal
    let orders: Int
    // Optional because the user might not have access to this data
    let visitors: Int?
}

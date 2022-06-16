import WidgetKit
import SwiftUI
import Foundation

@main
struct WordPressStatsWidgets: WidgetBundle {
    var body: some Widget {
        WooCommerceTodayStatsWidget()
        WooCommerceThisWeekStatsWidget()
    }
}

import Foundation

extension WooAnalyticsEvent {
    enum DashboardCustomRange {

        private enum Keys {
            static let isEditing = "is_editing"
        }

        /// When the user taps the button to add a custom range.
        static func addButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardStatsCustomRangeAddButtonTapped, properties: [:])
        }

        /// When the user confirms a date range for a custom range tab.
        static func customRangeConfirmed(isEditing: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardStatsCustomRangeConfirmed,
                              properties: [Keys.isEditing: isEditing])
        }

        /// When the user selects the custom range tab of Dashboard stats.
        static func tabSelected() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardStatsCustomRangeTabSelected, properties: [:])
        }

        /// When the user taps the button to edit the date range on the custom range tab of Dashboard stats.
        static func editButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardStatsCustomRangeEditButtonTapped, properties: [:])
        }

        /// When the user taps on the chart on custom range to see metrics for specific periods.
        static func interacted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardStatsCustomRangeInteracted, properties: [:])
        }
    }
}

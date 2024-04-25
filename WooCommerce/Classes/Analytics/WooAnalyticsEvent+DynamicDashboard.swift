import Foundation
import struct Yosemite.DashboardCard

extension WooAnalyticsEvent {
    enum DynamicDashboard {
        private enum Keys: String {
            case type
            case sections
        }

        /// When the user taps the button to edit the dashboard layout.
        static func editLayoutButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditLayoutButtonTapped, properties: [:])
        }

        /// When the user taps on the Hide button in the ellipsis menu of any dashboard section
        static func hideSectionTapped(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardHideSectionTapped, 
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user changes the order of a section in the layout editor.
        static func editorReorderSection(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditorReorderSection, 
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the button to include a section on the dashboard in the layout editor.
        static func editorShowSection(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditorShowSection, 
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the button to exclude a section on the dashboard in the layout editor.
        static func editorHideSection(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditorHideSection, 
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the Save button to in the layout editor.
        static func editorSaveTapped(types: [DashboardCard.CardType]) -> WooAnalyticsEvent {
            let typeNames = types.map { $0.analyticName }.sorted().joined(separator: ",")
            return WooAnalyticsEvent(statName: .dynamicDashboardEditorSaveTapped,
                                     properties: [Keys.sections.rawValue: typeNames])
        }
    }
}

extension DashboardCard.CardType {
    var analyticName: String {
        switch self {
        case .onboarding:
            "store_setup"
        case .blaze:
            "blaze"
        case .performance:
            "performance"
        case .topPerformers:
            "top_performers"
        }
    }
}

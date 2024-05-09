import Foundation
import struct Yosemite.DashboardCard
import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    enum DynamicDashboard {
        private enum Keys: String {
            case type
            case cards
        }

        /// When the user taps the button to edit the dashboard layout.
        static func editLayoutButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditLayoutButtonTapped, properties: [:])
        }

        /// When the user taps on the Hide button in the ellipsis menu of any dashboard card
        static func hideCardTapped(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardHideCardTapped,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the Save button to in the layout editor.
        static func editorSaveTapped(types: [DashboardCard.CardType]) -> WooAnalyticsEvent {
            let typeNames = types.map { $0.analyticName }.sorted().joined(separator: ",")
            return WooAnalyticsEvent(statName: .dynamicDashboardEditorSaveTapped,
                                     properties: [Keys.cards.rawValue: typeNames])
        }

        /// When the user taps the Retry button on the error state view of any dashboard card.
        static func cardRetryTapped(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardRetryTapped,
                              properties: [Keys.type.rawValue: type.analyticName])
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

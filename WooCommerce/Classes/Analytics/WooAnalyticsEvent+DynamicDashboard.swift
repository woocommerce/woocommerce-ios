import Foundation
import struct Yosemite.DashboardCard

extension WooAnalyticsEvent {
    enum DynamicDashboard {
        private enum Keys: String {
            case type
            case cards
            case newCardAvailable = "new_card_available"
            case sortedCards = "sorted_cards"
        }

        /// When the user taps the button to edit the dashboard layout.
        static func editLayoutButtonTapped(isNewCardAvailable: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardEditLayoutButtonTapped,
                              properties: [Keys.newCardAvailable.rawValue: isNewCardAvailable])
        }

        /// When the user taps on the Hide button in the ellipsis menu of any dashboard card
        static func hideCardTapped(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardHideCardTapped,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the Save button to in the layout editor.
        static func editorSaveTapped(types: [DashboardCard.CardType]) -> WooAnalyticsEvent {
            let typeNamesUserSorted = types.map { $0.analyticName }
            let typeNamesAlphabeticallySorted = typeNamesUserSorted.sorted()
            return WooAnalyticsEvent(
                statName: .dynamicDashboardEditorSaveTapped,
                properties: [
                    Keys.cards.rawValue: typeNamesAlphabeticallySorted.joined(separator: ","),
                    Keys.sortedCards.rawValue: typeNamesUserSorted.joined(separator: ","),
                ].compactMapValues { $0 }
            )
        }

        /// When the user taps the Retry button on the error state view of any dashboard card.
        static func cardRetryTapped(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardRetryTapped,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user interacts with the dashboard cards by tapping on any action buttons.
        static func dashboardCardInteracted(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardInteracted,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When the user taps the Add new sections button on the new cards suggestion.
        static func dashboardCardAddNewSectionsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardAddNewSectionsTapped, properties: [:])
        }

        /// When a dashboard card starts loading data.
        static func cardLoadingStarted(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardDataLoadingStarted,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When a dashboard card completes loading data without error
        static func cardLoadingCompleted(type: DashboardCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardDataLoadingCompleted,
                              properties: [Keys.type.rawValue: type.analyticName])
        }

        /// When a dashboard card fails to load data
        static func cardLoadingFailed(type: DashboardCard.CardType, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dynamicDashboardCardDataLoadingFailed,
                              properties: [Keys.type.rawValue: type.analyticName],
                              error: error)
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
        case .inbox:
            "inbox"
        case .stock:
            "stock"
        case .reviews:
            "reviews"
        case .lastOrders:
            "orders"
        case .coupons:
            "coupons"
        case .googleAds:
            "google-ads"
        }
    }
}

import SwiftUI
import Yosemite

final class MarketingToolsViewModel: ObservableObject {
    /// List of marketing events
    @Published private(set) var events: [MarketingEvent] = []

    /// Currently selected event for detail view
    @Published var selectedEvent: MarketingEvent?

    /// Site ID for this marketing tools instance
    let siteID: Int64

    private let stores: StoresManager

    /// Store timezone for event scheduling
    var storeTimezone: TimeZone {
        guard let site = stores.sessionManager.defaultSite,
              let timezone = TimeZone(identifier: site.timezone) else {
            return .current
        }
        return timezone
    }

    init(
        siteID: Int64,
        stores: StoresManager = ServiceLocator.stores
    ) {
        self.siteID = siteID
        self.stores = stores
        loadEvents()
    }

    /// Loads preset marketing events for the current year
    func loadEvents() {
        let currentYear = Calendar.current.component(.year, from: Date())
        events = MarketingEvent.presetEvents(for: currentYear)
    }

    /// Loads suggested marketing events for the current year
    func loadSuggestedEvents() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let suggestedEvents = MarketingEvent.suggestedEvents(for: currentYear)

        // Add suggested events that don't already exist
        for event in suggestedEvents {
            if !events.contains(where: { $0.id == event.id }) {
                events.append(event)
            }
        }
    }

    /// Handles create event action (placeholder for now)
    func createEvent() {
        // TODO: Navigate to event creation form
    }

    /// Returns available actions for a given event
    func availableActions(for event: MarketingEvent) -> [MarketingAction] {
        MarketingAction.availableActions(for: event)
    }

    /// Handles action selection and navigates to appropriate screen
    func handleActionTap(action: MarketingAction, for event: MarketingEvent) {
        switch action.type {
        case .editProduct:
            // Navigate to Products tab
            MainTabBarController.switchToProductsTab()

        case .createCoupon:
            // Navigate to Hub Menu's coupon section
            MainTabBarController.switchToHubMenuTab { hubMenuViewController in
                hubMenuViewController?.showCoupons()
            }
        }
    }
}

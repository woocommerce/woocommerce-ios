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
    private let notificationScheduler: MarketingEventNotificationScheduling

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
        stores: StoresManager = ServiceLocator.stores,
        notificationScheduler: MarketingEventNotificationScheduling = MarketingEventNotificationScheduler()
    ) {
        self.siteID = siteID
        self.stores = stores
        self.notificationScheduler = notificationScheduler
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

                // Schedule notification for this event
                Task {
                    await notificationScheduler.scheduleNotification(for: event, daysBeforeEvent: 3)
                }
            }
        }
    }

    /// Loads AI-generated event suggestions using Foundation Models
    @available(iOS 26.0, *)
    func loadSuggestedEventsWithAI() {
        Task {
            let aiEvents = await generateAIEventSuggestions()

            // Add AI-generated events that don't already exist
            for event in aiEvents {
                if !events.contains(where: { $0.id == event.id }) {
                    events.append(event)

                    // Schedule notification for this event
                    await notificationScheduler.scheduleNotification(for: event, daysBeforeEvent: 3)
                }
            }
        }
    }

    /// Generates event suggestions using Foundation Models
    @available(iOS 26.0, *)
    private func generateAIEventSuggestions() async -> [MarketingEvent] {
        // TODO: Implement Foundation Models integration
        // For now, fall back to hardcoded events
        // Later:
        // 1. Use SystemLanguageModel to generate event names/dates
        // 2. Consider store category, current date, seasonality

        let currentYear = Calendar.current.component(.year, from: Date())
        return MarketingEvent.suggestedEvents(for: currentYear)
    }

    /// Creates a new custom marketing event and adds it to the events list
    func createEvent(name: String, date: Date) {
        let newEvent = MarketingEvent(
            id: UUID().uuidString,
            name: name,
            date: date,
            type: .custom
        )
        events.append(newEvent)

        // Schedule notification for this event (3 days before)
        Task {
            await notificationScheduler.scheduleNotification(for: newEvent, daysBeforeEvent: 3)
        }
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

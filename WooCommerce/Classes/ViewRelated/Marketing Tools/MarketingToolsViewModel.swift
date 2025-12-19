import SwiftUI
import Yosemite

#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
/// Represents a single AI-generated event suggestion
@available(iOS 26.0, *)
@Generable
struct AIEventSuggestion {
    @Guide(description: "Name of the marketing event, under 50 characters")
    let eventName: String

    @Guide(description: "Date of the event in ISO 8601 format (YYYY-MM-DD)")
    let eventDate: String

    @Guide(description: "Type of event: black_friday, holiday_sale, or seasonal_promotion")
    let eventType: String

    @Guide(description: "Brief reason why this event is relevant, under 100 characters")
    let reasoning: String
}

/// Container for multiple AI-generated event suggestions
@available(iOS 26.0, *)
@Generable
struct AIEventSuggestions {
    @Guide(description: "Array of 2-4 relevant marketing events for the upcoming months")
    let suggestions: [AIEventSuggestion]
}
#endif


final class MarketingToolsViewModel: ObservableObject {
    /// List of marketing events
    @Published private(set) var events: [MarketingEvent] = []

    /// Currently selected event for detail view
    @Published var selectedEvent: MarketingEvent?

    /// Site ID for this marketing tools instance
    let siteID: Int64

    private let stores: StoresManager
    private let notificationScheduler: MarketingEventNotificationScheduling

    /// Language model session for AI event generation
    #if canImport(FoundationModels)
    private var languageModelSession: LanguageModelSession?
    #endif

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

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if SystemLanguageModel.default.availability == .available {
                languageModelSession = LanguageModelSession {
                    """
                    You're a marketing assistant for WooCommerce store owners.
                    Generate relevant marketing event suggestions based on:
                    - Current date and upcoming seasons
                    - Major retail holidays (Black Friday, Cyber Monday, Christmas, New Year, Valentine's Day, Mother's Day, etc.)
                    - Seasonal events (Spring Sale, Summer Sale, Back to School, Holiday Season)
                    - Industry-standard sales events

                    Focus on actionable events that merchants can prepare for.
                    Events should be within the next 3-6 months.
                    Provide specific dates and clear event names.
                    """
                }
            }
        }
        #endif

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

    @available(iOS 26.0, *)
    private func generateAIEventSuggestions() async -> [MarketingEvent] {
        #if canImport(FoundationModels)
        // Check if language model session is available
        guard let session = languageModelSession else {
            DDLogInfo("Language model session not available, falling back to hardcoded events")
            let currentYear = Calendar.current.component(.year, from: Date())
            return MarketingEvent.suggestedEvents(for: currentYear)
        }

        // Prepare context for AI generation
        let currentDate = Date()
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        let currentDateString = dateFormatter.string(from: currentDate)

        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        let timezoneIdentifier = storeTimezone.identifier

        // Build prompt with rich context
        let prompt = """
        Current date: \(currentDateString)
        Current month: \(currentMonth)
        Current year: \(currentYear)
        Store timezone: \(timezoneIdentifier)

        Generate 2-4 relevant marketing events for a WooCommerce store owner to prepare for.
        Consider:
        - Upcoming major retail holidays (Black Friday, Cyber Monday, Christmas, New Year, Valentine's Day, Mother's Day, Father's Day)
        - Seasonal events (Spring Sale, Summer Sale, Back to School, Holiday Season)
        - Industry events within the next 3-6 months
        - Current season and upcoming seasons

        For each event:
        - Provide a clear, actionable event name
        - Specify the exact date in YYYY-MM-DD format
        - Classify the event type (black_friday, holiday_sale, or seasonal_promotion)
        - Explain briefly why this event is relevant now

        Focus on events that are coming up soon and that merchants should start preparing for.
        """

        do {
            // Generate AI suggestions
            DDLogInfo("Generating AI event suggestions with Foundation Models")
            let response = try await session.respond(
                to: prompt,
                generating: AIEventSuggestions.self
            )

            DDLogInfo("AI generated \(response.suggestions.count) event suggestions")

            // Convert AI suggestions to MarketingEvent objects
            let events = response.suggestions.compactMap { suggestion in
                convertAISuggestionToEvent(suggestion, calendar: calendar)
            }

            // If AI generated events successfully, return them
            if !events.isEmpty {
                DDLogInfo("Successfully converted \(events.count) AI suggestions to events")
                return events
            }

            // If conversion failed, fall back to hardcoded
            DDLogWarn("AI event conversion produced no events, falling back to hardcoded")
            return MarketingEvent.suggestedEvents(for: currentYear)

        } catch {
            // On error, fall back to hardcoded events
            DDLogError("Failed to generate AI event suggestions: \(error.localizedDescription)")
            let currentYear = calendar.component(.year, from: currentDate)
            return MarketingEvent.suggestedEvents(for: currentYear)
        }
        #else
        // FoundationModels not available, fall back to hardcoded events
        let currentYear = Calendar.current.component(.year, from: Date())
        return MarketingEvent.suggestedEvents(for: currentYear)
        #endif
    }

    #if canImport(FoundationModels)
    /// Converts an AI-generated event suggestion into a MarketingEvent
    /// - Parameters:
    ///   - suggestion: The AI-generated suggestion
    ///   - calendar: Calendar to use for date parsing
    /// - Returns: A MarketingEvent if conversion succeeds, nil otherwise
    @available(iOS 26.0, *)
    private func convertAISuggestionToEvent(
        _ suggestion: AIEventSuggestion,
        calendar: Calendar
    ) -> MarketingEvent? {
        // Parse the ISO 8601 date string
        let dateFormatter = ISO8601DateFormatter()
        guard let eventDate = dateFormatter.date(from: suggestion.eventDate) else {
            DDLogWarn("Failed to parse event date: \(suggestion.eventDate)")
            return nil
        }

        // Determine event type based on AI classification
        let eventType: MarketingEvent.EventType
        let lowercasedType = suggestion.eventType.lowercased()

        if lowercasedType.contains("black") && lowercasedType.contains("friday") {
            eventType = .blackFriday
        } else if lowercasedType.contains("holiday") || lowercasedType.contains("christmas") {
            eventType = .holidaySale
        } else {
            eventType = .custom
        }

        // Generate a stable ID based on event type and date
        let id = "ai-\(suggestion.eventType.lowercased())-\(suggestion.eventDate)"

        DDLogInfo("Converted AI suggestion: \(suggestion.eventName) on \(suggestion.eventDate) (type: \(eventType))")

        return MarketingEvent(
            id: id,
            name: suggestion.eventName,
            date: eventDate,
            type: eventType
        )
    }
    #endif

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

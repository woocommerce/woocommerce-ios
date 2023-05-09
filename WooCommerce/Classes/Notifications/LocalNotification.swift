import Foundation

/// Content for a local notification to be converted to `UNNotificationContent`.
struct LocalNotification {
    let title: String
    let body: String
    let scenario: Scenario
    let actions: CategoryActions?

    /// A category of actions in a notification.
    struct CategoryActions {
        let category: Category
        let actions: [Action]
    }

    /// The scenario for the local notification.
    /// Its raw value is used for the identifier of a local notification and also the event property for analytics.
    enum Scenario: String, CaseIterable {
        case storeCreationComplete = "store_creation_complete"
        case oneDayAfterStoreCreationNameWithoutFreeTrial = "one_day_after_store_creation_name_without_free_trial"
        case oneDayBeforeFreeTrialExpires = "one_day_before_free_trial_expires"
        case oneDayAfterFreeTrialExpires = "one_day_after_free_trial_expires"
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case storeCreation
    }

    /// The action type in a local notification.
    enum Action: String {
        // TODO: 9665 - determine if there are any custom actions
        case none

        /// The title of the action in a local notification.
        var title: String {
            switch self {
            case .none:
                return ""
            }
        }
    }
}

extension LocalNotification {
    init(scenario: Scenario) {
        // TODO: 9665 - Copy TBD for each notification
        self.init(title: scenario.rawValue,
                  body: "",
                  scenario: scenario,
                  actions: .init(category: .storeCreation, actions: []))
    }
}

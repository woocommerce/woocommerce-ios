import struct Yosemite.StoreOnboardingTask

extension WooAnalyticsEvent {
    enum StoreOnboarding {
        /// Event property Key.
        private enum Key {
            static let task = "task"
            static let pendingTasks = "pending_tasks"
            static let source = "source"
        }

        static func storeOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingShown, properties: [:])
        }

        static func storeOnboardingTaskTapped(task: StoreOnboardingTask.TaskType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingTaskTapped, properties: [Key.task: task.analyticsValue])
        }

        static func storeOnboardingTaskCompleted(task: StoreOnboardingTask.TaskType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingTaskCompleted, properties: [Key.task: task.analyticsValue])
        }

        static func storeOnboardingCompleted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingCompleted, properties: [:])
        }

        static func storeOnboardingHideList(source: Source, pendingTasks: [StoreOnboardingTask.TaskType]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingHideList,
                              properties: [Key.source: source.rawValue,
                                           Key.pendingTasks: pendingTasks.map({ $0.analyticsValue }).sorted().joined(separator: ",")])
        }
    }
}

extension WooAnalyticsEvent.StoreOnboarding {
    enum Source: String {
        case onboardingList = "onboarding_list"
        case settings
    }
}

private extension StoreOnboardingTask.TaskType {
    var analyticsValue: String {
        switch self {
        case .storeDetails:
            return "store_details"
        case .launchStore:
            return "launch_site"
        case .addFirstProduct:
            return "products"
        case .customizeDomains:
            return "add_domain"
        case .payments, .woocommercePayments:
            return "payments"
        case .unsupported(let task):
            return task
        }
    }
}

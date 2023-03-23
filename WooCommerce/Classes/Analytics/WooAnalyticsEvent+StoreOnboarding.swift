import struct Yosemite.StoreOnboardingTask

extension WooAnalyticsEvent {
    enum StoreOnboarding {
        /// Event property keys.
        private enum Keys {
            static let task = "task"
        }

        static func storeOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingShown, properties: [:])
        }

        static func storeOnboardingTaskTapped(task: StoreOnboardingTask.TaskType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingTaskTapped, properties: [Keys.task: task.analyticsValue])
        }

        static func storeOnboardingTaskCompleted(task: StoreOnboardingTask.TaskType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingTaskCompleted, properties: [Keys.task: task.analyticsValue])
        }

        static func storeOnboardingCompleted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeOnboardingCompleted, properties: [:])
        }
    }
}

private extension StoreOnboardingTask.TaskType {
    var analyticsValue: String {
        switch self {
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

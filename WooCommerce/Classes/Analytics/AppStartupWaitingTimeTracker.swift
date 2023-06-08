import Foundation

/// Tracks the waiting time for app startup, allowing to evaluate as analytics
/// how much time in seconds it took between the init and the final `end` function call
///
final class AppStartupWaitingTimeTracker: WaitingTimeTracker {
    /// Represents all of the app startup actions that are waiting to be completed.
    ///
    /// This begins with all app startup actions, with each action removed as it ends.
    ///
    private var appStartupWaitingActions = AppStartupAction.allCases

    /// NotificationCenter Tokens
    ///
    private var trackingObservers: [NSObjectProtocol]?

    /// NotificationCenter
    ///
    private let notificationCenter: NotificationCenter

    /// All actions that must be waited for on app startup.
    ///
    enum AppStartupAction: CaseIterable {
        case validateRoleEligibility
        case checkFeatureAnnouncements
        case restoreSessionSite
        case syncEntities
        case checkMinimumWooVersion
        case syncDashboardStats
        case syncTopPerformers
        case fetchExperimentAssignments
        case syncJITMs
        case syncPaymentConnectionTokens

        var notificationName: NSNotification.Name {
            switch self {
            case .validateRoleEligibility:
                return .RoleEligibilityValidated
            case .checkFeatureAnnouncements:
                return .FeatureAnnouncementsChecked
            case .restoreSessionSite:
                return .SessionSiteRestored
            case .syncEntities:
                return .EntitiesSynchronized
            case .checkMinimumWooVersion:
                return .MinimumWooVersionChecked
            case .syncDashboardStats:
                return .DashboardStatsSynced
            case .syncTopPerformers:
                return .TopPerformersSynced
            case .fetchExperimentAssignments:
                return .ExperimentAssignmentsFetched
            case .syncJITMs:
                return .JITMsSynced
            case .syncPaymentConnectionTokens:
                return .PaymentConnectionTokensSynced
            }
        }
    }

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter

        super.init(trackScenario: .appStartup)

        startListeningToNotifications()
    }

    /// Starts listening for Notifications
    ///
    func startListeningToNotifications() {
        for startupAction in AppStartupAction.allCases {
            let observer = notificationCenter.addObserver(forName: startupAction.notificationName, object: nil, queue: .main) { [weak self] _ in
                self?.end(startupAction)
            }
            trackingObservers?.append(observer)
        }
    }

    /// End the waiting time for the provided startup action.
    /// If all startup actions are completed, evaluate the elapsed time from the init,
    /// and send it as an analytics event.
    ///
    func end(_ appStartupAction: AppStartupAction) {
        guard appStartupWaitingActions.isNotEmpty else {
            return
        }
        appStartupWaitingActions.removeAll { $0 == appStartupAction }
        if appStartupWaitingActions.isEmpty {
            print("*** App startup complete. ***")
            // TODO: Call super.end() to fire the analytics event
        }
    }
}

// MARK: App Startup Notifications
//
extension NSNotification.Name {
    static let RoleEligibilityValidated = NSNotification.Name(rawValue: "RoleEligibilityValidated")
    static let FeatureAnnouncementsChecked = NSNotification.Name(rawValue: "FeatureAnnouncementsChecked")
    static let SessionSiteRestored = NSNotification.Name(rawValue: "SessionSiteRestored")
    static let EntitiesSynchronized = NSNotification.Name(rawValue: "EntitiesSynchronized")
    static let MinimumWooVersionChecked = NSNotification.Name(rawValue: "MinimumWooVersionChecked")
    static let DashboardStatsSynced = NSNotification.Name(rawValue: "DashboardStatsSynced")
    static let TopPerformersSynced = NSNotification.Name(rawValue: "TopPerformersSynced")
    static let ExperimentAssignmentsFetched = NSNotification.Name(rawValue: "ExperimentAssignmentsFetched")
    static let JITMsSynced = NSNotification.Name(rawValue: "JITMsSynced")
    static let PaymentConnectionTokensSynced = NSNotification.Name(rawValue: "PaymentConnectionTokensSynced")
}

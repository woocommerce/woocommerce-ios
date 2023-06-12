import Foundation
import Yosemite

/// Tracks the waiting time for app startup, allowing to evaluate as analytics
/// how much time in seconds it took between the init and the final `end` function call
///
final class AppStartupWaitingTimeTracker: WaitingTimeTracker {

    /// The status of an app startup action
    ///
    public enum ActionStatus: String {
        case started
        case completed
    }

    /// Represents all of the app startup actions that are waiting to be completed.
    ///
    private var startupActionsPending = [Notification.Name]()

    /// Represents all of the app startup actions to observe notifications for.
    ///
    /// Not all of these actions will be triggered every time the app is started,
    /// but they are all possible startup actions that contribute to the startup waiting time.
    /// Actions can be added or removed from this list to include or exclude them from the waiting time calculation.
    ///
    private let startupActionsToObserve: [NSNotification.Name] = [
        .launchApp, // Ensures tracker doesn't end before all launch actions are started
        .validateRoleEligibility,
        .checkFeatureAnnouncements,
        .restoreSessionSite,
        .synchronizeEntities,
        .checkMinimumWooVersion,
        .syncDashboardStats,
        .syncTopPerformers,
        .fetchExperimentAssignments,
        .syncJITMs,
        .syncPaymentConnectionTokens
    ]

    /// NotificationCenter
    ///
    private let notificationCenter: NotificationCenter

    /// Stores Manager
    ///
    private let stores: StoresManager

    init(notificationCenter: NotificationCenter = .default,
         stores: StoresManager = ServiceLocator.stores,
         analyticsService: Analytics = ServiceLocator.analytics,
         currentTimeInMillis: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.notificationCenter = notificationCenter
        self.stores = stores

        super.init(trackScenario: .appStartup, analyticsService: analyticsService, currentTimeInMillis: currentTimeInMillis)

        startListeningToNotifications()
    }

    /// Triggers a notification for the start or end of the provided startup action.
    ///
    static func notify(action: NSNotification.Name, withStatus status: ActionStatus, notificationCenter: NotificationCenter = .default) {
        notificationCenter.post(name: action, object: status)
    }

    /// Start listening to notifications that may occur on app startup.
    ///
    private func startListeningToNotifications() {
        for startupAction in startupActionsToObserve {
            notificationCenter.addObserver(self, selector: #selector(observeNotification), name: startupAction, object: nil)
        }
    }

    /// Handle the notifications as they are observed.
    ///
    @objc private func observeNotification(for notification: Notification) {
        guard let status = (notification.object as? ActionStatus) ?? (notification.object as? String).flatMap(ActionStatus.init(rawValue:)) else {
            return
        }

        switch status {
        case .started:
            start(notification.name)
        case .completed:
            end(notification.name)
        }
    }

    /// Start tracking the provided startup action.
    ///
    private func start(_ startupAction: Notification.Name) {
        startupActionsPending.append(startupAction)
    }

    /// End the waiting time for the provided startup action.
    /// If all startup actions are completed, evaluate the elapsed time from the init,
    /// and send it as an analytics event.
    ///
    private func end(_ startupAction: Notification.Name) {
        startupActionsPending.removeAll { $0 == startupAction }

        // End the waiting time tracker when no more actions are pending
        if startupActionsPending.isEmpty {
            notificationCenter.removeObserver(self) // Stop listening to any notifications
            guard stores.isAuthenticated else { // Don't track the waiting time if the user is logged out
                return
            }
            super.end() // Calculate the elapsed time and trigger analytics event
        }
    }
}

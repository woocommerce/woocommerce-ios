import Foundation

final class TrackEventRequestNotificationHandler {

    /// NotificationCenter Tokens for tracking Analytics event
    ///
    private var trackingObservers: [NSObjectProtocol]?

    /// NotificationCenter
    ///
    private let notificationCenter: NotificationCenter

    /// Analytics
    ///
    private let analytics: Analytics

    init(notificationCenter: NotificationCenter = .default,
         analytics: Analytics = ServiceLocator.analytics) {
        self.notificationCenter = notificationCenter
        self.analytics = analytics
        startListeningToNotifications()
    }
}

private extension TrackEventRequestNotificationHandler {
    /// Starts listening for Notifications
    ///
    func startListeningToNotifications() {
        let newPasswordCreatedObserver = notificationCenter.addObserver(forName: .ApplicationPasswordsNewPasswordCreated,
                                                                        object: nil,
                                                                        queue: .main) { [weak self] note in
            self?.trackApplicationPasswordsNewPasswordCreated(note: note)
        }

        let passwordGenerationFailedObserver = notificationCenter.addObserver(forName: .ApplicationPasswordsGenerationFailed,
                                                                              object: nil,
                                                                              queue: .main) { [weak self] note in
            self?.trackApplicationPasswordsGenerationFailed(note: note)
        }

        trackingObservers = [newPasswordCreatedObserver, passwordGenerationFailedObserver]
    }

    /// Tracks an event when an application password is created
    ///
    func trackApplicationPasswordsNewPasswordCreated(note: Notification) {
        analytics.track(event: .ApplicationPassword.applicationPasswordGeneratedSuccessfully(scenario: .regeneration))
    }

    /// Tracks an event when generating an application password fails
    ///
    func trackApplicationPasswordsGenerationFailed(note: Notification) {
        guard let error = note.object as? Error else {
            return
        }
        analytics.track(event: .ApplicationPassword.applicationPasswordGenerationFailed(scenario: .regeneration, error: error))
    }
}

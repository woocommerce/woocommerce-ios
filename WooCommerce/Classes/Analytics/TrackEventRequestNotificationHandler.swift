import Foundation
import class Networking.Remote
import enum Yosemite.ApplicationPasswordGenerationUserInfoKey
import protocol WooFoundation.Analytics
import UIKit

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

    private let applicationStateProvider: @MainActor @Sendable () -> UIApplication.State

    init(notificationCenter: NotificationCenter = .default,
         analytics: Analytics = ServiceLocator.analytics,
         applicationStateProvider: @escaping @MainActor @Sendable () -> UIApplication.State = { UIApplication.shared.applicationState }) {
        self.notificationCenter = notificationCenter
        self.analytics = analytics
        self.applicationStateProvider = applicationStateProvider
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

        let jsonParsingFailedObserver = notificationCenter.addObserver(forName: .RemoteDidReceiveJSONParsingError,
                                                                   object: nil,
                                                                   queue: .main) { [weak self] note in
            self?.trackJSONParsingFailed(note: note)
        }

        trackingObservers = [
            newPasswordCreatedObserver,
            passwordGenerationFailedObserver,
            jsonParsingFailedObserver
        ]
    }

    /// Tracks an event when an application password is created
    ///
    func trackApplicationPasswordsNewPasswordCreated(note: Notification) {
        analytics.track(event: .ApplicationPassword.applicationPasswordGeneratedSuccessfully(scenario: scenario(of: note)))
    }

    /// Tracks an event when generating an application password fails
    ///
    func trackApplicationPasswordsGenerationFailed(note: Notification) {
        guard let error = note.object as? Error else {
            return
        }
        let path = note.userInfo?[ApplicationPasswordGenerationUserInfoKey.path] as? String
        // This observer is delivered on the main queue.
        let applicationStateProvider = applicationStateProvider
        let isAppInForeground = MainActor.assumeIsolated {
            applicationStateProvider() != .background
        }
        analytics.track(event: .ApplicationPassword.applicationPasswordGenerationFailed(scenario: scenario(of: note),
                                                                                        error: error,
                                                                                        path: path,
                                                                                        isAppInForeground: isAppInForeground))
    }

    func scenario(of note: Notification) -> WooAnalyticsEvent.ApplicationPassword.Scenario {
        (note.userInfo?[ApplicationPasswordGenerationUserInfoKey.isRegeneration] as? Bool) == true ? .regeneration : .generation
    }

    /// Tracks an event when JSON parsing fails
    ///
    func trackJSONParsingFailed(note: Notification) {
        guard let error = note.object as? DecodingError else {
            return
        }
        let path = note.userInfo?[Remote.JSONParsingErrorUserInfoKey.path] as? String
        let entityName = note.userInfo?[Remote.JSONParsingErrorUserInfoKey.entityName] as? String
        analytics.track(event: .RemoteRequest.jsonParsingError(error, path: path, entityName: entityName))
    }
}

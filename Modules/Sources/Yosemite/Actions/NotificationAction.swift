import Foundation
import Networking



// MARK: - NotificationAction: Defines all of the Actions supported by the NotificationStore.
//
public enum NotificationAction: Action {

    /// Registers a device for Push Notifications Delivery.
    ///
    case registerDevice(device: APNSDevice,
                        applicationId: String,
                        applicationVersion: String,
                        onCompletion: (DotcomDevice?, Error?) -> Void)

    /// Unregisters a device for Push Notifications Delivery.
    ///
    case unregisterDevice(deviceId: String, onCompletion: (Error?) -> Void)

    /// Synchronizes the full Notifications collection.
    ///
    case synchronizeNotifications(onCompletion: (Error?) -> Void)

    /// Synchronizes a specified Notification.
    ///
    case synchronizeNotification(noteID: Int64, onCompletion: (Note?, Error?) -> Void)

    /// Updates the WordPress.com Last Seen field.
    ///
    case updateLastSeen(timestamp: String, onCompletion: (Error?) -> Void)

    /// Updates a given Notification's read flag.
    ///
    case updateReadStatus(noteID: Int64, read: Bool, onCompletion: (Error?) -> Void)

    /// Updates, in batch, the Notification's read flag.
    ///
    case updateMultipleReadStatus(noteIDs: [Int64], read: Bool, onCompletion: (Error?) -> Void)
    case updateLocalDeletedStatus(noteID: Int64, deleteInProgress: Bool, onCompletion: (Error?) -> Void)

    /// Registers a device for Push Notifications Delivery with the self-driven push notification system.
    ///
    /// - Parameters:
    ///     - siteID: ID of the site
    ///     - device: APNS Device to be registered
    ///     - applicationID: App ID
    ///     - deviceLocale: Device locale in `xx_XX` format (e.g. `en_US`)
    ///     - appVersion: App version string
    ///     - availableAsRESTRequest: Whether the underlying request can be sent as a direct REST
    ///       call when an application password is available. Safe only when `siteID` is the currently
    ///       selected site. For cross-site registration pass `false` to force the Jetpack tunnel.
    ///
    case registerDeviceForSelfDrivenPushNotifications(siteID: Int64,
                                                      device: APNSDevice,
                                                      applicationID: String,
                                                      deviceLocale: String,
                                                      appVersion: String,
                                                      availableAsRESTRequest: Bool,
                                                      onCompletion: (Result<Int64, Error>) -> Void)

    /// Removes a given tokenID from the the self-driven push notification system.
    ///
    /// - Parameters:
    ///     - siteID: ID of the site
    ///     - tokenID: The push token ID to delete
    ///     - availableAsRESTRequest: Whether the underlying request can be sent as a direct REST
    ///       call when an application password is available. Safe only when `siteID` is the currently
    ///       selected site. For cross-site unregistration pass `false` to force the Jetpack tunnel.
    ///
    case unregisterFromSelfDrivenPushNotifications(siteID: Int64,
                                                   tokenID: Int64,
                                                   availableAsRESTRequest: Bool,
                                                   onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the current user's push notification preferences for a site.
    ///
    /// - Parameter siteID: The site to query.
    ///
    case loadPushNotificationPreferences(siteID: Int64,
                                         onCompletion: (Result<PushNotificationPreferences, Error>) -> Void)

    /// Sends a partial update to the current user's push notification preferences and returns the
    /// full, server-merged result. Only the fields set on `changes` are sent over the wire; the
    /// server deep-merges them with the stored preferences.
    ///
    /// - Parameters:
    ///   - siteID: The site to update.
    ///   - changes: A `PushNotificationPreferences` value with only the fields the caller wants to
    ///     change set; everything else should be `nil`.
    ///
    case updatePushNotificationPreferences(siteID: Int64,
                                           changes: PushNotificationPreferences,
                                           onCompletion: (Result<PushNotificationPreferences, Error>) -> Void)
}

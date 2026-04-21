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
    case registerDeviceForSelfDrivenPushNotifications(siteID: Int64,
                                                      device: APNSDevice,
                                                      applicationID: String,
                                                      deviceLocale: String,
                                                      appVersion: String,
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
}

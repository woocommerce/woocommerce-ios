import Foundation

/// Protocol for `PushNotificationPreferencesRemote` — mockable for tests.
///
public protocol PushNotificationPreferencesRemoteProtocol {
    /// Loads the current user's push notification preferences for a site.
    ///
    /// - Parameter siteID: The Jetpack-connected site to query.
    /// - Returns: The full, server-merged preferences object.
    func loadPreferences(siteID: Int64) async throws -> PushNotificationPreferences

    /// Sends a partial update to the current user's push notification preferences.
    ///
    /// Only the sub-fields set on `changes` are sent over the wire; the server
    /// deep-merges them with the stored preferences and returns the full result.
    ///
    /// - Parameters:
    ///   - siteID: The Jetpack-connected site to update.
    ///   - changes: A `PushNotificationPreferences` instance with only the fields
    ///     the caller wants to change set; everything else should be `nil`.
    /// - Returns: The full, server-merged preferences object after the update.
    func updatePreferences(siteID: Int64,
                           changes: PushNotificationPreferences) async throws -> PushNotificationPreferences
}

/// Remote for the WooCommerce push notification preferences endpoint
/// (`wc-push-notifications/preferences`). Requests prefer the REST fallback when an
/// application password is available and fall back to the Jetpack tunnel otherwise.
///
public final class PushNotificationPreferencesRemote: Remote, PushNotificationPreferencesRemoteProtocol {

    public func loadPreferences(siteID: Int64) async throws -> PushNotificationPreferences {
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .get,
                                     siteID: siteID,
                                     path: Paths.preferences,
                                     availableAsRESTRequest: true)
        return try await enqueue(request)
    }

    public func updatePreferences(siteID: Int64,
                                  changes: PushNotificationPreferences) async throws -> PushNotificationPreferences {
        let parameters = try changes.toDictionary()
        let request = JetpackRequest(wooApiVersion: .none,
                                     method: .post,
                                     siteID: siteID,
                                     path: Paths.preferences,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return try await enqueue(request)
    }
}

// MARK: - Constants
//
private extension PushNotificationPreferencesRemote {
    enum Paths {
        static let preferences = "wc-push-notifications/preferences"
    }
}

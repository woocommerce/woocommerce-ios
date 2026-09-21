import Foundation
import protocol Yosemite.StoresManager

/// Resolves the site ID a push notification refers to within the current session.
///
/// This lives in the app target instead of `PushNotification.swift` on purpose: that file is also
/// compiled into the Watch App and the Notification Extension, and neither of them links Yosemite
/// or has access to `ServiceLocator`.
///
extension PushNotification {
    /// Returns the site ID that should be used for data operations in the current session.
    ///
    /// Push notifications contain the site's real WP.com blog ID. Site-credential sessions,
    /// however, identify their only selected site with `WooConstants.placeholderStoreID`.
    /// Using the push ID in those sessions would store the fetched data in a different partition
    /// from the one observed by the UI.
    ///
    /// The selected store is always read from the session, so callers cannot accidentally resolve
    /// against a site ID that isn't the one the session is currently pointing at.
    ///
    func resolvedSiteID(stores: StoresManager = ServiceLocator.stores) -> Int64 {
        stores.sessionManager.defaultStoreID == WooConstants.placeholderStoreID ? WooConstants.placeholderStoreID : siteID
    }
}

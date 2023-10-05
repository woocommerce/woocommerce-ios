import Foundation
import Networking
import Storage

// MARK: - NotificationCountAction: Defines all of the Actions supported by the NotificationCountStore.
//
public enum NotificationCountAction: Action {
    /// Increments the notification count by a given amount and type for a site of the given ID.
    ///
    case increment(siteID: Int64, type: Note.Kind, incrementCount: Int, onCompletion: () -> Void)

    /// Loads the notification count of a given type for a site of the given ID.
    /// If type is nil, the count of all notification types is returned.
    ///
    case load(siteID: Int64, type: SiteNotificationCountType, onCompletion: (_ count: Int) -> Void)

    /// Resets the notification count of a given type for a site of the given ID.
    ///
    case reset(siteID: Int64, type: Note.Kind, onCompletion: () -> Void)

    /// Resets the notification count for all sites.
    ///
    case resetForAllSites(onCompletion: () -> Void)
}

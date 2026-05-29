import Foundation

/// Notification names posted by the app target to the PointOfSale module for cross-boundary
/// lifecycle events.
///
public extension Notification.Name {
    /// Posted when the user logs out or switches to a different site. The PointOfSale module
    /// listens for this notification to clear the staff PIN cache so stale credentials do not
    /// survive across sessions.
    static let posShouldClearStaffCache = Notification.Name("POSShouldClearStaffCache")
}

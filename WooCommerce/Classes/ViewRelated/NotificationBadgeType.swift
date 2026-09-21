import Foundation

/// The type of notification badge to display on a tab.
///
enum NotificationBadgeType {
    case primary
    case secondary
}

/// Whether the notification badge should be shown or hidden.
///
enum NotificationBadgeActionType {
    case show(type: NotificationBadgeType)
    case hide
}

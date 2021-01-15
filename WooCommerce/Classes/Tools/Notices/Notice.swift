import Foundation
import UIKit


/// Notice represents a small notification that that can be displayed within the app, much like Android toasts or snackbars.
/// Once you've created a Notice, you can dispatch a `NoticeAction` to display it.
///
struct Notice {

    /// The title of the notice
    ///
    let title: String

    /// An optional subtitle for the notice
    ///
    let message: String?

    /// An optional taptic feedback type. If provided, taptic feedback will be triggered when the notice is displayed.
    ///
    let feedbackType: UINotificationFeedbackGenerator.FeedbackType?

    /// If provided, the notice will be presented as a system notification when the app isn't in the foreground.
    ///
    let notificationInfo: NoticeNotificationInfo?

    /// A title for an optional action button that can be displayed as part of a notice
    ///
    let actionTitle: String?

    /// An optional handler closure that will be called when the action button is tapped, if you've provided an action title
    ///
    let actionHandler: (() -> Void)?


    /// Designated Initializer
    ///
    init(title: String,
         message: String? = nil,
         feedbackType: UINotificationFeedbackGenerator.FeedbackType? = nil,
         notificationInfo: NoticeNotificationInfo? = nil,
         actionTitle: String? = nil,
         actionHandler: ((() -> Void))? = nil) {
        self.title = title
        self.message = message
        self.feedbackType = feedbackType
        self.notificationInfo = notificationInfo
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
    }
}

extension Notice: Equatable {
    static func == (lhs: Notice, rhs: Notice) -> Bool {
        return lhs.title == rhs.title &&
            lhs.message == rhs.message &&
            lhs.feedbackType == rhs.feedbackType &&
            lhs.notificationInfo?.identifier == rhs.notificationInfo?.identifier &&
            lhs.actionTitle == rhs.actionTitle
    }
}

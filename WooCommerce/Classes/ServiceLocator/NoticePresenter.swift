import Foundation
import UIKit

/// Abstracts the In-App Notifications Presenter
protocol NoticePresenter {

    /// Enqueues the specified Notice for display.
    ///
    /// - Parameter notice: the info to be displayed in the notice.
    /// - Returns: a boolean that indicates whether the notice can be displayed
    ///            (e.g. a notice of the same content isn't already displayed or enqueued).
    @discardableResult
    func enqueue(notice: Notice) -> Bool

    /// UIViewController to be used as Notice(s) Presenter
    ///
    var presentingViewController: UIViewController? { get set }
}

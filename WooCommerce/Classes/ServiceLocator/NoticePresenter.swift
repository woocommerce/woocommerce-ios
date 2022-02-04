import Foundation
import UIKit

/// Abstracts the In-App Notifications Presenter
protocol NoticePresenter {

    /// Enqueues the specified Notice for display.
    ///
    func enqueue(notice: Notice)

    /// It dismisses the provided `Notice` if it is currenly presented in the foreground, or removes it from the queue
    ///
    func cancel(notice: Notice)

    /// UIViewController to be used as Notice(s) Presenter
    ///
    var presentingViewController: UIViewController? { get set }
}

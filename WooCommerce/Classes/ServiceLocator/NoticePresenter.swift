import Foundation
import UIKit

/// Abstracts the In-App Notifications Presenter
protocol NoticePresenter {

    /// Enqueues the specified Notice for display.
    ///
    func enqueue(notice: Notice)

    /// UIViewController to be used as Notice(s) Presenter
    ///
    var presentingViewController: UIViewController? { get set }
}

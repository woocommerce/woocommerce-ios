import Foundation
import WordPressUI

/// Abstracts the In-App Notifications Presenter
protocol Notices {
    
    /// Enqueues the specified Notice for display.
    ///
    func enqueue(notice: Notice)

    /// UIViewController to be used as Notice(s) Presenter
    ///
    var presentingViewController: UIViewController? { get set }
}

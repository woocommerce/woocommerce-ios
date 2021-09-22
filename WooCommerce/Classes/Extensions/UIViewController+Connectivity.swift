import UIKit
import Combine

extension UIViewController {
    /// Defines if the view controller should show a "no connection" banner when offline.
    /// This requires the view controller to be contained inside a `WooNavigationController`.
    /// Defaults to `false`.
    ///
    @objc var shouldShowOfflineBanner: Bool {
        false
    }
}

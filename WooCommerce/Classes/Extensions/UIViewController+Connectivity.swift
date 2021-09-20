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

    /// Observes changes in status of connectivity and returns a subscription.
    /// Keep a strong reference to this subscription to show the offline banner in the navigation controller's built-in toolbar.
    /// This requires the view controller to be contained inside a `WooNavigationController`.
    ///
    func observeConnectivity() -> AnyCancellable {
        ServiceLocator.connectivityObserver.statusPublisher
            .sink { [weak self] status in
                guard let self = self else { return }
                guard let navigationController = self.navigationController as? WooNavigationController,
                      self.isViewOnScreen() else { return }
                navigationController.isToolbarHidden = status != .notReachable
            }
    }
}

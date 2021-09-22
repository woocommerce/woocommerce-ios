import Combine
import UIKit

/// Subclass to set Woo styling. Removes back button text on managed view controllers.
///
class WooNavigationController: UINavigationController {

    weak override var delegate: UINavigationControllerDelegate? {
        get {
            return navigationDelegate.forwardDelegate
        }
        set {
            navigationDelegate.forwardDelegate = newValue
        }
    }

    /// Private object that listens, acts upon, and forwards events from `UINavigationControllerDelegate`
    ///
    private let navigationDelegate = WooNavigationControllerDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = navigationDelegate
    }

    /// Sets the status bar of the pushed view to white.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }
}

/// Class that listens and forwards events from `UINavigationControllerDelegate`
/// Needed to configure the managed `ViewController` back button while providing a `delegate` to children classes.
///
/// Please be cautious when forwarding events of `navigationController(_:animationControllerFor:from:to:)`.
/// Make sure to implement the method in ALL subclasses of `WooNavigationController`,
/// otherwise it will break the interactive pop gesture.
///
private class WooNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {

    private let connectivityObserver: ConnectivityObserver
    private var currentController: UIViewController?
    private var subscriptions: Set<AnyCancellable> = []

    init(connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.connectivityObserver = connectivityObserver
        super.init()
        observeConnectivity()
    }

    /// Children delegate, all events will be forwarded to this object
    ///
    weak var forwardDelegate: UINavigationControllerDelegate?

    /// Configures the back button for the managed `ViewController` and forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        currentController = viewController
        configureOfflineBanner(for: viewController)
        configureBackButton(for: viewController)
        forwardDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        forwardDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        forwardDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .allButUpsideDown
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        forwardDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
    }
}

// MARK: Back button configuration
private extension WooNavigationControllerDelegate {
    /// Removes the back button text for the provided `ViewController`
    ///
    func configureBackButton(for viewController: UIViewController) {
        viewController.removeNavigationBackBarButtonText()
    }
}

// MARK: - Offline banner configuration
private extension WooNavigationControllerDelegate {

    /// Observes changes in status of connectivity and returns a subscription.
    /// Keep a strong reference to this subscription to show the offline banner in the navigation controller's built-in toolbar.
    ///
    func observeConnectivity() {
        connectivityObserver.statusPublisher
            .sink { [weak self] status in
                guard let self = self, let currentController = self.currentController else { return }
                self.configureOfflineBanner(for: currentController, status: status)
            }
            .store(in: &subscriptions)
    }

    /// Shows or hides offline banner based on the input connectivity status and
    /// whether the view controller supports showing the banner.
    ///
    func configureOfflineBanner(for viewController: UIViewController, status: ConnectivityStatus? = nil) {
        if viewController.shouldShowOfflineBanner {
            setOfflineBannerWhenNoConnection(for: viewController, status: status ?? connectivityObserver.currentStatus)
        } else {
            removeOfflineBanner(for: viewController)
        }
    }

    /// Displays offline banner in the default tool bar of the view controller's navigation controller.
    ///
    func setOfflineBannerWhenNoConnection(for viewController: UIViewController, status: ConnectivityStatus) {

        guard let navigationController = viewController.navigationController else {
            return
        }

        // We can only show it when we are sure we can't reach the internet
        guard status == .notReachable else {
            return removeOfflineBanner(for: viewController)
        }

        let offlineBannerView = OfflineBannerView(frame: .zero)
        offlineBannerView.sizeToFit()
        let offlineItem = UIBarButtonItem(customView: offlineBannerView)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        viewController.toolbarItems = [spaceItem, offlineItem, spaceItem]
        navigationController.toolbar.barTintColor = .gray

        navigationController.setToolbarHidden(false, animated: false)
    }

    /// Hides the default tool bar in the view controller's navigation controller.
    ///
    func removeOfflineBanner(for viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else {
            return
        }
        navigationController.setToolbarHidden(true, animated: false)
    }
}

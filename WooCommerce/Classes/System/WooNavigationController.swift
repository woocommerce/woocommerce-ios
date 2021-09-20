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

    init(connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.connectivityObserver = connectivityObserver
    }

    /// Children delegate, all events will be forwarded to this object
    ///
    weak var forwardDelegate: UINavigationControllerDelegate?

    /// Configures the back button for the managed `ViewController` and forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let wooNavigationController = navigationController as? WooNavigationController,
           viewController.shouldShowOfflineBanner {
            configureOfflineBanner(for: viewController, in: wooNavigationController)
        } else {
            navigationController.isToolbarHidden = true
        }
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

    /// Set up toolbar for the view controller to display the offline message,
    /// and listen to connectivity status changes to change the toolbar's visibility.
    ///
    func configureOfflineBanner(for viewController: UIViewController, in navigationController: WooNavigationController) {
        let offlineBannerView = OfflineBannerView(frame: .zero)
        offlineBannerView.sizeToFit()
        let offlineItem = UIBarButtonItem(customView: offlineBannerView)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        viewController.toolbarItems = [spaceItem, offlineItem, spaceItem]
        navigationController.toolbar.barTintColor = .gray

        let connected = connectivityObserver.isConnectivityAvailable
        navigationController.setToolbarHidden(connected, animated: false)
    }
}

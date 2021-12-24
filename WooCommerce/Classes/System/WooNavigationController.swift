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

// MARK: Offline banner configuration
private extension WooNavigationControllerDelegate {

    /// Observes changes in status of connectivity and updates the offline banner in current view controller accordingly.
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

    /// Adds offline banner at the bottom of the view controller.
    ///
    func setOfflineBannerWhenNoConnection(for viewController: UIViewController, status: ConnectivityStatus) {
        // We can only show it when we are sure we can't reach the internet
        guard status == .notReachable else {
            return removeOfflineBanner(for: viewController)
        }

        // Only add banner view if it's not already added.
        guard let navigationController = viewController.navigationController,
              let view = viewController.view,
              view.subviews.first(where: { $0 is OfflineBannerView }) == nil else {
            return
        }

        let offlineBannerView = OfflineBannerView(frame: .zero)
        offlineBannerView.backgroundColor = .gray
        offlineBannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(offlineBannerView)

        let extraBottomSpace = viewController.hidesBottomBarWhenPushed ? navigationController.view.safeAreaInsets.bottom : 0
        NSLayoutConstraint.activate([
            offlineBannerView.heightAnchor.constraint(equalToConstant: OfflineBannerView.height),
            offlineBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -extraBottomSpace)
        ])
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: OfflineBannerView.height, right: 0)
        UIAccessibility.post(notification: .announcement, argument: Localization.offlineAnnouncement)
    }

    /// Removes the offline banner from the view controller if it exists.
    ///
    func removeOfflineBanner(for viewController: UIViewController) {
        guard let offlineBanner = viewController.view.subviews.first(where: { $0 is OfflineBannerView }) else {
            return
        }
        offlineBanner.removeFromSuperview()
        viewController.additionalSafeAreaInsets = .zero
        UIAccessibility.post(notification: .announcement, argument: Localization.onlineAnnouncement)
    }
}

private extension WooNavigationControllerDelegate {
    enum Localization {
        static let offlineAnnouncement = NSLocalizedString("Offline - using cached data",
                                                           comment: "Accessibility announcement message when device goes offline")
        static let onlineAnnouncement = NSLocalizedString("Back online",
                                                          comment: "Accessibility announcement message when device goes back online")
    }
}

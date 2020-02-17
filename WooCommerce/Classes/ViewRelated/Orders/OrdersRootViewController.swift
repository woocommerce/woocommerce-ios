import UIKit
import Yosemite

final class OrdersRootViewController: UIViewController {

    // MARK: Child view controller

    private lazy var ordersViewController = OrdersMasterViewController()

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // MARK: View Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)

        configureTitle()
        configureTabBarItem()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.image = .statsAltImage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureNavigationButtons()
        configureView()
        configureContainerView()
        configureChildViewController()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ordersViewController.view.frame = containerView.bounds
    }

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        ordersViewController.presentDetails(for: note)
    }
}

// MARK: - Configuration
//
private extension OrdersRootViewController {

    func configureView() {
        view.backgroundColor = .listBackground
    }

    private func configureTitle() {
        title = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
    }

    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = title
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    /// For `viewDidLoad` only, set up `navigationItem` buttons.
    ///
    func configureNavigationButtons() {
        navigationItem.leftBarButtonItem = ordersViewController.createSearchBarButtonItem()

        removeNavigationBackBarButtonText()
    }

    func configureContainerView() {
        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerView)
    }

    func configureChildViewController() {
        let contentView = ordersViewController.view!
        addChild(ordersViewController)
        containerView.addSubview(contentView)
        ordersViewController.didMove(toParent: self)
    }
}

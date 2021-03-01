import UIKit
import Yosemite

/// The root tab controller for Orders.
///
/// This is really just a container for `OrdersTabbedViewController` with subtle fixes for the
/// XLPagerTabStrip bug in landscape. See PR#1851 (https://git.io/Jvzg8) for more information
/// about the bug.
///
/// If we eventually get XLPagerTabStrip replaced, we can merge this class with
/// `OrdersTabbedViewController`.
///
/// If you need to add additional logic, probably consider adding it to `OrdersTabbedViewController`
/// instead if possible.
///
final class OrdersRootViewController: UIViewController {

    // MARK: Child view controller

    private lazy var ordersViewController = OrdersTabbedViewController(siteID: siteID)

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    private let siteID: Int64

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)

        configureTitle()
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        // The magical fix for XLPagerTabStrip landscape issue. h/t @jaclync https://git.io/JvzgK
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
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            hiddenScrollView.configureForLargeTitleWorkaround()
            // Adds the "hidden" scroll view to the root of the UIViewController for large title workaround.
            view.addSubview(hiddenScrollView)
            hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
        }

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

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            ordersViewController.scrollDelegate = self
        }
    }
}

extension OrdersRootViewController: OrdersTabbedViewControllerScrollDelegate {
    func orderListScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
    }
}

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
        configureChildViewController()
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

    func configureChildViewController() {
        let contentView = ordersViewController.view!
        addChild(ordersViewController)
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(contentView)
        ordersViewController.didMove(toParent: self)
    }
}

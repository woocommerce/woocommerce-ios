import UIKit

/// Controller to wrap the orders split view
///
final class OrdersSplitViewWrapperController: UIViewController {
    private let siteID: Int64

    private let ordersSplitViewController = WooSplitViewController()

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
        configureSplitView()
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureChildViewController()
    }
}

private extension OrdersSplitViewWrapperController {
    func configureSplitView() {
        let ordersViewController = OrdersRootViewController(siteID: siteID)
        let ordersNavigationController = WooTabNavigationController()
        ordersNavigationController.viewControllers = [ordersViewController]

        // workaround to remove extra space at the bottom when embedded in spit view
        let ghostTableViewController = GhostTableViewController()
        ghostTableViewController.extendedLayoutIncludesOpaqueBars = true
        let ghostTableViewNavigationController = WooNavigationController(rootViewController: ghostTableViewController)
        ghostTableViewNavigationController.extendedLayoutIncludesOpaqueBars = true

        ordersSplitViewController.viewControllers = [ordersNavigationController, ghostTableViewNavigationController]
    }

    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    func configureChildViewController() {
        let contentView = ordersSplitViewController.view!
        addChild(ordersSplitViewController)
        view.addSubview(contentView)
        ordersSplitViewController.didMove(toParent: self)
    }
}

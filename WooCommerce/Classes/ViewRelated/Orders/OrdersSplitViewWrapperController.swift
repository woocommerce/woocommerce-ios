import UIKit
import Yosemite

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

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order), let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        let loaderViewController = OrderLoaderViewController(note: note, orderID: Int64(orderID), siteID: Int64(siteID))
        let loaderNavigationController = WooNavigationController(rootViewController: loaderViewController)

        // workaround to get rid of the extra space at the bottom when embedded in split view
        loaderViewController.extendedLayoutIncludesOpaqueBars = true
        loaderNavigationController.extendedLayoutIncludesOpaqueBars = true

        ordersSplitViewController.showDetailViewController(loaderNavigationController, sender: nil)
    }
}

private extension OrdersSplitViewWrapperController {
    func configureSplitView() {
        let ordersViewController = OrdersRootViewController(siteID: siteID)
        ordersViewController.extendedLayoutIncludesOpaqueBars = true
        let ordersNavigationController = WooTabNavigationController()
        ordersNavigationController.viewControllers = [ordersViewController]

        // workaround to remove extra space at the bottom when embedded in spit view
        let ghostTableViewController = GhostTableViewController()
        ghostTableViewController.extendedLayoutIncludesOpaqueBars = true
        let ghostTableViewNavigationController = WooNavigationController(rootViewController: ghostTableViewController)

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

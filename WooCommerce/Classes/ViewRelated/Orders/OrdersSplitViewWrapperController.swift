import UIKit
import Yosemite

/// Controller to wrap the orders split view
///
final class OrdersSplitViewWrapperController: UIViewController {
    private let siteID: Int64

    private lazy var ordersSplitViewController = WooSplitViewController(columnForCollapsingHandler: handleCollapsingSplitView)

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

    override var shouldShowOfflineBanner: Bool {
        return true
    }

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order),
              let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        presentDetails(for: Int64(orderID), siteID: Int64(siteID), note: note)
    }

    func presentDetails(for orderID: Int64, siteID: Int64, note: Note? = nil) {
        let loaderViewController = OrderLoaderViewController(orderID: orderID, siteID: Int64(siteID), note: note)
        let loaderNavigationController = WooNavigationController(rootViewController: loaderViewController)

        ordersSplitViewController.showDetailViewController(loaderNavigationController, sender: nil)
    }
}

private extension OrdersSplitViewWrapperController {
    func configureSplitView() {
        let ordersViewController = OrdersRootViewController(siteID: siteID)
        let ordersNavigationController = WooTabNavigationController()
        ordersNavigationController.viewControllers = [ordersViewController]

        let emptyStateViewController = EmptyStateViewController(style: .basic)
        let config = EmptyStateViewController.Config.simple(
            message: .init(string: Localization.emptyOrderDetails),
            image: .emptySearchResultsImage
        )
        emptyStateViewController.configure(config)

        ordersSplitViewController.viewControllers = [ordersNavigationController, emptyStateViewController]
    }

    func handleCollapsingSplitView(splitViewController: UISplitViewController) -> UISplitViewController.Column {
        if let navigationController = splitViewController.viewController(for: .secondary) as? UINavigationController,
           navigationController.viewControllers.contains(where: { $0 is OrderDetailsViewController }) {
            return .secondary
        }
        return .primary
    }

    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = Localization.ordersTabTitle
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    func configureChildViewController() {
        let contentView = ordersSplitViewController.view!
        addChild(ordersSplitViewController)
        view.addSubview(contentView)
        ordersSplitViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}

extension OrdersSplitViewWrapperController {
    private enum Localization {
        static let ordersTabTitle = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
        static let emptyOrderDetails = NSLocalizedString("No order selected",
                                                         comment: "Message on the detail view of the Orders tab before any order is selected")
    }
}

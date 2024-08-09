import UIKit
import Yosemite

/// Controller to wrap the orders split view
///
final class OrdersSplitViewWrapperController: UIViewController {
    private let siteID: Int64

    private lazy var ordersSplitViewController = WooSplitViewController(columnForCollapsingHandler: handleCollapsingSplitView)
    private lazy var ordersViewController = OrdersRootViewController(siteID: siteID, switchDetailsHandler: handleSwitchingDetails)

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
        configureChildViewController()
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
        // If the order cannot be selected from the order list like when it hasn't been fetched remotely,
        // `OrderLoaderViewController` is shown instead.
        guard ordersViewController.selectOrderFromListIfPossible(for: orderID) else {
            // In #12071, it seems that some users are seeing the loader pushed twice, which causes a crash.
            // This shouldn't really be possible, but just in case, this check may improve these crashes.
            guard !orderLoaderAlreadyShownInSecondaryView(for: orderID) else {
                return
            }
            let loaderViewController = OrderLoaderViewController(orderID: orderID, siteID: Int64(siteID), note: note)
            let loaderNavigationController = WooNavigationController(rootViewController: loaderViewController)
            return showSecondaryView(loaderNavigationController)
        }
    }

    private func orderLoaderAlreadyShownInSecondaryView(for orderID: Int64) -> Bool {
        guard let navigationController = ordersSplitViewController.viewController(for: .secondary) as? WooNavigationController,
              let loaderController = navigationController.topViewController as? OrderLoaderViewController else {
            return false
        }
        return loaderController.orderID == orderID
    }

    func presentOrderCreationFlow() {
        ordersViewController.presentOrderCreationFlow()
    }

    func presentOrderCreationFlow(for customerID: Int64, billing: Address?, shipping: Address?) {
        ordersViewController.presentOrderCreationFlowWithCustomer(id: customerID, billing: billing, shipping: shipping)
    }
}

private extension OrdersSplitViewWrapperController {
    func showEmptyView() {
        let emptyStateViewController = EmptyStateViewController(style: .basic)
        let config = EmptyStateViewController.Config.simpleImageWithDescription(image: .shoppingBagsImage,
                                                                               details: Localization.emptyOrderDetails)
        emptyStateViewController.configure(config)
        let navigationController = WooNavigationController(rootViewController: emptyStateViewController)
        showSecondaryView(navigationController)
    }

    func isShowingEmptyView() -> Bool {
        (ordersSplitViewController.viewController(for: .secondary) as? UINavigationController)?
            .viewControllers.contains(where: { $0 is EmptyStateViewController }) == true
    }

    func showSecondaryView(_ viewController: UIViewController) {
        // added to remove double details presented bug #11752 https://github.com/woocommerce/woocommerce-ios/pull/11753#discussion_r1463020153
        // - white debugging noticed that ordersViewController.navigationController had multiple orders in the view controllers list
        ordersViewController.navigationController?.popToRootViewController(animated: false)

        ordersSplitViewController.setViewController(viewController, for: .secondary)
        ordersSplitViewController.show(.secondary)
    }

    /// This is to update the order detail in split view
    ///
    func handleSwitchingDetails(viewModels: [OrderDetailsViewModel],
                                currentIndex: Int,
                                isSelectedManually: Bool,
                                onCompletion: ((_ hasBeenSelected: Bool) -> Void)? = nil) {
        // If the order details is auto-selected (from `viewDidLayoutSubviews`) and the empty view isn't shown,
        // it does not override the secondary view content.
        guard isSelectedManually || isShowingEmptyView() else {
            onCompletion?(false)
            return
        }

        guard viewModels.isNotEmpty else {
            showEmptyView()
            onCompletion?(false)
            return
        }

        let orderDetailsViewController = OrderDetailsViewController(
            viewModels: viewModels,
            currentIndex: currentIndex,
            switchDetailsHandler: { [weak self] viewModels, currentIndex, isSelectedManually, completion in
                self?.handleSwitchingDetails(viewModels: viewModels,
                                             currentIndex: currentIndex,
                                             isSelectedManually: isSelectedManually,
                                             onCompletion: completion)
            })

        // When navigating between orders using up and down arrows (referred to "quick order navigation" in code), each new Order Details screen
        // shown should replace the topViewController, to avoid having to tap back through several Order Details
        // screens in the navigation stack. The back button should always go to the Order List.
        // The up and down arrows are enabled when there is more than one item in `viewModels`.
        guard isQuickOrderNavigationSupported(viewModels: viewModels),
              let viewModel = viewModels[safe: currentIndex],
              let secondaryNavigationController = ordersSplitViewController.viewController(for: .secondary) as? UINavigationController,
              secondaryNavigationController.topViewController is OrderDetailsViewController else {
            // When showing an order without quick navigation, it simply sets the order details to the secondary view.
            let orderDetailsNavigationController = WooNavigationController(rootViewController: orderDetailsViewController)
            showSecondaryView(orderDetailsNavigationController)
            onCompletion?(true)
            return
        }

        secondaryNavigationController.replaceTopViewController(with: orderDetailsViewController, animated: false)
        ordersViewController.onOrderSelected(id: viewModel.order.orderID)
        ordersSplitViewController.show(.secondary)
        onCompletion?(true)
    }

    func isQuickOrderNavigationSupported(viewModels: [OrderDetailsViewModel]) -> Bool {
        viewModels.count > 1
    }
}

private extension OrdersSplitViewWrapperController {
    func configureSplitView() {
        let ordersNavigationController = WooTabNavigationController()
        ordersNavigationController.viewControllers = [ordersViewController]
        ordersSplitViewController.setViewController(ordersNavigationController, for: .primary)

        showEmptyView()
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

extension OrdersSplitViewWrapperController: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        guard let ordersDestination = destination as? OrdersDestination else {
            return
        }
        switch ordersDestination {
        case .createOrder:
            presentOrderCreationFlow()
        case .orderList:
            return
        }
    }
}

extension OrdersSplitViewWrapperController {
    private enum Localization {
        static let ordersTabTitle = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
        static let emptyOrderDetails = NSLocalizedString("No order selected",
                                                         comment: "Message on the detail view of the Orders tab before any order is selected")
    }
}

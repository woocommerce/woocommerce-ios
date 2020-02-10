
import UIKit
import XLPagerTabStrip
import struct Yosemite.OrderStatus
import enum Yosemite.OrderStatusEnum
import struct Yosemite.Note

/// The main Orders view controller that is shown when the Orders tab is accessed.
///
final class OrdersMasterViewController: ButtonBarPagerTabStripViewController {

    private lazy var analytics = ServiceLocator.analytics

    private lazy var viewModel = OrdersMasterViewModel()

    init() {
        super.init(nibName: Self.nibName, bundle: nil)

        title = NSLocalizedString("Orders", comment: "The title of the Orders tab.")

        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        // `configureTabStrip` must be called before `super.viewDidLoad()` or else the selection
        // highlight will be black. ¯\_(ツ)_/¯
        configureTabStrip()
        configureNavigationButtons()

        super.viewDidLoad()

        viewModel.activate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.syncOrderStatuses()
    }

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order), let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        let loaderViewController = OrderLoaderViewController(note: note, orderID: Int64(orderID), siteID: Int64(siteID))
        navigationController?.pushViewController(loaderViewController, animated: true)
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchOrders() {
        guard let storeID = viewModel.siteID else {
            return
        }

        analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(storeID: storeID,
                                                                                                  command: OrderSearchUICommand(),
                                                                                                  cellType: OrderTableViewCell.self)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    // MARK: - ButtonBarPagerTabStripViewController Conformance

    /// Return the ViewControllers for "Processing" and "All Orders".
    ///
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        // TODO This is fake. It's probably better to just pass the `slug` to `OrdersViewController`.
        let processingOrderStatus = OrderStatus(
            name: OrderStatusEnum.processing.rawValue,
            siteID: Int64.max,
            slug: OrderStatusEnum.processing.rawValue,
            total: 0
        )
        let processingOrdersVC = OrdersViewController(
            title: NSLocalizedString("Processing", comment: "Title for the first page in the Orders tab."),
            statusFilter: processingOrderStatus,
            showsRemoveFilterActionOnFilteredEmptyView: true)
        processingOrdersVC.delegate = self

        let allOrdersVC = OrdersViewController(
            title: NSLocalizedString("All Orders", comment: "Title for the second page in the Orders tab."),
            statusFilter: nil,
            showsRemoveFilterActionOnFilteredEmptyView: true)
        allOrdersVC.delegate = self

        return [processingOrdersVC, allOrdersVC]
    }
}

// MARK: - OrdersViewControllerDelegate

extension OrdersMasterViewController: OrdersViewControllerDelegate {
    func ordersViewControllerWillSynchronizeOrders(_ viewController: OrdersViewController) {
        viewModel.syncOrderStatuses()
    }

    func ordersViewControllerRequestsToClearStatusFilter(_ viewController: OrdersViewController) {
    }
}

// MARK: - Initialization and Loading (Not Reusable)

private extension OrdersMasterViewController {
    /// Initialize the tab bar containing the "Processing" and "All Orders" buttons.
    ///
    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .listForeground
        settings.style.buttonBarItemBackgroundColor = .listForeground
        settings.style.selectedBarBackgroundColor = .primary
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStripDimensions.selectedBarHeight
        settings.style.buttonBarItemTitleColor = .text
        settings.style.buttonBarItemLeftRightMargin = TabStripDimensions.buttonLeftRightMargin

        changeCurrentIndexProgressive = {
            (oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool) -> Void in

            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .textSubtle
            newCell?.label.textColor = .primary
        }
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
        navigationItem.leftBarButtonItem = createSearchBarButtonItem()

        removeNavigationBackBarButtonText()
    }

    enum TabStripDimensions {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}

// MARK: - Creators

private extension OrdersMasterViewController {
    /// Create a `UIBarButtonItem` to be used as the search button on the top-left.
    ///
    func createSearchBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .searchImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(displaySearchOrders))
        button.accessibilityTraits = .button
        button.accessibilityLabel = NSLocalizedString("Search orders", comment: "Search Orders")
        button.accessibilityHint = NSLocalizedString(
            "Retrieves a list of orders that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search orders."
        )
        button.accessibilityIdentifier = "order-search-button"

        return button
    }
}


import UIKit
import XLPagerTabStrip
import struct Yosemite.OrderStatus
import enum Yosemite.OrderStatusEnum
import struct Yosemite.Note

/// Relays the scroll events to a delegate for navigation bar large title workaround.
protocol OrdersTabbedViewControllerScrollDelegate: class {
    /// Called when an order list `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    func orderListScrollViewDidScroll(_ scrollView: UIScrollView)
}

/// The main Orders view controller that is shown when the Orders tab is accessed.
///
final class OrdersTabbedViewController: ButtonBarPagerTabStripViewController {
    /// For navigation bar large title workaround.
    weak var scrollDelegate: OrdersTabbedViewControllerScrollDelegate?

    private lazy var analytics = ServiceLocator.analytics

    private lazy var viewModel = OrdersTabbedViewModel(siteID: siteID)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        // `configureTabStrip` must be called before `super.viewDidLoad()` or else the selection
        // highlight will be black. ¯\_(ツ)_/¯
        configureTabStrip()

        super.viewDidLoad()

        viewModel.activate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.syncOrderStatuses()

        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }

        ServiceLocator.pushNotesManager.resetBadgeCount(type: .storeOrder)
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
        analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(storeID: siteID,
                                                                                                  command: OrderSearchUICommand(siteID: siteID),
                                                                                                  cellType: OrderTableViewCell.self,
                                                                                                  cellSeparator: .singleLine)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    // MARK: - ButtonBarPagerTabStripViewController Conformance

    /// Return the ViewControllers for "Processing" and "All Orders".
    ///
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return makeViewControllers()
    }

}

// MARK: - OrdersViewControllerDelegate

extension OrdersTabbedViewController: OrderListViewControllerDelegate {
    func orderListViewControllerWillSynchronizeOrders(_ viewController: UIViewController) {
        viewModel.syncOrderStatuses()
    }

    func orderListScrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.orderListScrollViewDidScroll(scrollView)
    }
}

// MARK: - Initialization and Loading (Not Reusable)

private extension OrdersTabbedViewController {
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

        addBottomBorderToTabStripButtonBarView(buttonBarView)
    }

    /// Helper for `configureTabStrip()`.
    ///
    func addBottomBorderToTabStripButtonBarView(_ buttonBarView: ButtonBarView) {
        guard let superView = buttonBarView.superview else {
            return
        }

        let border = UIView.createBorderView()

        superView.addSubview(border)

        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: buttonBarView.bottomAnchor),
            border.leadingAnchor.constraint(equalTo: buttonBarView.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: buttonBarView.trailingAnchor)
        ])
    }

    enum TabStripDimensions {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}

// MARK: - Creators

extension OrdersTabbedViewController {
    /// Create a `UIBarButtonItem` to be used as the search button on the top-left.
    ///
    func createSearchBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .searchBarButtonItemImage,
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

    /// Creates the view controllers to be shown in tabs.
    func makeViewControllers() -> [UIViewController] {
        // TODO This is fake. It's probably better to just pass the `slug` to `OrdersViewController`.
        let processingOrderStatus = OrderStatus(
            name: OrderStatusEnum.processing.rawValue,
            siteID: siteID,
            slug: OrderStatusEnum.processing.rawValue,
            total: 0
        )

        // We're intentionally not using `processingOrderStatus` as the source of the "Processing"
        // text in here. We want the string to be translated.
        let processingOrdersVC = OrderListViewController(
            siteID: siteID,
            title: Localization.processingTitle,
            viewModel: OrderListViewModel(siteID: siteID, statusFilter: processingOrderStatus),
            emptyStateConfig: .simple(
                message: NSAttributedString(string: Localization.processingEmptyStateMessage),
                image: .waitingForCustomersImage
            )
        )
        processingOrdersVC.delegate = self

        let allOrdersVC = OrderListViewController(
            siteID: siteID,
            title: Localization.allOrdersTitle,
            viewModel: OrderListViewModel(siteID: siteID, statusFilter: nil),
            emptyStateConfig: .withLink(
                message: NSAttributedString(string: Localization.allOrdersEmptyStateMessage),
                image: .emptyOrdersImage,
                details: Localization.allOrdersEmptyStateDetail,
                linkTitle: Localization.learnMore,
                linkURL: WooConstants.URLs.blog.asURL()
            )
        )
        allOrdersVC.delegate = self

        return [processingOrdersVC, allOrdersVC]
    }
}

// MARK: - Localization

private extension OrdersTabbedViewController {
    enum Localization {
        static let processingTitle = NSLocalizedString("Processing", comment: "Title for the first page in the Orders tab.")
        static let processingEmptyStateMessage =
            NSLocalizedString("All orders have been fulfilled",
                              comment: "The message shown in the Orders → Processing tab if the list is empty.")
        static let allOrdersTitle = NSLocalizedString("All Orders", comment: "Title for the second page in the Orders tab.")
        static let allOrdersEmptyStateMessage =
            NSLocalizedString("Waiting for your first order",
                              comment: "The message shown in the Orders → All Orders tab if the list is empty.")
        static let allOrdersEmptyStateDetail =
            NSLocalizedString("We'll notify you when you receive a new order. In the meantime, explore how you can increase your store sales.",
                              comment: "The detailed message shown in the Orders → All Orders tab if the list is empty.")
        static let learnMore = NSLocalizedString("Learn more", comment: "Title of button shown in the Orders → All Orders tab if the list is empty.")
    }
}

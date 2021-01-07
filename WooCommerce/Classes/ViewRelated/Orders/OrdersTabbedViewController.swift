import UIKit
import struct Yosemite.OrderStatus
import enum Yosemite.OrderStatusEnum
import struct Yosemite.Note

/// The main Orders view controller that is shown when the Orders tab is accessed.
///
final class OrdersTabbedViewController: TabbedViewController {

    private lazy var analytics = ServiceLocator.analytics

    private lazy var viewModel = OrdersTabbedViewModel(siteID: siteID)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        let processingOrdersVC: OrderListViewController = {
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
            return processingOrdersVC
        }()
        let allOrdersVC: OrderListViewController = {
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
            return allOrdersVC
        }()
        // TODO: accessibility
        let tabItems: [TabbedItem] = [
            .init(title: Localization.processingTitle,
                  viewController: processingOrdersVC,
                  accessibilityIdentifier: Localization.processingTitle),
            .init(title: Localization.allOrdersTitle,
                  viewController: allOrdersVC,
                  accessibilityIdentifier: Localization.allOrdersTitle),
        ]
        super.init(items: tabItems, tabSizingStyle: .equalWidths)

        processingOrdersVC.delegate = self
        allOrdersVC.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
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
                                                                                                  cellType: OrderTableViewCell.self)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

}

// MARK: - OrdersViewControllerDelegate

extension OrdersTabbedViewController: OrderListViewControllerDelegate {
    func orderListViewControllerWillSynchronizeOrders(_ viewController: UIViewController) {
        viewModel.syncOrderStatuses()
    }
}

// MARK: - Creators

extension OrdersTabbedViewController {
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

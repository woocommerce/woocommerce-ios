
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
        // We're intentionally not using `processingOrderStatus` as the source of the "Processing"
        // text in here. We want the string to be translated.
        let processingOrdersVC = OrdersViewController(
            title: NSLocalizedString("Processing", comment: "Title for the first page in the Orders tab."),
            viewModel: OrdersViewModel(statusFilter: processingOrderStatus),
            emptyStateAttributes: .init(
                message: NSAttributedString(string: NSLocalizedString("All orders have been fulfilled",
                                                                      comment: "The message shown in the Orders → Processing tab if the list is empty.")),
                image: .waitingForCustomersImage,
                details: nil,
                actionButton: nil
            )
        )
        processingOrdersVC.delegate = self

        let allOrdersVC = OrdersViewController(
            title: NSLocalizedString("All Orders", comment: "Title for the second page in the Orders tab."),
            viewModel: OrdersViewModel(statusFilter: nil, includesFutureOrders: false),
            emptyStateAttributes: .init(
                message: NSAttributedString(string: NSLocalizedString("Waiting for your first order",
                                                                      comment: "The message shown in the Orders → All Orders tab if the list is empty.")),
                image: .emptyOrdersImage,
                details: NSLocalizedString("We'll notify you when you receive a new order. In the meantime, explore how you can increase your store sales.",
                                           comment: "The detailed message shown in the Orders → All Orders tab if the list is empty."),
                actionButton: (
                    title: NSLocalizedString("Learn more", comment: "Title of button shown in the Orders → All Orders tab if the list is empty."),
                    url: .wooCommerceBlog
                )
            )
        )
        allOrdersVC.delegate = self

        return [processingOrdersVC, allOrdersVC]
    }
}

// MARK: - OrdersViewControllerDelegate

extension OrdersMasterViewController: OrdersViewControllerDelegate {
    func ordersViewControllerWillSynchronizeOrders(_ viewController: OrdersViewController) {
        viewModel.syncOrderStatuses()
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

extension OrdersMasterViewController {
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

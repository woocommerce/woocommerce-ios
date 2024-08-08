import Combine
import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import SwiftUI
import WooFoundation

private typealias SyncReason = OrderListSyncActionUseCase.SyncReason

protocol OrderListViewControllerDelegate: AnyObject {
    /// Called when `OrderListViewController` (or `OrdersViewController`) is about to fetch Orders from the API.
    ///
    func orderListViewControllerWillSynchronizeOrders(_ viewController: UIViewController)

    /// Called when new the order list has been synced and the sync timestamp changes.
    ///
    func orderListViewControllerSyncTimestampChanged(_ syncTimestamp: Date)

    /// Called when an order list `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    ///
    func orderListScrollViewDidScroll(_ scrollView: UIScrollView)

    /// Called when a user press a clear filters button. Eg. the clear filters button in the empty screen.
    ///
    func clearFilters()
}

/// OrderListViewController: Displays the list of Orders associated to the active Store / Account.
///
final class OrderListViewController: UIViewController, GhostableViewController {
    /// Callback closure when an order is selected either manually (by the user) or automatically in multi-column view.
    /// `allViewModels` is a list of order details view models that are available in a stack when the split view is collapsed
    /// so that the user can navigate between order details easily. `index` is the default index of order details to be shown.
    /// `isSelectedManually` indicates whether the order details is selected manually, as the first order can be auto-selected when the split
    /// view has multiple columns but only if the empty view is shown.
    /// `onCompletion` is called after switching details completes, with a boolean that indicates if the order details has been selected.
    /// When multi-column split view is shown, auto-selection only works if the empty state isn't shown.
    typealias SelectOrderDetails = (_ allViewModels: [OrderDetailsViewModel],
                                    _ index: Int,
                                    _ isSelectedManually: Bool,
                                    _ onCompletion: ((_ hasBeenSelected: Bool) -> Void)?) -> Void

    weak var delegate: OrderListViewControllerDelegate?

    private let viewModel: OrderListViewModel

    /// Main TableView.
    ///
    @IBOutlet weak var tableView: UITableView!

    /// The data source that is bound to `tableView`.
    private var dataSource: UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>?

    /// Returns the first Order in the OrderList datasource
    ///
    var firstAvailableOrder: Order? {
        let firstIndexPath = IndexPath(row: 0, section: 0)
        guard let objectID = dataSource?.itemIdentifier(for: firstIndexPath),
              let orderViewModel = viewModel.detailsViewModel(withID: objectID) else {
            return nil
        }
        return orderViewModel.order
    }

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: OrderTableViewCell.self,
                                                                                                estimatedRowHeight: Settings.estimatedRowHeight,
                                                                                                tableViewStyle: .grouped,
                                                                                                isScrollEnabled: false))

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// The view shown if the list is empty.
    ///
    private lazy var emptyStateViewController = EmptyStateViewController(style: .list)

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Timestamp for last successful sync.
    /// Reads and feeds from `OrderListSyncBackgroundTask.latestSyncDate`
    ///
    private(set) var lastFullSyncTimestamp: Date {
        get {
            OrderListSyncBackgroundTask.latestSyncDate
        }
        set {
            OrderListSyncBackgroundTask.latestSyncDate = newValue
            delegate?.orderListViewControllerSyncTimestampChanged(newValue)
        }
    }

    /// Minimum time interval allowed between full sync.
    ///
    private let minimalIntervalBetweenSync: TimeInterval = {
        return 30 * 60 // 30m
    }()

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            guard oldValue != state else {
                return
            }

            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    private var cancellables = Set<AnyCancellable>()

    private let siteID: Int64

    /// Current top banner that is displayed.
    ///
    private var topBannerView: UIView?

    /// Callback closure when an order is selected
    private let switchDetailsHandler: SelectOrderDetails

    /// Currently selected index path in the table view
    ///
    private var selectedIndexPath: IndexPath?

    /// Currently selected order ID in the table view
    ///
    private var selectedOrderID: Int64?

    /// Tracks if the swipe actions have been glanced to the user.
    ///
    private var swipeActionsGlanced = false

    /// Banner variation that will be shown as In-Person Payments feedback banner. If any.
    ///
    private var inPersonPaymentsSurveyVariation: SurveyViewController.Source?

    /// Store plan banner presentation handler.
    ///
    private var storePlanBannerPresenter: StorePlanBannerPresenter?

    /// Notice presentation handler
    ///
    private var noticePresenter: NoticePresenter = DefaultNoticePresenter()

    // MARK: - View Lifecycle

    /// Designated initializer.
    ///
    init(siteID: Int64,
         title: String,
         viewModel: OrderListViewModel,
         switchDetailsHandler: @escaping ([OrderDetailsViewModel], Int, Bool, ((Bool) -> Void)?) -> Void) {
        self.siteID = siteID
        self.viewModel = viewModel
        self.switchDetailsHandler = switchDetailsHandler

        super.init(nibName: type(of: self).nibName, bundle: nil)

        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }

    deinit {
        cancellables.forEach {
            $0.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createDataSource()

        registerUserActivity()

        registerTableViewHeadersAndCells()
        configureTableView()

        configureViewModel()
        configureSyncingCoordinator()

        configureStorePlanBannerPresenter()
    }

    private func createDataSource() {
        guard dataSource == nil else {
            return
        }

        let dataSource = UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>(
            tableView: tableView,
            cellProvider: makeCellProvider()
        )
        dataSource.defaultRowAnimation = .fade

        self.dataSource = dataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.resynchronize(reason: SyncReason.viewWillAppear.rawValue)

        // Fix any incomplete animation of the refresh control
        // when switching tabs mid-animation
        refreshControl.resetAnimation(in: tableView)

        // Fix any _incomplete_ animation if the orders were deleted and refetched from
        // a different location (or Orders tab).
        //
        // We can remove this once we've replaced XLPagerTabStrip.
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        highlightSelectedRowIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateHeaderHeight()

        // To fix this issue, the selected item checking is now called after `viewDidLayoutSubviews`, where `isCollapsed` value is
        // correctly set.
        // This additionally ensures that an order is selected when changing from horizontally compact to regular.
        // Select the first order if we're showing in an open split view (i.e. on iPad in some size classes)
        guard let splitViewController,
              !splitViewController.isCollapsed else {
            return
        }
        checkSelectedItem()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if selectedIndexPath != nil {
            // Reload table view to update selected state on the list when changing rotation
            tableView.reloadData()
        }
    }

    /// Called when an order is shown and the order should be selected in the order list.
    /// - Parameter orderID: ID of the order to be selected in the order list.
    /// - Parameter shouldScrollIfNeeded: Boolean flag to turn on scrolling if the newly selected row is not visible
    func onOrderSelected(id orderID: Int64, shouldScrollIfNeeded: Bool = false) {
        selectedOrderID = orderID
        selectedIndexPath = indexPath(for: orderID)
        highlightSelectedRowIfNeeded(shouldScrollIfNeeded: shouldScrollIfNeeded)
    }

    /// Returns a function that creates cells for `dataSource`.
    private func makeCellProvider() -> UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>.CellProvider {
        return { [weak self] tableView, indexPath, objectID in
            let cell = tableView.dequeueReusableCell(OrderTableViewCell.self, for: indexPath)
            guard let self = self else {
                return cell
            }

            let cellViewModel = self.viewModel.cellViewModel(withID: objectID)

            cell.configureCell(viewModel: cellViewModel)
            cell.layoutIfNeeded()
            return cell
        }
    }
}


// MARK: - User Interface Initialization
//
private extension OrderListViewController {
    /// Initialize ViewModel operations
    ///
    func configureViewModel() {
        viewModel.onShouldResynchronizeIfViewIsVisible = { [weak self] in
            guard let self else { return }

            // Avoid synchronizing if the view is not visible. The refresh will be handled in
            // `viewWillAppear` instead.
            guard self.viewIfLoaded?.window != nil else { return }

            // Send a delegate event in case the updated happened while the app was in the background.
            self.delegate?.orderListViewControllerSyncTimestampChanged(lastFullSyncTimestamp)

            self.syncingCoordinator.resynchronize(reason: SyncReason.viewWillAppear.rawValue)
        }

        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = { [weak self] in
            self?.syncingCoordinator.resynchronize(reason: SyncReason.newFiltersApplied.rawValue)
        }

        viewModel.activate()

        /// Update the `dataSource` whenever there is a new snapshot.
        viewModel.snapshot.sink { [weak self] snapshot in
            guard let self = self else { return }

            dataSource?.apply(snapshot)

            transitionToResultsUpdatedState()

            /// Check that view is loaded and displayed to prevent UI tests failing while synching orders from other screens.
            if isViewLoaded == true && view.window != nil,
               self.splitViewController?.isCollapsed == false {
                self.checkSelectedItem()
            }
        }.store(in: &cancellables)

        /// Update the top banner when needed
        viewModel.$topBanner
            .sink { [weak self] topBannerType in
                guard let self = self else { return }
                switch topBannerType {
                case .none:
                    self.hideTopBannerView()
                case .error(let error):
                    self.setErrorTopBanner(for: error)
                }
            }
            .store(in: &cancellables)
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = dataSource

        view.backgroundColor = .listBackground
        tableView.accessibilityIdentifier = "orders-table-view"
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
        tableView.estimatedSectionHeaderHeight = Settings.estimatedHeaderHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.allowsFocus = supportsFocus()
    }

    /// Registers all of the available table view cells and headers
    ///
    func registerTableViewHeadersAndCells() {
        tableView.registerNib(for: OrderTableViewCell.self)

        let headerType = TwoColumnSectionHeaderView.self
        tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
    }

    func configureStorePlanBannerPresenter() {
        self.storePlanBannerPresenter =  StorePlanBannerPresenter(viewController: self,
                                                                  containerView: view,
                                                                  siteID: siteID) { [weak self] bannerHeight in
            self?.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bannerHeight, right: 0)
        }
    }
}

// MARK: - Actions
//
extension OrderListViewController {
    @objc func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.ordersListPulledToRefresh)
        delegate?.orderListViewControllerWillSynchronizeOrders(self)
        NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
        viewModel.onPullToRefresh()
        syncingCoordinator.resynchronize(reason: SyncReason.pullToRefresh.rawValue) {
            sender.endRefreshing()
        }
    }

    func showErrorNotice(_ notice: Notice, in viewController: UIViewController) {
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)
    }

    private func markOrderAsCompleted(resultID: FetchResultSnapshotObjectID) {
        guard let orderDetailsViewModel = viewModel.detailsViewModel(withID: resultID) else {
            return DDLogError("⛔️ ViewModel for resultID: \(resultID) not found")
        }
        /// Actions that performs the mark completed request remotely.
        let fulfillmentProcess = orderDetailsViewModel.markCompleted(flow: .list)

        /// Messages configuration
        let noticeConfiguration = OrderFulfillmentNoticePresenter.NoticeConfiguration(
            successTitle: Localization.markCompletedNoticeTitle(orderID: orderDetailsViewModel.order.orderID),
            errorTitle: Localization.markCompletedErrorNoticeTitle(orderID: orderDetailsViewModel.order.orderID))

        /// Fires fulfillment action, observes its result and enqueue the appropriate notices.
        let presenter = OrderFulfillmentNoticePresenter(noticeConfiguration: noticeConfiguration)
        presenter.present(process: fulfillmentProcess)
    }

    /// Slightly reveal swipe actions of the first visible cell that contains at least one swipe action.
    /// This action is performed only once, using `swipeActionsGlanced` as a control variable.
    ///
    private func glanceTrailingActionsIfNeeded() {
        if !swipeActionsGlanced {
            swipeActionsGlanced = true
            tableView.glanceTrailingSwipeActions()
        }
    }
}

// MARK: - Sync'ing Helpers
//
extension OrderListViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    /// Sets `retryTimeout` as `true`.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        sync(pageNumber: pageNumber, pageSize: pageSize, reason: reason, retryTimeout: true, onCompletion: onCompletion)
    }

    /// Synchronizes the Orders for the Default Store (if any).
    /// When retry timeout is `true` it retires the request one time recursively when a timeout happens.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, retryTimeout: Bool, onCompletion: ((Bool) -> Void)? = nil) {
        // Decide if we need to continue with the sync depending on custom conditions between sync reason and latest sync
        if let syncReason = SyncReason(rawValue: reason ?? ""), pageNumber == syncingCoordinator.pageFirstIndex {

            switch syncReason {
            case .viewWillAppear where Date().timeIntervalSince(lastFullSyncTimestamp) < minimalIntervalBetweenSync:
                onCompletion?(true) // less than 30m from last full sync
                return
            case .viewWillAppear:
                refreshControl.showRefreshAnimation(on: self.tableView)
            default:
                break
            }
        }

        transitionToSyncingState()
        viewModel.dataLoadingError = nil

        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            reason: SyncReason(rawValue: reason ?? ""),
            lastFullSyncTimestamp: lastFullSyncTimestamp) { [weak self] totalDuration, error in
                guard let self = self else {
                    return
                }

                if let error {
                    ServiceLocator.analytics.track(event: .ordersListLoadError(error))
                    DDLogError("⛔️ Error synchronizing orders: \(error)")

                    // Recursively retries timeout errors when required.
                    if error.isTimeoutError && retryTimeout {

                        self.sync(pageNumber: pageNumber, pageSize: pageSize, reason: reason, retryTimeout: false, onCompletion: onCompletion)
                        ServiceLocator.analytics.track(event: .ConnectivityTool.automaticTimeoutRetry())

                    } else {
                        self.viewModel.dataLoadingError = error
                    }
                } else {
                    if pageNumber == self.syncingCoordinator.pageFirstIndex {
                        // save timestamp of last successful update
                        self.lastFullSyncTimestamp = Date()
                    }

                    let totalCompletedOrderCount = self.viewModel.totalCompletedOrderCount(pageNumber: pageNumber)
                    ServiceLocator.analytics.track(event: .ordersListLoaded(totalDuration: totalDuration,
                                                                            pageNumber: pageNumber,
                                                                            filters: self.viewModel.filters,
                                                                            totalCompletedOrders: totalCompletedOrderCount))
                }

                self.transitionToResultsUpdatedState()
                self.refreshControl.endRefreshing()
                onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }

    /// Sets the current top banner in the table view header
    ///
    private func showTopBannerView() {
        guard let topBannerView = topBannerView else { return }

        // Configure header container view
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 0))
        headerContainer.addSubview(topBannerView)
        headerContainer.pinSubviewToAllEdges(topBannerView)

        tableView.tableHeaderView = headerContainer
        tableView.updateHeaderHeight()
    }

    /// Hide the top banner from the table view header
    ///
    private func hideTopBannerView() {
        topBannerView?.removeFromSuperview()
        topBannerView = nil
        if tableView.tableHeaderView != nil {
            // Setting tableHeaderView = nil when having a previous value keeps an extra header space (See p5T066-3c3#comment-12307)
            // This solution avoids it by adding an almost zero height header (Originally from https://stackoverflow.com/a/18938763/428353)
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNonzeroMagnitude))
        }

        tableView.updateHeaderHeight()
    }
}

// MARK: - Spinner Helpers
//
extension OrderListViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        footerSpinnerView.startAnimating()
    }

    /// Whenever we're sync'ing an Orders Page that's beyond what we're currently displaying, this method will return *true*.
    ///
    private func mustStartFooterSpinner() -> Bool {
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced,
              let dataSource else {
            return false
        }

        return highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize > dataSource.numberOfItems
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
    }
}

// MARK: - Split view helpers
//
private extension OrderListViewController {
    /// Highlights the selected row if any row has been selected and the split view is not collapsed.
    /// Removes the selected state otherwise.
    ///
    func highlightSelectedRowIfNeeded(shouldScrollIfNeeded: Bool = false) {
        guard let selectedOrderID, let orderIndexPath = indexPath(for: selectedOrderID) else {
            tableView.deselectSelectedRowWithAnimation(true)
            return
        }
        if splitViewController?.isCollapsed == true {
            tableView.deselectRow(at: orderIndexPath, animated: false)
        } else {
            tableView.selectRow(at: orderIndexPath, animated: false, scrollPosition: .none)
            if shouldScrollIfNeeded {
                tableView.scrollToRow(at: orderIndexPath, at: .none, animated: true)
            }
        }
    }

    /// Focus code crashes on iPadOS 16 and 16.1 versions
    /// peaMlT-Ng-p2
    /// https://github.com/woocommerce/woocommerce-ios/issues/13485
    private func supportsFocus() -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return true
        }

        if #available(iOS 16.2, *) {
            return true
        } else {
            return false
        }
    }

    /// Checks to see if there is a selected order ID, and selects its order.
    /// Otherwise, try to select first item.
    ///
    func checkSelectedItem() {
        guard let orderID = selectedOrderID else {
            selectFirstItemIfPossible()
            return
        }
        let selected = selectOrderFromListIfPossible(for: orderID)
        if !selected {
            selectedIndexPath = nil
            switchDetailsHandler([], 0, true, nil)
        }
    }

    /// Attempts setting the first item in the list as selected if there's any item at all.
    /// Otherwise, triggers closure to remove the current selected item from the split view's secondary column.
    ///
    func selectFirstItemIfPossible() {
        let firstIndexPath = IndexPath(row: 0, section: 0)
        guard let objectID = dataSource?.itemIdentifier(for: firstIndexPath),
              let orderDetailsViewModel = viewModel.detailsViewModel(withID: objectID),
                state != .empty else {
            selectedOrderID = nil
            selectedIndexPath = nil
            return switchDetailsHandler([], 0, false, nil)
        }
        switchDetailsHandler([orderDetailsViewModel], 0, false) { [weak self] hasBeenSelected in
            guard let self else { return }
            if hasBeenSelected {
                onOrderSelected(id: orderDetailsViewModel.order.orderID)
            }
        }
    }

    func indexPath(for orderID: Int64) -> IndexPath? {
        guard let dataSource else {
            return nil
        }
        for identifier in dataSource.snapshot().itemIdentifiers {
            if let detailsViewModel = viewModel.detailsViewModel(withID: identifier),
               detailsViewModel.order.orderID == orderID,
               let indexPath = dataSource.indexPath(for: identifier) {
                return indexPath
            }
        }
        return nil
    }
}

extension OrderListViewController {
    /// Adds ability to select any order
    /// Used when opening an order with deep link
    /// - Parameter orderID: ID of the order to select in the list.
    /// - Returns: Whether the order to select is in the list already (i.e. the order has been fetched and exists locally).
    func selectOrderFromListIfPossible(for orderID: Int64) -> Bool {
        guard let dataSource else {
            return false
        }
        for identifier in dataSource.snapshot().itemIdentifiers {
            if let detailsViewModel = viewModel.detailsViewModel(withID: identifier),
               detailsViewModel.order.orderID == orderID {
                let orderNotAlreadySelected = selectedOrderID != orderID
                let indexPath = dataSource.indexPath(for: identifier)
                let indexPathNotAlreadySelected = selectedIndexPath != indexPath
                let shouldSwitchDetails = orderNotAlreadySelected || indexPathNotAlreadySelected
                if shouldSwitchDetails {
                    showOrderDetails(detailsViewModel.order)
                }
                else {
                    onOrderSelected(id: orderID)
                }
                return true
            }
        }
        return false
    }

    func showOrderDetails(_ order: Order, shouldScrollIfNeeded: Bool = false, onCompletion: ((Bool) -> Void)? = nil) {
        let viewModel = OrderDetailsViewModel(order: order)
        switchDetailsHandler([viewModel], 0, true) { [weak self] hasBeenSelected in
            guard let self else { return }
            if hasBeenSelected {
                onOrderSelected(id: order.orderID, shouldScrollIfNeeded: shouldScrollIfNeeded)
            }
            onCompletion?(hasBeenSelected)
        }
    }
}

// MARK: - Placeholders & Ghostable Table
//
private extension OrderListViewController {

    /// Renders the Placeholder Orders
    ///
    func displayPlaceholderOrders() {
        displayGhostContent()
    }

    /// Removes the Placeholder Orders (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderOrders() {
        removeGhostContent()
    }
}

// MARK: - Empty state view configuration
//
private extension OrderListViewController {
    /// Shows the EmptyStateViewController
    ///
    func displayEmptyViewController() {
        let childController = emptyStateViewController

        // Abort if we are already displaying this childController
        guard childController.parent == nil else {
            return
        }
        guard let childView = childController.view else {
            return
        }

        childController.configure(createFilterConfig())

        // Show Error Loading Data banner if the empty state is caused by a sync error
        if let error = viewModel.dataLoadingError {
            childController.showTopBannerView(for: error)
        } else {
            childController.hideTopBannerView()
        }

        childView.translatesAutoresizingMaskIntoConstraints = false

        addChild(childController)
        view.addSubview(childView)
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: tableView.topAnchor),
            childView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
        childController.didMove(toParent: self)

        // Make sure the banner is on top of the empty state view
        storePlanBannerPresenter?.bringBannerToFront()
    }

    func removeEmptyViewController() {
        let childController = emptyStateViewController

        guard childController.parent == self,
            let childView = childController.view else {
            return
        }

        childController.willMove(toParent: nil)
        childView.removeFromSuperview()
        childController.removeFromParent()
    }

    /// Empty state config
    ///
    func createFilterConfig() ->  EmptyStateViewController.Config {
        guard let filters = viewModel.filters, filters.numberOfActiveFilters != 0 else {
            return noOrdersAvailableConfig()
        }

        return noOrdersMatchFilterConfig()
    }

    /// Creates EmptyStateViewController.Config when there are no orders available
    ///
    func noOrdersAvailableConfig() -> EmptyStateViewController.Config {

        let analytics = ServiceLocator.analytics
        if viewModel.shouldEnableTestOrder, let url = viewModel.siteURL {

            analytics.track(event: .TestOrder.entryPointDisplayed())
            return .withButton(message: NSAttributedString(string: Localization.allOrdersEmptyStateMessage),
                               image: .emptyOrdersImage,
                               details: Localization.createTestOrderDetail,
                               buttonTitle: Localization.tryTestOrder,
                               onTap: { [weak self] _ in
                guard let self else { return }
                analytics.track(event: .TestOrder.tryTestOrderTapped())
                let hostingController = CreateTestOrderHostingController {
                    analytics.track(event: .TestOrder.testOrderStarted())
                    UIApplication.shared.open(url)
                }
                self.present(UINavigationController(rootViewController: hostingController), animated: true)
            }, onPullToRefresh: { [weak self] refreshControl in
                self?.pullToRefresh(sender: refreshControl)
            })
        }

        /// Otherwise, show link to Woo blog.
        return .withLink(message: NSAttributedString(string: Localization.allOrdersEmptyStateMessage),
                         image: .emptyOrdersImage,
                         details: Localization.allOrdersEmptyStateDetail,
                         linkTitle: Localization.learnMore,
                         linkURL: WooConstants.URLs.blog.asURL()) { [weak self] refreshControl in
            self?.pullToRefresh(sender: refreshControl)
        }
    }

    /// Creates EmptyStateViewController.Config for no orders matching the filter empty view
    ///
    func noOrdersMatchFilterConfig() -> EmptyStateViewController.Config {
        let boldSearchKeyword = NSAttributedString(string: viewModel.filters?.readableString ?? String(),
                                                   attributes: [.font: EmptyStateViewController.Config.messageFont.bold])
        let message = NSMutableAttributedString(string: Localization.filteredOrdersEmptyStateMessage)
        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)

        return EmptyStateViewController.Config.withButton(
            message: message,
            image: .emptySearchResultsImage,
            details: "",
            buttonTitle: Localization.clearButton,
            onTap: { [weak self] button in
                self?.delegate?.clearFilters()
            },
            onPullToRefresh: { [weak self] refreshControl in
                self?.pullToRefresh(sender: refreshControl)
            })
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension OrderListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if splitViewController?.isCollapsed == true {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard state != .placeholder else {
            return
        }

        guard let objectID = dataSource?.itemIdentifier(for: indexPath),
            let orderDetailsViewModel = viewModel.detailsViewModel(withID: objectID) else {
                return
        }

        selectedIndexPath = indexPath
        let order = orderDetailsViewModel.order
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderOpen(order: order,
                                                                                 horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        selectedOrderID = order.orderID
        let allViewModels = allViewModels()
        let currentIndex = allViewModels.firstIndex(where: { $0.order.orderID == order.orderID })

        guard let currentIndex = currentIndex else { return }

        let allowOrderNavigation = splitViewController?.isCollapsed ?? true
        // There is no point of having order navigation in the order details view when we have a split screen,
        // because orders can be easily selected in the left view (orders list).
        // Passing just one order (the selected one) disables navigation
        allowOrderNavigation ? switchDetailsHandler(allViewModels, currentIndex, true, nil) :
        switchDetailsHandler([orderDetailsViewModel], 0, true, nil)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let itemIndex = dataSource?.indexOfItem(for: indexPath) else {
            return
        }

        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: itemIndex)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let reuseIdentifier = TwoColumnSectionHeaderView.reuseIdentifier
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? TwoColumnSectionHeaderView else {
            return nil
        }

        header.leftText = {
            guard let sectionIdentifier = dataSource?.sectionIdentifier(for: section) else {
                return nil
            }

            return viewModel.sectionTitleFor(sectionIdentifier: sectionIdentifier)
        }()
        header.rightText = nil

        return header
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.orderListScrollViewDidScroll(scrollView)
    }

    /// Provide an implementation to show cell swipe actions. Return `nil` to provide no action.
    ///
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        /// Fetch the order view model and make sure the order is not marked as completed before proceeding.
        ///
        guard let objectID = dataSource?.itemIdentifier(for: indexPath),
              let cellViewModel = viewModel.cellViewModel(withID: objectID),
              cellViewModel.status != .completed else {
                  return nil
              }
        let markAsCompletedAction = UIContextualAction(style: .normal, title: Localization.markCompleted, handler: { [weak self] _, _, completionHandler in
            self?.markOrderAsCompleted(resultID: objectID)
            completionHandler(true) // Tells the table that the action was performed and forces it to go back to its original state (un-swiped)
        })
        markAsCompletedAction.backgroundColor = .brand
        markAsCompletedAction.image = .checkmarkImage

        return UISwipeActionsConfiguration(actions: [markAsCompletedAction])
    }
}

// MARK: - Finite State Machine Management
//
private extension OrderListViewController {

    func didEnter(state: State) {
        switch state {
        case .empty:
            displayEmptyViewController()
        case .placeholder:
            displayPlaceholderOrders()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        case .results:
            glanceTrailingActionsIfNeeded()
        }
    }

    func didLeave(state: State) {
        switch state {
        case .empty:
            removeEmptyViewController()
        case .placeholder:
            removePlaceholderOrders()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        case .results:
            break
        }
    }

    /// Should be called before Sync'ing. Transitions to either `results` or `placeholder` state, depending on whether if
    /// we've got cached results, or not.
    ///
    func transitionToSyncingState() {
        guard let dataSource else {
            return
        }
        state = dataSource.isEmpty ? .placeholder : .syncing
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` or `.empty`.
    ///
    func transitionToResultsUpdatedState() {
        guard let dataSource else {
            return
        }
        state = dataSource.isEmpty ? .empty : .results
    }
}

// MARK: Top Banner Factories
private extension OrderListViewController {
    /// Sets the `topBannerView` property to an error banner.
    ///
    func setErrorTopBanner(for error: Error) {
        topBannerView = ErrorTopBannerFactory.createTopBanner(for: error,
                                                              expandedStateChangeHandler: { [weak self] in
            self?.tableView.updateHeaderHeight()
        },
        onTroubleshootButtonPressed: { [weak self] in
            guard let self = self else { return }

            ServiceLocator.analytics.track(event: .ConnectivityTool.topBannerTroubleshootTapped())
            let connectivityToolViewController = ConnectivityToolViewController()
            self.show(connectivityToolViewController, sender: self)
        },
        onContactSupportButtonPressed: { [weak self] in
            guard let self = self else { return }
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        })
        showTopBannerView()
    }

    func allViewModels() -> [OrderDetailsViewModel] {
        let ids = (0...tableView.numberOfSections - 1)
            .map { section in
                (0...tableView.numberOfRows(inSection: section) - 1)
                    .compactMap { row in
                        dataSource?.itemIdentifier(for: IndexPath(row: row, section: section))
                    }
            }

        return ids
            .flatMap { rows in
                rows.compactMap { id in
                    viewModel.detailsViewModel(withID: id)
                }
            }
    }
}

// MARK: - Constants
//
private extension OrderListViewController {
    enum Localization {
        static let allOrdersEmptyStateMessage = NSLocalizedString("Waiting for your first order",
                                                                  comment: "The message shown in the Orders → All Orders tab if the list is empty.")
        static let allOrdersEmptyStateDetail = NSLocalizedString("Explore how you can increase your store sales",
                                                                 comment: "The detailed message shown in the Orders → All Orders tab if the list is empty.")
        static let learnMore = NSLocalizedString("Learn more", comment: "Title of button shown in the Orders → All Orders tab if the list is empty.")
        static let createTestOrderDetail = NSLocalizedString(
            "Run a test order to ensure your WooCommerce process delivers a seamless customer experience.",
            comment: "Message shown in Orders → All Orders tab if the list is empty and the site has been launched"
        )
        static let tryTestOrder = NSLocalizedString(
            "Try a Test Order",
            comment: "Title of button shown in Orders → All Orders tab if the list is empty and the site has been launched"
        )
        static let filteredOrdersEmptyStateMessage = NSLocalizedString("We're sorry, we couldn't find any order that match %@",
                   comment: "Message for empty Orders filtered results. The %@ is a placeholder for the filters entered by the user.")
        static let clearButton = NSLocalizedString("Clear Filters",
                                 comment: "Action to remove filters orders on the placeholder overlay when no orders match the filter on the Order List")

        static let markCompleted = NSLocalizedString("Mark Completed", comment: "Title for the swipe order action to mark it as completed")

        static let shareFeedbackButton = NSLocalizedString("Share feedback",
                                                           comment: "Title of the feedback action button on the In-Person Payments feedback banner"
        )

        static let remindMeLater = NSLocalizedString("Remind me later",
                                                     comment: "Title of the button shown when the In-Person Payments feedback banner is dismissed."
        )

        static let dontShowAgain = NSLocalizedString("Don't show again",
                                                     comment: "Title of the button shown when the In-Person Payments feedback banner is dismissed."
        )

        static func markCompletedNoticeTitle(orderID: Int64) -> String {
            let format = NSLocalizedString(
                "Order #%1$d marked as completed",
                comment: "Notice title when an order is marked as completed via a swipe action. Parameter: Order Number"
            )
            return String.localizedStringWithFormat(format, orderID)
        }

        static func markCompletedErrorNoticeTitle(orderID: Int64) -> String {
            let format = NSLocalizedString(
                "Error updating Order #%1$d",
                comment: "Notice title when marking an order as completed via a swipe action fails. Parameter: Order Number"
            )
            return String.localizedStringWithFormat(format, orderID)
        }
    }

    enum Settings {
        static let estimatedHeaderHeight = CGFloat(43)
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }

    enum State {
        case placeholder
        case syncing
        case results
        case empty
    }
}

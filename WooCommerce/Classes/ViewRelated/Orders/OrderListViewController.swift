import Combine
import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import StoreKit

// Used for protocol conformance of IndicatorInfoProvider only.
import XLPagerTabStrip

private typealias SyncReason = OrderListSyncActionUseCase.SyncReason

protocol OrderListViewControllerDelegate: AnyObject {
    /// Called when `OrderListViewController` (or `OrdersViewController`) is about to fetch Orders from the API.
    ///
    func orderListViewControllerWillSynchronizeOrders(_ viewController: UIViewController)

    /// Called when an order list `UIScrollView`'s `scrollViewDidScroll` event is triggered from the user.
    ///
    func orderListScrollViewDidScroll(_ scrollView: UIScrollView)

    /// Called when a user press a clear filters button. Eg. the clear filters button in the empty screen.
    ///
    func clearFilters()
}

/// OrderListViewController: Displays the list of Orders associated to the active Store / Account.
///
final class OrderListViewController: UIViewController {

    weak var delegate: OrderListViewControllerDelegate?

    private let viewModel: OrderListViewModel

    /// Main TableView.
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.accessibilityIdentifier = "orders-table-view"
        return tableView
    }()

    /// The data source that is bound to `tableView`.
    private lazy var dataSource: UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID> = {
        let dataSource = UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>(
            tableView: self.tableView,
            cellProvider: self.makeCellProvider()
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }()

    /// Ghostable TableView.
    ///
    private(set) var ghostableTableView = UITableView(frame: .zero, style: .grouped)

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

    /// The configuration to use for the view if the list is empty.
    ///
    private let emptyStateConfig: EmptyStateViewController.Config

    /// The view shown if the list is empty.
    ///
    private lazy var emptyStateViewController = EmptyStateViewController(style: .list)

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Timestamp for last successful sync.
    ///
    private var lastFullSyncTimestamp: Date?

    /// Minimum time interval allowed between full sync.
    ///
    private let minimalIntervalBetweenSync: TimeInterval = 30

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
    private var topBannerView: TopBannerView?

    /// Callback closure when an order is selected
    ///
    private var switchDetailsHandler: (OrderDetailsViewModel) -> Void

    /// Currently selected index path in the table view
    ///
    private var selectedIndexPath: IndexPath?

    // MARK: - View Lifecycle

    /// Designated initializer.
    ///
    init(siteID: Int64,
         title: String,
         viewModel: OrderListViewModel,
         emptyStateConfig: EmptyStateViewController.Config,
         switchDetailsHandler: @escaping (OrderDetailsViewModel) -> Void) {
        self.siteID = siteID
        self.viewModel = viewModel
        self.emptyStateConfig = emptyStateConfig
        self.switchDetailsHandler = switchDetailsHandler

        super.init(nibName: nil, bundle: nil)

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

        registerTableViewHeadersAndCells()
        configureTableView()
        configureGhostableTableView()

        configureViewModel()
        configureSyncingCoordinator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.syncOrderStatuses()

        syncingCoordinator.resynchronize(reason: SyncReason.viewWillAppear.rawValue)

        // Fix any incomplete animation of the refresh control
        // when switching tabs mid-animation
        refreshControl.resetAnimation(in: tableView)

        // Fix any _incomplete_ animation if the orders were deleted and refetched from
        // a different location (or Orders tab).
        //
        // We can remove this once we've replaced XLPagerTabStrip.
        tableView.reloadData()

        restartPlaceholderAnimation()

        // restore highlight for selected row after table reload
        highlightSelectedRowIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateHeaderHeight()
        // restore or remove highlight for selected row
        highlightSelectedRowIfNeeded()
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
            guard let self = self,
                  // Avoid synchronizing if the view is not visible. The refresh will be handled in
                  // `viewWillAppear` instead.
                  self.viewIfLoaded?.window != nil else {
                return
            }

            self.syncingCoordinator.resynchronize()
        }

        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = { [weak self] in
            self?.syncingCoordinator.resynchronize(reason: SyncReason.newFiltersApplied.rawValue)
        }

        viewModel.activate()

        /// Update the `dataSource` whenever there is a new snapshot.
        viewModel.snapshot.sink { [weak self] snapshot in
            self?.dataSource.apply(snapshot)
            // restore highlight for selected row after table reload
            self?.highlightSelectedRowIfNeeded()
        }.store(in: &cancellables)

        /// Update the top banner when needed
        viewModel.$topBanner
            .sink { [weak self] topBannerType in
                guard let self = self else { return }
                switch topBannerType {
                case .none:
                    self.hideTopBannerView()
                case .error:
                    self.setErrorTopBanner()
                case .simplePayments:
                    self.setSimplePaymentsEnabledTopBanner()
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
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
        tableView.estimatedSectionHeaderHeight = Settings.estimatedHeaderHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)
    }

    /// Setup: Ghostable TableView
    ///
    func configureGhostableTableView() {
        view.addSubview(ghostableTableView)
        ghostableTableView.isHidden = true

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ghostableTableView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ghostableTableView.heightAnchor.constraint(equalTo: tableView.heightAnchor),
            ghostableTableView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            ghostableTableView.topAnchor.constraint(equalTo: tableView.topAnchor)
        ])

        view.backgroundColor = .listBackground
        ghostableTableView.backgroundColor = .listBackground
        ghostableTableView.isScrollEnabled = false
    }

    /// Registers all of the available table view cells and headers
    ///
    func registerTableViewHeadersAndCells() {
        tableView.registerNib(for: OrderTableViewCell.self)
        ghostableTableView.registerNib(for: OrderTableViewCell.self)

        let headerType = TwoColumnSectionHeaderView.self
        tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
    }
}

// MARK: - Actions
//
extension OrderListViewController {
    @objc func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.ordersListPulledToRefresh)
        delegate?.orderListViewControllerWillSynchronizeOrders(self)
        viewModel.syncOrderStatuses()
        syncingCoordinator.resynchronize(reason: SyncReason.pullToRefresh.rawValue) {
            sender.endRefreshing()
        }
    }
}

// MARK: - Sync'ing Helpers
//
extension OrderListViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        if pageNumber == syncingCoordinator.pageFirstIndex,
           reason == SyncReason.viewWillAppear.rawValue,
           let lastFullSyncTimestamp = lastFullSyncTimestamp,
           Date().timeIntervalSince(lastFullSyncTimestamp) < minimalIntervalBetweenSync {
            // less than 30 s from last full sync
            onCompletion?(true)
            return
        }

        transitionToSyncingState()
        viewModel.hasErrorLoadingData = false

        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            reason: SyncReason(rawValue: reason ?? "")) { [weak self] totalDuration, error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    DDLogError("⛔️ Error synchronizing orders: \(error)")
                    self.viewModel.hasErrorLoadingData = true
                } else {
                    if pageNumber == self.syncingCoordinator.pageFirstIndex {
                        // save timestamp of last successful update
                        self.lastFullSyncTimestamp = Date()
                    }
                    ServiceLocator.analytics.track(event: .ordersListLoaded(totalDuration: totalDuration,
                                                                            pageNumber: pageNumber,
                                                                            filters: self.viewModel.filters))
                }

                self.transitionToResultsUpdatedState()
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
        tableView.tableHeaderView = nil
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
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced else {
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
    func highlightSelectedRowIfNeeded() {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        if splitViewController?.isCollapsed == true {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
        } else {
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        }
    }
}


// MARK: - Placeholders & Ghostable Table
//
private extension OrderListViewController {

    /// Renders the Placeholder Orders
    ///
    func displayPlaceholderOrders() {
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: OrderTableViewCell.reuseIdentifier,
                                   rowsPerSection: Settings.placeholderRowsPerSection)

        // If the ghostable table view gets stuck for any reason,
        // let's reset the state before using it again
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: options,
                                               style: Constants.ghostStyle)
        ghostableTableView.startGhostAnimation()
        ghostableTableView.isHidden = false
    }

    /// Removes the Placeholder Orders (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderOrders() {
        ghostableTableView.isHidden = true
        ghostableTableView.stopGhostAnimation()
        ghostableTableView.removeGhostContent()
    }

    /// After returning to the screen, `restartGhostAnimation` is required to resume ghost animation.
    func restartPlaceholderAnimation() {
        guard ghostableTableView.isHidden == false else {
            return
        }
        ghostableTableView.restartGhostAnimation(style: Constants.ghostStyle)
    }

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
        if viewModel.hasErrorLoadingData {
            childController.showTopBannerView()
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
            return emptyStateConfig
        }

        return noOrdersMatchFilterConfig()
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
            buttonTitle: Localization.clearButton) { [weak self] button in
                self?.delegate?.clearFilters()
            }
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

        guard let objectID = dataSource.itemIdentifier(for: indexPath),
            let orderDetailsViewModel = viewModel.detailsViewModel(withID: objectID) else {
                return
        }

        selectedIndexPath = indexPath
        let order = orderDetailsViewModel.order
        ServiceLocator.analytics.track(.orderOpen, withProperties: ["id": order.orderID,
                                                                    "status": order.status.rawValue])

        switchDetailsHandler(orderDetailsViewModel)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let itemIndex = dataSource.indexOfItem(for: indexPath) else {
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
            guard let sectionIdentifier = dataSource.sectionIdentifier(for: section) else {
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
            break
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
        state = dataSource.isEmpty ? .placeholder : .syncing
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` or `.empty`.
    ///
    func transitionToResultsUpdatedState() {
        state = dataSource.isEmpty ? .empty : .results
    }
}

// MARK: - IndicatorInfoProvider Conformance

// This conformance is not used directly by `OrderListViewController`. We only need this because
// `Self` is used as a child of `OrdersTabbedViewController` which is a
// `ButtonBarPagerTabStripViewController`.
extension OrderListViewController: IndicatorInfoProvider {
    /// Return `self.title` under `IndicatorInfo`.
    ///
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: title)
    }
}

// MARK: Top Banner Factories
private extension OrderListViewController {
    /// Sets the `topBannerView` property to an error banner.
    ///
    func setErrorTopBanner() {
        topBannerView = ErrorTopBannerFactory.createTopBanner(isExpanded: false, expandedStateChangeHandler: { [weak self] in
            self?.tableView.updateHeaderHeight()
        },
        onTroubleshootButtonPressed: { [weak self] in
            let safariViewController = SFSafariViewController(url: WooConstants.URLs.troubleshootErrorLoadingData.asURL())
            self?.present(safariViewController, animated: true, completion: nil)
        },
        onContactSupportButtonPressed: { [weak self] in
            guard let self = self else { return }
            ZendeskProvider.shared.showNewRequestIfPossible(from: self, with: nil)
        })
        showTopBannerView()
    }

    /// Sets the `topBannerView` property to a simple payments enabled banner.
    ///
    func setSimplePaymentsEnabledTopBanner() {
        topBannerView = SimplePaymentsTopBannerFactory.createFeatureEnabledBanner(onTopButtonPressed: { [weak self] in
            self?.tableView.updateHeaderHeight()
        }, onDismissButtonPressed: { [weak self] in
            self?.viewModel.hideSimplePaymentsBanners = true
        }, onGiveFeedbackButtonPressed: { [weak self] in
            let surveyNavigation = SurveyCoordinatingController(survey: .simplePaymentsPrototype)
            self?.present(surveyNavigation, animated: true, completion: nil)
        })
        showTopBannerView()
    }
}

// MARK: - Constants
//
private extension OrderListViewController {
    enum Localization {
        static let filteredOrdersEmptyStateMessage = NSLocalizedString("We're sorry, we couldn't find any order that match %@",
                   comment: "Message for empty Orders filtered results. The %@ is a placeholder for the filters entered by the user.")
        static let clearButton = NSLocalizedString("Clear Filters",
                                 comment: "Action to remove filters orders on the placeholder overlay when no orders match the filter on the Order List")
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

    enum Constants {
        static let ghostStyle: GhostStyle = .wooDefaultGhostStyle
    }
}

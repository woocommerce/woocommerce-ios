import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging

/// A generic data source for the paginated list selector UI `PaginatedListSelectorViewController`.
///
protocol PaginatedListSelectorDataSource {
    associatedtype StorageModel: ResultsControllerMutableType
    associatedtype Cell: UITableViewCell

    /// The model that is currently selected in the list.
    var selected: StorageModel.ReadOnlyType? { get }

    /// Creates a results controller that defines the data to fetch.
    func createResultsController() -> ResultsController<StorageModel>

    /// Called when a different model is selected.
    mutating func handleSelectedChange(selected: StorageModel.ReadOnlyType)

    /// Configures the selected UI.
    func isSelected(model: StorageModel.ReadOnlyType) -> Bool

    /// Configures the cell with the given model.
    func configureCell(cell: Cell, model: StorageModel.ReadOnlyType)

    /// Called when the UI is requesting to sync another page of data.
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?)
}

/// Displays a paginated list (implemented by table view) for the user to select a generic model.
///
final class PaginatedListSelectorViewController<DataSource: PaginatedListSelectorDataSource, Model, StorageModel, Cell>: UIViewController,
    UITableViewDataSource, UITableViewDelegate, SyncingCoordinatorDelegate
where DataSource.StorageModel == StorageModel, Model == DataSource.StorageModel.ReadOnlyType, Model: Equatable, DataSource.Cell == Cell {
    private let viewProperties: PaginatedListSelectorViewProperties
    private var dataSource: DataSource
    private let onDismiss: (_ selected: Model?) -> Void

    private let rowType = Cell.self

    private lazy var tableView: UITableView = UITableView(frame: .zero, style: viewProperties.tableViewStyle)

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = {
        return FooterSpinnerView(tableViewStyle: tableView.style)
    }()

    private lazy var footerEmptyView = {
        return UIView(frame: .zero)
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Product Variations in sync.
    ///
    private lazy var resultsController: ResultsController<StorageModel> = {
        let resultsController = dataSource.createResultsController()
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
        return resultsController
    }()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    private lazy var stateCoordinator: PaginatedListViewControllerStateCoordinator = {
        let stateCoordinator = PaginatedListViewControllerStateCoordinator(onLeavingState: { [weak self] state in
            self?.didLeave(state: state)
            }, onEnteringState: { [weak self] state in
                self?.didEnter(state: state)
        })
        return stateCoordinator
    }()

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    // MARK: - Constants
    //
    let estimatedRowHeight = CGFloat(44)
    let placeholderRowsPerSection: [Int] = [3]

    init(viewProperties: PaginatedListSelectorViewProperties,
         dataSource: DataSource,
         onDismiss: @escaping (_ selected: Model?) -> Void) {
        self.viewProperties = viewProperties
        self.dataSource = dataSource
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureSyncingCoordinator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.synchronizeFirstPage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onDismiss(dataSource.selected)
        super.viewWillDisappear(animated)
    }

    // MARK: UITableViewDataSource
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: rowType.reuseIdentifier,
                                                       for: indexPath) as? Cell else {
                                                        fatalError()
        }
        let model = resultsController.object(at: indexPath)
        dataSource.configureCell(cell: cell, model: model)

        cell.accessoryType = dataSource.isSelected(model: model) ? .checkmark: .none

        return cell
    }

    // MARK: UITableViewDelegate
    //

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = resultsController.object(at: indexPath)
        dataSource.handleSelectedChange(selected: selected)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let objectIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: objectIndex)

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }

    // MARK: SyncingCoordinatorDelegate
    //
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState(pageNumber: pageNumber)
        dataSource.sync(pageNumber: pageNumber, pageSize: pageSize) { [weak self] isCompleted in
            guard let self = self else {
                return
            }

            guard isCompleted else {
                DDLogError("⛔️ Error synchronizing models")
                self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
                return
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(isCompleted)
        }
    }

    // MARK: actions
    //
    @objc private func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.productVariationListPulledToRefresh)

        syncingCoordinator.synchronizeFirstPage {
            sender.endRefreshing()
        }
    }
}

// MARK: - View Configuration
//
private extension PaginatedListSelectorViewController {

    func configureNavigation() {
        title = viewProperties.navigationBarTitle
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.refreshControl = refreshControl

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)

        registerTableViewCells()
    }

    func registerTableViewCells() {
        guard Bundle.main.path(forResource: rowType.classNameWithoutNamespaces, ofType: "nib") != nil else {
            tableView.register(rowType.self, forCellReuseIdentifier: rowType.reuseIdentifier)
            return
        }
        tableView.register(rowType.loadNib(), forCellReuseIdentifier: rowType.reuseIdentifier)
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }
}

// MARK: - Finite State Machine Management
//
private extension PaginatedListSelectorViewController {

    func didEnter(state: PaginatedListViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            displayNoResultsOverlay()
        case .syncing:
            if isEmpty {
                displayPlaceholderProducts()
            } else {
                ensureFooterSpinnerIsStarted()
            }
        case .results:
            break
        }
    }

    func didLeave(state: PaginatedListViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            removeAllOverlays()
        case .syncing:
            ensureFooterSpinnerIsStopped()
            removePlaceholderProducts()
        case .results:
            break
        }
    }

    func transitionToSyncingState(pageNumber: Int) {
        stateCoordinator.transitionToSyncingState(pageNumber: pageNumber)
    }

    func transitionToResultsUpdatedState() {
        stateCoordinator.transitionToResultsUpdatedState(hasData: !isEmpty)
    }
}

// MARK: - Placeholders
//
private extension PaginatedListSelectorViewController {

    /// Renders the Placeholder Orders: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderProducts() {
        let options = GhostOptions(reuseIdentifier: Cell.reuseIdentifier, rowsPerSection: placeholderRowsPerSection)
        tableView.displayGhostContent(options: options,
                                      style: .wooDefaultGhostStyle)

        resultsController.stopForwardingEvents()
    }

    /// Removes the Placeholder Products (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderProducts() {
        tableView.removeGhostContent()
        resultsController.startForwardingEvents(to: tableView)
        tableView.reloadData()
    }

    /// Displays the Error Notice.
    ///
    func displaySyncingErrorNotice(pageNumber: Int, pageSize: Int) {
        let message = NSLocalizedString("Unable to refresh list", comment: "Refresh Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.sync(pageNumber: pageNumber, pageSize: pageSize, onCompletion: nil)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = viewProperties.noResultsPlaceholderImage
        overlayView.messageImageTintColor = viewProperties.noResultsPlaceholderImageTintColor
        overlayView.messageText = viewProperties.noResultsPlaceholderText
        overlayView.actionVisible = false
        overlayView.attach(to: view)
    }

    /// Removes all of the the OverlayMessageView instances in the view hierarchy.
    ///
    func removeAllOverlays() {
        for subview in view.subviews where subview is OverlayMessageView {
            subview.removeFromSuperview()
        }
    }
}

// MARK: - Spinner Helpers
//
extension PaginatedListSelectorViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        tableView.tableFooterView = footerSpinnerView
        footerSpinnerView.startAnimating()
    }

    /// Whenever we're sync'ing an Products Page that's beyond what we're currently displaying, this method will return *true*.
    ///
    private func mustStartFooterSpinner() -> Bool {
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced else {
            return false
        }

        return highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize > resultsController.numberOfObjects
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
        tableView.tableFooterView = footerEmptyView
    }
}

// MARK: - ResultsController
//
private extension PaginatedListSelectorViewController {

    func configureResultsController(_ resultsController: ResultsController<StorageModel>, onReload: @escaping () -> Void) {
        resultsController.onDidChangeContent = {
            onReload()
        }

        resultsController.onDidResetContent = {
            onReload()
        }

        do {
            try resultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }

        tableView.reloadData()
    }
}

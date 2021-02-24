import UIKit
import Yosemite

/// The UI that shows the approved Reviews related to a specific product.
final class ProductReviewsViewController: UIViewController {

    private let product: Product

    private let viewModel: ProductReviewsViewModel

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            willEnter(state: state)

            guard oldValue != state else {
                return
            }
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return viewModel.isEmpty
    }

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - View Lifecycle
    init(product: Product) {
        self.product = product
        viewModel = ProductReviewsViewModel(siteID: product.siteID, data: ProductReviewsDataSource(product: product))
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureSyncingCoordinator()
        configureTableView()
        configureTableViewCells()
        configureResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.synchronizeFirstPage()
    }
}


// MARK: - User Interface Initialization
//
private extension ProductReviewsViewController {

    /// Setup: View properties
    ///
    func configureView() {
        navigationItem.title = NSLocalizedString(
            "Reviews",
            comment: "Title that appears on top of the Product Reviews screen."
        )
        view.backgroundColor = .listBackground
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.dataSource = viewModel.dataSource
        tableView.delegate = self
        tableView.tableFooterView = footerSpinnerView
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.allowsSelection = false
    }

    /// Setup: ResultsController
    ///
    func configureResultsController() {
        viewModel.configureResultsController(tableView: tableView)
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells() {
        viewModel.configureTableViewCells(tableView: tableView)
    }
}


// MARK: - Actions
//
private extension ProductReviewsViewController {

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        // TODO: Analytics M3
        syncingCoordinator.synchronizeFirstPage {
            sender.endRefreshing()
        }
    }
}


// MARK: - UITableViewDelegate
extension ProductReviewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, heightForHeaderInSection: section) ?? 0
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, heightForRowAt: indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.delegate.didSelectItem(at: indexPath, in: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.delegate.tableView(tableView, willDisplay: cell, forRowAt: indexPath, with: syncingCoordinator)
    }
}


// MARK: - Placeholders
//
private extension ProductReviewsViewController {

    /// Renders Placeholder Reviews.
    ///
    func displayPlaceholderReviews() {
        viewModel.displayPlaceholderReviews(tableView: tableView)
    }

    /// Removes Placeholder Reviews.
    ///
    func removePlaceholderReviews() {
        viewModel.removePlaceholderReviews(tableView: tableView)
    }

    /// Displays the Empty State Overlay.
    ///
    func displayEmptyOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .emptyReviewsImage
        overlayView.messageText = NSLocalizedString("No Reviews Yet for this Product!", comment: "Empty Product Reviews List Message")
        overlayView.actionText = NSLocalizedString("Share your Store", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            guard let self = self else {
                return
            }
            guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
                return
            }
            guard let url = URL(string: site.url) else {
                return
            }

            ServiceLocator.analytics.track(.reviewsShareStoreButtonTapped)
            SharingHelper.shareURL(url: url, title: site.name, from: overlayView.actionButtonView, in: self)
        }

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

// MARK: - Finite State Machine Management
//
private extension ProductReviewsViewController {

    /// Runs prior to the FSM entering a new state.
    ///
    /// Note: Just because this func runs does not guarantee `didEnter()` or `didLeave()` will run as well.
    ///
    func willEnter(state: State) {
        // no-op for the moment
    }

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .empty:
            if isEmpty == true {
                displayEmptyOverlay()
            }
        case .results:
            break
        case .placeholder:
            displayPlaceholderReviews()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        }
    }

    /// Runs whenever the FSM leaves a State.
    ///
    func didLeave(state: State) {
        switch state {
        case .empty:
            removeAllOverlays()
        case .results:
            break
        case .placeholder:
            removePlaceholderReviews()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        }
    }

    /// Should be called before Sync'ing Starts: Transitions to .results / .syncing
    ///
    func transitionToSyncingState() {
        state = isEmpty ? .placeholder : .syncing
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` / `.emptyFiltered` / `.empty` accordingly.
    ///
    func transitionToResultsUpdatedState() {
        if isEmpty == false {
            state = .results
            return
        }

        state = .empty
    }
}

// MARK: - Sync'ing Helpers
//
extension ProductReviewsViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState()
        viewModel.synchronizeReviews(pageNumber: pageNumber, pageSize: pageSize, productID: product.productID) { [weak self] in
            self?.transitionToResultsUpdatedState()
            onCompletion?(true)
        }
    }
}

// MARK: - Spinner Helpers
//
extension ProductReviewsViewController {

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

        return viewModel.containsMorePages(highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize)
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
    }
}


// MARK: - Nested Types
//
private extension ProductReviewsViewController {
    enum State {
        case placeholder
        case empty
        case results
        case syncing
    }
}

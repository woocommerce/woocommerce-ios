import UIKit
import Gridicons
import Yosemite
import WordPressUI
import CocoaLumberjack


/// OrdersViewController: Displays the list of Orders associated to the active Store / Account.
///
class OrdersViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let storageManager = AppDelegate.shared.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)

        return ResultsController<StorageOrder>(storageManager: storageManager, sectionNameKeyPath: "normalizedAgeAsString", sortedBy: [descriptor])
    }()

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// Indicates if there's a filter being applied.
    ///
    private var isFiltered: Bool {
        return resultsController.predicate != nil
    }

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



    // MARK: - View Lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        tabBarItem.title = NSLocalizedString("Orders", comment: "Orders title")
        tabBarItem.image = Gridicon.iconOfType(.pages)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
        configureResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncOrders()
    }
}


// MARK: - User Interface Initialization
//
private extension OrdersViewController {

    func configureNavigation() {
        title = NSLocalizedString("Orders", comment: "Orders title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.menus),
                                             style: .plain,
                                             target: self,
                                             action: #selector(displayFiltersAlert))
        rightBarButton.tintColor = .white
        rightBarButton.accessibilityLabel = NSLocalizedString("Filter orders", comment: "Filter the orders list.")
        rightBarButton.accessibilityTraits = UIAccessibilityTraitButton
        rightBarButton.accessibilityHint = NSLocalizedString("Filters the order list by payment status.", comment: "VoiceOver accessibility hint, informing the user the button can be used to filter the order list.")
        navigationItem.rightBarButtonItem = rightBarButton

        // Don't show the Order title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.refreshControl = refreshControl
    }

    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
    }
}


// MARK: - Actions
//
extension OrdersViewController {

    @IBAction func displayFiltersAlert() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(FilterAction.dismiss)
        actionSheet.addDefaultActionWithTitle(FilterAction.displayAll) { [weak self] _ in
            self?.resetOrderFilters()
        }

        for status in OrderStatus.knownStatus {
            actionSheet.addDefaultActionWithTitle(status.description) { [weak self] _ in
                self?.displayOrders(with: status)
            }
        }

        actionSheet.addDefaultActionWithTitle(FilterAction.displayCustom) { [weak self] _ in
            self?.displayOrdersWithUnknownStatus()
        }

        present(actionSheet, animated: true)
    }

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        syncOrders {
            sender.endRefreshing()
        }
    }
}


// MARK: - Filters
//
private extension OrdersViewController {

    func displayOrders(with status: OrderStatus) {
        let predicate = NSPredicate(format: "status = %@", status.rawValue)

        updateResultsController(predicate: predicate)
    }

    func displayOrdersWithUnknownStatus() {
        let knownStatus = OrderStatus.knownStatus.map { $0.rawValue }
        let predicate = NSPredicate(format: "NOT (status in %@)", knownStatus)

        updateResultsController(predicate: predicate)
    }

    func resetOrderFilters() {
        updateResultsController(predicate: nil)
    }

    private func updateResultsController(predicate: NSPredicate?)  {
        resultsController.predicate = predicate
        state.transitionToResultsUpdatedState(isEmpty: isEmpty, isFiltered: isFiltered)

        tableView.reloadData()
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrdersViewController {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func syncOrders(onCompletion: (() -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?()
            return
        }

        state.transitionToSyncingState(isEmpty: isEmpty)

        let action = OrderAction.retrieveOrders(siteID: siteID) { [weak self] error in
            guard let `self` = self else {
                return
            }

            defer {
                onCompletion?()
            }

            guard let error = error else {
                self.state.transitionToResultsUpdatedState(isEmpty: self.isEmpty, isFiltered: self.isFiltered)
                return
            }

            DDLogError("⛔️ Error synchronizing orders: \(error)")
            self.state.transitionToErrorState()
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Placeholders
//
private extension OrdersViewController {

    /// Renders the Placeholder Orders: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderOrders() {
        let settings = GhostSettings(reuseIdentifier: OrderListCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(using: settings)

        resultsController.stopForwardingEvents()
    }

    /// Removes the Placeholder Orders (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderOrders() {
        tableView.removeGhostContent()
        resultsController.startForwardingEvents(to: self.tableView)
    }

    /// Displays the Error State Overlay.
    ///
    func displayErrorOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.messageImage = .errorStateImage
        overlayView.messageText = NSLocalizedString("Unable to load the orders list", comment: "Order List Loading Error")
        overlayView.actionText = NSLocalizedString("Retry", comment: "Retry Action")
        overlayView.onAction = { [weak self] in
            self?.syncOrders()
        }

        overlayView.attach(to: view)
    }

    /// Displays the Empty State Overlay.
    ///
    func displayEmptyUnfilteredOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("Waiting for Customers", comment: "Orders List (Empty State / No Filters)")
        overlayView.actionText = NSLocalizedString("Share your Store", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            self?.displayDefaultSite()
        }

        overlayView.attach(to: view)
    }

    /// Displays the Empty State (with filters applied!) Overlay.
    ///
    func displayEmptyFilteredOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("No results for selected criteria", comment: "Orders List (Empty State + Filters)")
        overlayView.actionText = NSLocalizedString("Remove Filters", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            self?.resetOrderFilters()
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

    /// Displays the Default Site in a WebView.
    ///
    func displayDefaultSite() {
        guard let urlAsString = StoresManager.shared.sessionManager.defaultSite?.url, let siteURL = URL(string: urlAsString) else {
            return
        }

        let safariViewController = SafariViewController(url: siteURL)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }
}


// MARK: - Convenience Methods
//
private extension OrdersViewController {

    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel {
        let order = resultsController.object(at: indexPath)
        return OrderDetailsViewModel(order: order)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrdersViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as? OrderListCell else {
            fatalError()
        }

        let viewModel = detailsViewModel(at: indexPath)
        cell.configureCell(order: viewModel)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Order.descriptionForSectionIdentifier(resultsController.sections[section].name)
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrdersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard state == .results else {
            return
        }

        performSegue(withIdentifier: Segues.orderDetails, sender: detailsViewModel(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let singleOrderViewController = segue.destination as? OrderDetailsViewController, let viewModel = sender as? OrderDetailsViewModel else {
            return
        }

        singleOrderViewController.viewModel = viewModel
    }
}


// MARK: - FSM Management
//
private extension OrdersViewController {

    func didEnter(state: State) {
        switch state {
        case .emptyUnfiltered:
            displayEmptyUnfilteredOverlay()
        case .emptyFiltered:
            displayEmptyFilteredOverlay()
        case .error:
            displayErrorOverlay()
        case .placeholder:
            displayPlaceholderOrders()
        case .results:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .emptyFiltered:
            removeAllOverlays()
        case .emptyUnfiltered:
            removeAllOverlays()
        case .error:
            removeAllOverlays()
        case .placeholder:
            removePlaceholderOrders()
        case .results:
            break
        }
    }
}


// MARK: - Nested Types
//
private extension OrdersViewController {

    enum FilterAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let displayAll = NSLocalizedString("All", comment: "All filter title")
        static let displayCustom = NSLocalizedString("Custom", comment: "Title for button that catches all custom labels and displays them on the order list")
    }

    enum Settings {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }

    enum Segues {
        static let orderDetails = "ShowOrderDetailsViewController"
    }

    enum State {
        case placeholder
        case results
        case emptyUnfiltered
        case emptyFiltered
        case error

        /// Should be called before Sync'ing. Transitions to either `results` or `placeholder` state, depending on whether if
        /// we've got cached results, or not.
        ///
        mutating func transitionToSyncingState(isEmpty: Bool) {
            self = isEmpty ? .placeholder : .results
        }

        /// Transitions to the Error State.
        ///
        mutating func transitionToErrorState() {
            self = .error
        }

        /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
        /// Transitions to `.results` / `.emptyFiltered` / `.emptyUnfiltered` accordingly.
        ///
        mutating func transitionToResultsUpdatedState(isEmpty: Bool, isFiltered: Bool) {
            if isEmpty == false  {
                self = .results
                return
            }

            if isFiltered {
                self = .emptyFiltered
                return
            }

            self = .emptyUnfiltered
        }
    }
}

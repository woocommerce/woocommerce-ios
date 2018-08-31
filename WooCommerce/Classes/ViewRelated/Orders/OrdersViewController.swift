import UIKit
import Gridicons
import Yosemite
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

    /// Indicates if there are any Objects matching the criteria (or not).
    ///
    private var displaysNoResults: Bool {
        return resultsController.isEmpty
    }

    /// Indicates if a Filters is in active, or not.
    ///
    private var displaysFilteredResults: Bool {
        return resultsController.predicate != nil
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
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.refreshControl = refreshControl
        tableView.register(NoResultsTableViewCell.loadNib(), forCellReuseIdentifier: NoResultsTableViewCell.reuseIdentifier)
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
        resultsController.predicate = NSPredicate(format: "status = %@", status.rawValue)
        tableView.reloadData()
    }

    func displayOrdersWithUnknownStatus() {
        let knownStatus = OrderStatus.knownStatus.map { $0.rawValue }
        resultsController.predicate = NSPredicate(format: "NOT (status in %@)", knownStatus)
        tableView.reloadData()
    }

    func resetOrderFilters() {
        resultsController.predicate = nil
        tableView.reloadData()
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrdersViewController {

    func syncOrders(onCompletion: (() -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?()
            return
        }

        let action = OrderAction.retrieveOrders(siteID: siteID) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing orders: \(error)")
            }

            onCompletion?()
        }

        StoresManager.shared.dispatch(action)
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
// TODO: Support Loading State + Empty State 
//        guard !displaysNoResults else {
//            return Constants.filterResultsNotFoundSectionCount
//        }

        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
// TODO: Support Loading State + Empty State
//        guard !displaysNoResults else {
//            return Constants.filterResultsNotFoundRowCount
//        }

        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
// TODO: Support Empty State
//        guard !displaysNoResults else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: NoResultsTableViewCell.reuseIdentifier, for: indexPath) as! NoResultsTableViewCell
//            cell.title = NSLocalizedString("No results found. Clear the filter to try again.", comment: "Displays message to user when no filter results were found.")
//            return cell
//        }

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

        guard displaysNoResults == false else {
            return
        }

        performSegue(withIdentifier: Constants.orderDetailsSegue, sender: detailsViewModel(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let singleOrderViewController = segue.destination as? OrderDetailsViewController, let viewModel = sender as? OrderDetailsViewModel else {
            return
        }

        singleOrderViewController.viewModel = viewModel
    }
}


// MARK: - Constants
//
private extension OrdersViewController {
    enum FilterAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let displayAll = NSLocalizedString("All", comment: "All filter title")
        static let displayCustom = NSLocalizedString("Custom", comment: "Title for button that catches all custom labels and displays them on the order list")
    }

    enum Constants {
        static let estimatedRowHeight = CGFloat(86)
        static let orderDetailsSegue = "ShowOrderDetailsViewController"
    }
}

import UIKit
import Gridicons
import Contacts
import Yosemite
import SafariServices


// MARK: - OrderDetailsViewController: Displays the details for a given Order.
//
final class OrderDetailsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: viewModel.order)
    }()

    /// Order to be rendered!
    ///
    var viewModel: OrderDetailsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    private let notices = OrderDetailsNotices()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        configureViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncNotes()
        syncProducts()
        syncRefunds()
        syncTrackingsHidingAddButtonIfNecessary()
    }

    private func syncTrackingsHidingAddButtonIfNecessary() {
        syncTracking { [weak self] error in
            if error == nil {
                self?.viewModel.trackingIsReachable = true
            }

            self?.reloadTableViewSectionsAndData()
        }
    }
}


// MARK: - TableView Configuration
//
private extension OrderDetailsViewController {

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl

        tableView.dataSource = viewModel.dataSource
    }

    /// Setup: Navigation
    ///
    func configureNavigation() {
        title = NSLocalizedString("Order #\(viewModel.order.number)", comment: "Order number title")

        // Don't show the previous title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] order in
            guard let self = self else {
                return
            }
            self.viewModel.updateOrderStatus(order: order)
            self.reloadTableViewSectionsAndData()
        }
        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayOrderDeletedNotice(order: self.viewModel.order)
        }
    }

    private func configureViewModel() {
        viewModel.onUIReloadRequired = { [weak self] in
            self?.reloadTableViewDataIfPossible()
        }

        viewModel.configureResultsControllers { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        viewModel.onCellAction = { [weak self] (actionType, indexPath) in
            self?.handleCellAction(actionType, at: indexPath)
        }
    }

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        reloadSections()
        reloadTableViewDataIfPossible()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.registerTableViewCells(tableView)
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        viewModel.registerTableViewHeaderFooters(tableView)
    }
}


// MARK: - Sections
//
private extension OrderDetailsViewController {

    func reloadSections() {
        viewModel.reloadSections()
    }
}


// MARK: - Notices
//
private extension OrderDetailsViewController {

    /// Displays a Notice onscreen, indicating that the current Order has been deleted from the Store.
    ///
    func displayOrderDeletedNotice(order: Order) {
        notices.displayOrderDeletedNotice(order: order)
    }

    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(order: Order, tracking: ShipmentTracking) {
        notices.displayDeleteErrorNotice(order: order, tracking: tracking) { [weak self] in
            self?.deleteTracking(tracking)
        }
    }
}

// MARK: - Action Handlers
//
extension OrderDetailsViewController {

    @objc func pullToRefresh() {
        ServiceLocator.analytics.track(.orderDetailPulledToRefresh)
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncProducts { _ in
            group.leave()
        }

        group.enter()
        syncRefunds() { _ in
            group.leave()
        }

        group.enter()
        syncNotes { _ in
            group.leave()
        }

        group.enter()
        syncTracking { _ in
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
            self?.refreshControl.endRefreshing()
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrderDetailsViewController {
    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncOrder { [weak self] (order, error) in
            guard let self = self, let order = order else {
                onCompletion?(error)
                return
            }

            self.viewModel.update(order: order)

            onCompletion?(nil)
        }
    }

    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        viewModel.syncTracking(onCompletion: onCompletion)
    }

    func syncNotes(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncNotes(onCompletion: onCompletion)
    }

    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncProducts(onCompletion: onCompletion)
    }

    func syncRefunds(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncRefunds(onCompletion: onCompletion)
    }

    func deleteTracking(_ tracking: ShipmentTracking) {
        let order = viewModel.order
        viewModel.deleteTracking(tracking) { [weak self] error in
            if let _ = error {
                self?.displayDeleteErrorNotice(order: order, tracking: tracking)
                return
            }

            self?.reloadSections()
        }
    }
}


// MARK: - Actions
//
private extension OrderDetailsViewController {

    func handleCellAction(_ type: OrderDetailsDataSource.CellActionType, at indexPath: IndexPath?) {
        switch type {
        case .fulfill:
            fulfillWasPressed()
        case .summary:
            displayOrderStatusList()
        case .tracking:
            guard let indexPath = indexPath else {
                break
            }
            trackingWasPressed(at: indexPath)
        }
    }

    func fulfillWasPressed() {
        ServiceLocator.analytics.track(.orderDetailFulfillButtonTapped)
        let fulfillViewController = FulfillViewController(order: viewModel.order, products: viewModel.products)
        navigationController?.pushViewController(fulfillViewController, animated: true)
    }

    func trackingWasPressed(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderTrackingTableViewCell else {
            return
        }

        displayShipmentTrackingAlert(from: cell, indexPath: indexPath)
    }

    func openTrackingDetails(_ tracking: ShipmentTracking) {
        guard let trackingURL = tracking.trackingURL?.addHTTPSSchemeIfNecessary(),
            let url = URL(string: trackingURL) else {
            return
        }

        ServiceLocator.analytics.track(.orderDetailTrackPackageButtonTapped)
        displayWebView(url: url)
    }

    func displayWebView(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension OrderDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tableView(tableView, in: self, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.dataSource.checkIfCopyingIsAllowed(for: indexPath) else {
            // Only allow the leading swipe action on the address rows
            return UISwipeActionsConfiguration(actions: [])
        }

        let copyActionTitle = NSLocalizedString("Copy", comment: "Copy address text button title — should be one word and as short as possible.")
        let copyAction = UIContextualAction(style: .normal, title: copyActionTitle) { [weak self] (action, view, success) in
            self?.viewModel.dataSource.copyText(at: indexPath)
            success(true)
        }
        copyAction.backgroundColor = .primary

        return UISwipeActionsConfiguration(actions: [copyAction])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // No trailing action on any cell
        return UISwipeActionsConfiguration(actions: [])
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return viewModel.dataSource.checkIfCopyingIsAllowed(for: indexPath)
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        guard action == #selector(copy(_:)) else {
            return
        }

        viewModel.dataSource.copyText(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Remove the first header
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.dataSource.viewForHeaderInSection(section, tableView: tableView)
    }
}


// MARK: - Segues
//
extension OrderDetailsViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productListViewController = segue.destination as? ProductListViewController {
            productListViewController.viewModel = viewModel
            productListViewController.products = viewModel.products
        }
    }
}


// MARK: - Trackings alert
// Track / delete tracking alert
private extension OrderDetailsViewController {
    /// Displays an alert that offers deleting a shipment tracking or opening
    /// it in a webview
    ///

    func displayShipmentTrackingAlert(from sourceView: UIView, indexPath: IndexPath) {
        guard let tracking = viewModel.dataSource.orderTracking(at: indexPath) else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(TrackingAction.dismiss)

        actionSheet.addDefaultActionWithTitle(TrackingAction.copyTrackingNumber) { [weak self] _ in
            self?.viewModel.dataSource.copyText(at: indexPath)
        }

        if tracking.trackingURL?.isEmpty == false {
            actionSheet.addDefaultActionWithTitle(TrackingAction.trackShipment) { [weak self] _ in
                self?.openTrackingDetails(tracking)
            }
        }

        actionSheet.addDestructiveActionWithTitle(TrackingAction.deleteTracking) { [weak self] _ in
            ServiceLocator.analytics.track(.orderDetailTrackingDeleteButtonTapped)
            self?.deleteTracking(tracking)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)
    }
}


// MARK: - Present Order Status List
//
private extension OrderDetailsViewController {
    private func displayOrderStatusList() {
        ServiceLocator.analytics.track(.orderDetailOrderStatusEditButtonTapped,
                                  withProperties: ["status": viewModel.order.statusKey])
        let statusList = OrderStatusListViewController(order: viewModel.order, currentStatus: viewModel.orderStatus)
        let navigationController = UINavigationController(rootViewController: statusList)

        present(navigationController, animated: true)
    }
}


// MARK: - Constants
//
private extension OrderDetailsViewController {

    enum TrackingAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the shipment tracking action sheet")
        static let copyTrackingNumber = NSLocalizedString("Copy Tracking Number", comment: "Copy tracking number button title")
        static let trackShipment = NSLocalizedString("Track Shipment", comment: "Track shipment button title")
        static let deleteTracking = NSLocalizedString("Delete Tracking", comment: "Delete tracking button title")
    }

    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}

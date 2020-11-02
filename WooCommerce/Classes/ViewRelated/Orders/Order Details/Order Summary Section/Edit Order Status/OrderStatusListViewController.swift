import UIKit
import Yosemite

import class AutomatticTracks.CrashLogging

final class OrderStatusListViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) OrderStatuses in sync.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld && slug != %@",
                                    siteID,
                                    OrderStatusEnum.refunded.rawValue)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// The status selected
    ///
    private var selectedStatus: OrderStatus? {
        didSet {
            activateApplyButton()
        }
    }

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Order to be provided with a new status
    ///
    private let order: Order
    private let siteID: Int64

    init(order: Order, currentStatus: OrderStatus?) {
        self.order = order
        self.siteID = order.siteID
        self.selectedStatus = currentStatus
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        configureNavigationBar()
        configureTableView()

        configureResultsController()

        preselectStatusIfPossible()
    }

    /// Setup: Results Controller
    ///
    private func configureResultsController() {
        statusResultsController.startForwardingEvents(to: tableView)

        do {
            try statusResultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }

        tableView.reloadData()
    }

    private func preselectStatusIfPossible() {
        if let selectedStatus = selectedStatus,
            let index = statusResultsController.fetchedObjects.firstIndex(of: selectedStatus) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }

    /// Registers all of the available TableViewCells
    ///
    private func registerTableViewCells() {
        tableView.registerNib(for: StatusListTableViewCell.self)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl

        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        reload {
            sender.endRefreshing()
        }
    }

    private func reload(completion: () -> Void) {
        configureResultsController()
        completion()
    }
}

// MARK: - Navigation bar
//
extension OrderStatusListViewController {
    func configureNavigationBar() {
        configureNavigationBarStyle()
        configureTitle()
        configureLeftButton()
        configureRightButton()
    }

    func configureNavigationBarStyle() {
        navigationController?.navigationBar.barStyle = .black
    }

    func configureTitle() {
        title = NSLocalizedString("Order Status", comment: "Change order status screen - Screen title")
    }

    func configureLeftButton() {
        let dismissButtonTitle = NSLocalizedString("Cancel",
                                                   comment: "Change order status screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Apply",
                                               comment: "Change order status screen - button title to apply selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(applyButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        deActivateApplyButton()
    }

    func activateApplyButton() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func deActivateApplyButton() {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func applyButtonTapped() {
        updateOrderStatus()
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - Update the Order status
//
private extension OrderStatusListViewController {
    /// Dispatches an Action to update the order status
    ///
    private func updateOrderStatus() {
        guard let newStatus = selectedStatus?.status else {
            return
        }

        let orderID = order.orderID
        let undoStatus = order.status

        let done = updateOrderAction(siteID: order.siteID, orderID: orderID, status: newStatus)
        let undo = updateOrderAction(siteID: order.siteID, orderID: orderID, status: undoStatus)

        ServiceLocator.stores.dispatch(done)
        ServiceLocator.analytics.track(.orderStatusChange,
                                  withProperties: ["id": orderID,
                                                   "from": undoStatus.rawValue,
                                                   "to": newStatus.rawValue])

        displayOrderUpdatedNotice {
            ServiceLocator.stores.dispatch(undo)
            ServiceLocator.analytics.track(.orderStatusChange,
                                      withProperties: ["id": orderID,
                                                       "from": newStatus.rawValue,
                                                       "to": undoStatus.rawValue])
        }
    }

    /// Returns an Order Update Action that will result in the specified Order Status updated accordingly.
    ///
    private func updateOrderAction(siteID: Int64, orderID: Int64, status: OrderStatusEnum) -> Action {
        return OrderAction.updateOrder(siteID: siteID, orderID: orderID, status: status, onCompletion: { error in
            guard let error = error else {
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                ServiceLocator.analytics.track(.orderStatusChangeSuccess)
                return
            }

            ServiceLocator.analytics.track(.orderStatusChangeFailed, withError: error)
            DDLogError("⛔️ Order Update Failure: [\(orderID).status = \(status)]. Error: \(error)")

            self.displayErrorNotice(orderID: orderID)
        })
    }
}


// MARK: - UITableViewDatasource conformance
//
extension OrderStatusListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return statusResultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusResultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(StatusListTableViewCell.self, for: indexPath)

        let status = statusResultsController.object(at: indexPath)
        cell.textLabel?.text = status.name
        cell.selectionStyle = .none

        return cell
    }
}


// MARK: - UITableViewDelegate conformance
//
extension OrderStatusListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedStatus = statusResultsController.object(at: indexPath)
    }
}


// MARK: - Error handling
//
extension OrderStatusListViewController {
    /// Displays the `Order Updated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    private func displayOrderUpdatedNotice(onUndoAction: @escaping () -> Void) {
        let message = NSLocalizedString("Order status updated", comment: "Order status update success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Unable to Change Status of Order` Notice.
    ///
    func displayErrorNotice(orderID: Int64) {
        let title = NSLocalizedString(
            "Unable to change status of order #\(orderID)",
            comment: "Content of error presented when updating the status of an Order fails. It reads: Unable to change status of order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.applyButtonTapped()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

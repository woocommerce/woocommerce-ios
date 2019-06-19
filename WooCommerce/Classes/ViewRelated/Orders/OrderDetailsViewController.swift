import UIKit
import Gridicons
import Contacts
import MessageUI
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

    /// Indicates if the Billing details should be rendered.
    ///
    private var displaysBillingDetails = false {
        didSet {
            viewModel.displaysBillingDetails = displaysBillingDetails
            reloadSections()
        }
    }

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager, readOnlyEntity: viewModel.order)
    }()

    /// Order to be rendered!
    ///
    var viewModel: OrderDetailsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        prepareViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncNotes()
        syncProducts()
        syncTrackingsHidingAddButtonIfNecessary()
    }

    private func syncTrackingsHidingAddButtonIfNecessary() {
        syncTracking { [weak self] error in
            if error == nil {
                self?.viewModel.trackingIsReachable = true
            }

            self?.reloadSections()
            self?.tableView.reloadData()
        }
    }
}


// MARK: - TableView Configuration
//
private extension OrderDetailsViewController {

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedSectionFooterHeight = Constants.rowHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
    }

    /// Setup: Navigation
    ///
    func configureNavigation() {
        title = NSLocalizedString("Order #\(viewModel.order.number)", comment: "Order number title")

        // Don't show the Order details title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] order in
            guard let self = self else {
                return
            }

            let orderStatus = self.viewModel.lookUpOrderStatus(for: order)
            self.viewModel = OrderDetailsViewModel(order: order, orderStatus: orderStatus)
        }

        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayOrderDeletedNotice()
        }
    }

    private func prepareViewModel() {
        viewModel.onUIReloadRequired = { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        viewModel.configureResultsControllers { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        viewModel.onCellAction = {[weak self] (actionType, indexPath) in
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
    func displayOrderDeletedNotice() {
        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Order %@ has been deleted from your store",
                comment: "Displayed whenever the Details for an Order that just got deleted was onscreen. It reads: Order {order number} has been deleted from your store."
            ),
            viewModel.order.number
        )

        let notice = Notice(title: message, feedbackType: .error)
        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Action Handlers
//
extension OrderDetailsViewController {

    @objc func pullToRefresh() {
        WooAnalytics.shared.track(.orderDetailPulledToRefresh)
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncProducts() { _ in
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
            self?.refreshControl.endRefreshing()
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrderDetailsViewController {
    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        let action = OrderAction.retrieveOrder(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID) { [weak self] (order, error) in
            guard let self = self, let order = order else {
                DDLogError("⛔️ Error synchronizing Order: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            let orderStatus = self.viewModel.lookUpOrderStatus(for: order)
            self.viewModel = OrderDetailsViewModel(order: order, orderStatus: orderStatus)
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        let orderID = viewModel.order.orderID
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: viewModel.order.siteID,
                                                                    orderID: orderID) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing tracking: \(error.localizedDescription)")
                onCompletion?(error)
                return
            }

            WooAnalytics.shared.track(.orderTrackingLoaded, withProperties: ["id": orderID])
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncNotes(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncNotes(onCompletion: onCompletion)
    }

    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.requestMissingProducts(for: viewModel.order) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing Products: \(error)")
                onCompletion?(error)

                return
            }

            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func deleteTracking(_ tracking: ShipmentTracking) {
        let siteID = viewModel.order.siteID
        let orderID = viewModel.order.orderID
        let trackingID = tracking.trackingID

        let statusKey = viewModel.order.statusKey
        let providerName = tracking.trackingProvider ?? ""

        WooAnalytics.shared.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                         "status": statusKey,
                                                                         "carrier": providerName,
                                                                         "source": "order_detail"])

        let deleteTrackingAction = ShipmentAction.deleteTracking(siteID: siteID,
                                                                 orderID: orderID,
                                                                 trackingID: trackingID) { [weak self] error in
                                                                    if let error = error {
                                                                        DDLogError("⛔️ Order Details - Delete Tracking: orderID \(orderID). Error: \(error)")

                                                                        WooAnalytics.shared.track(.orderTrackingDeleteFailed,
                                                                                                  withError: error)
                                                                        self?.displayDeleteErrorNotice(orderID: orderID, tracking: tracking)
                                                                        return
                                                                    }

                                                                    WooAnalytics.shared.track(.orderTrackingDeleteSuccess)
                                                                    self?.reloadSections()

        }

        StoresManager.shared.dispatch(deleteTrackingAction)
    }
}


// MARK: - Actions
//
private extension OrderDetailsViewController {

    func toggleBillingFooter() {
        displaysBillingDetails = !displaysBillingDetails
        if displaysBillingDetails {
            WooAnalytics.shared.track(.orderDetailShowBillingTapped)
        } else {
            WooAnalytics.shared.track(.orderDetailHideBillingTapped)
        }
    }

    func handleCellAction(_ type: OrderDetailsViewModel.CellActionType, at indexPath: IndexPath?) {
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
        case .footer:
            toggleBillingFooter()
        }
    }

    func fulfillWasPressed() {
        WooAnalytics.shared.track(.orderDetailFulfillButtonTapped)
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

        WooAnalytics.shared.track(.orderDetailTrackPackageButtonTapped)
        displayWebView(url: url)
    }

    func displayWebView(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrderDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections(in: tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return viewModel.tableView(tableView, cellForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.tableView(tableView, heightForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.tableView(tableView, viewForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.tableView(tableView, heightForFooterInSection: section)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewModel.tableView(tableView, viewForFooterInSection: section)
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrderDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch viewModel.sections[indexPath.section].rows[indexPath.row] {

        case .addOrderNote:
            WooAnalytics.shared.track(.orderDetailAddNoteButtonTapped)

            let newNoteViewController = NewNoteViewController()
            newNoteViewController.viewModel = viewModel

            let navController = WooNavigationController(rootViewController: newNoteViewController)
            present(navController, animated: true, completion: nil)
        case .trackingAdd:
            WooAnalytics.shared.track(.orderDetailAddTrackingButtonTapped)

            let addTrackingViewModel = AddTrackingViewModel(order: viewModel.order)
            let addTracking = ManualTrackingViewController(viewModel: addTrackingViewModel)
            let navController = WooNavigationController(rootViewController: addTracking)
            present(navController, animated: true, completion: nil)
        case .orderItem:
            let item = viewModel.order.items[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: viewModel.order.siteID)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            present(navController, animated: true, completion: nil)
        case .details:
            WooAnalytics.shared.track(.orderDetailProductDetailTapped)
            performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        case .billingEmail:
            WooAnalytics.shared.track(.orderDetailCustomerEmailTapped)
            displayEmailComposerIfPossible()
        case .billingPhone:
            displayContactCustomerAlert(from: view)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.checkIfCopyingIsAllowed(for: indexPath) else {
            // Only allow the leading swipe action on the address rows
            return UISwipeActionsConfiguration(actions: [])
        }

        let copyActionTitle = NSLocalizedString("Copy", comment: "Copy address text button title — should be one word and as short as possible.")
        let copyAction = UIContextualAction(style: .normal, title: copyActionTitle) { [weak self] (action, view, success) in
            self?.viewModel.copyText(at: indexPath)
            success(true)
        }
        copyAction.backgroundColor = StyleManager.wooCommerceBrandColor

        return UISwipeActionsConfiguration(actions: [copyAction])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // No trailing action on any cell
        return UISwipeActionsConfiguration(actions: [])
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return viewModel.checkIfCopyingIsAllowed(for: indexPath)
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        guard action == #selector(copy(_:)) else {
            return
        }

        viewModel.copyText(at: indexPath)
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
        guard let tracking = viewModel.orderTracking(at: indexPath) else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(TrackingAction.dismiss)

        if tracking.trackingURL?.isEmpty == false {
            actionSheet.addDefaultActionWithTitle(TrackingAction.trackShipment) { [weak self] _ in
                self?.openTrackingDetails(tracking)
            }
        }

        actionSheet.addDestructiveActionWithTitle(TrackingAction.deleteTracking) { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailTrackingDeleteButtonTapped)
            self?.deleteTracking(tracking)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)
    }
}


// MARK: - Contact Alert
//
private extension OrderDetailsViewController {

    /// Displays an alert that offers several contact methods to reach the customer: [Phone / Message]
    ///
    func displayContactCustomerAlert(from sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(ContactAction.dismiss)
        actionSheet.addDefaultActionWithTitle(ContactAction.call) { [weak self] _ in
            guard let phoneURL = self?.viewModel.order.billingAddress?.cleanedPhoneNumberAsActionableURL else {
                return
            }

            WooAnalytics.shared.track(.orderDetailCustomerPhoneOptionTapped)
            self?.callCustomerIfPossible(at: phoneURL)
        }

        actionSheet.addDefaultActionWithTitle(ContactAction.message) { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailCustomerSMSOptionTapped)
            self?.displayMessageComposerIfPossible()
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)

        WooAnalytics.shared.track(.orderDetailCustomerPhoneMenuTapped)
    }

    /// Attempts to perform a phone call at the specified URL
    ///
    func callCustomerIfPossible(at phoneURL: URL) {
        guard UIApplication.shared.canOpenURL(phoneURL) else {
            return
        }

        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": self.viewModel.order.orderID,
                                                                        "status": self.viewModel.order.statusKey,
                                                                        "type": "call"])

    }
}


// MARK: - Present Order Status List
//
private extension OrderDetailsViewController {
    private func displayOrderStatusList() {
        WooAnalytics.shared.track(.orderDetailOrderStatusEditButtonTapped,
                                  withProperties: ["status": viewModel.order.statusKey])
        let statusList = OrderStatusListViewController(order: viewModel.order)
        let navigationController = UINavigationController(rootViewController: statusList)

        present(navigationController, animated: true)
    }
}


// MARK: - MFMessageComposeViewControllerDelegate Conformance
//
extension OrderDetailsViewController: MFMessageComposeViewControllerDelegate {
    func displayMessageComposerIfPossible() {
        guard let phoneNumber = viewModel.order.billingAddress?.cleanedPhoneNumber,
            MFMessageComposeViewController.canSendText()
            else {
                return
        }

        displayMessageComposer(for: phoneNumber)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                        "status": viewModel.order.statusKey,
                                                                        "type": "sms"])
    }

    private func displayMessageComposer(for phoneNumber: String) {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - MFMailComposeViewControllerDelegate Conformance
//
extension OrderDetailsViewController: MFMailComposeViewControllerDelegate {
    func displayEmailComposerIfPossible() {
        guard let email = viewModel.order.billingAddress?.email, MFMailComposeViewController.canSendMail() else {
            return
        }

        displayEmailComposer(for: email)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                        "status": viewModel.order.statusKey,
                                                                        "type": "email"])
    }

    private func displayEmailComposer(for email: String) {
        // Workaround: MFMailCompose isn't *FULLY* picking up UINavigationBar's WC's appearance. Title / Buttons look awful.
        // We're falling back to iOS's default appearance
        UINavigationBar.applyDefaultAppearance()

        // Composer
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.mailComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        // Workaround: Restore WC's navBar appearance
        UINavigationBar.applyWooAppearance()
    }
}


// MARK: - Error notice
private extension OrderDetailsViewController {
    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(orderID: Int, tracking: ShipmentTracking) {
        let title = NSLocalizedString(
            "Unable to delete tracking for order #\(orderID)",
            comment: "Content of error presented when Delete Shipment Tracking Action Failed. It reads: Unable to delete tracking for order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: actionTitle) { [weak self] in
                                self?.deleteTracking(tracking)
        }

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Constants
//
private extension OrderDetailsViewController {

    enum ContactAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let call = NSLocalizedString("Call", comment: "Call phone number button title")
        static let message = NSLocalizedString("Message", comment: "Message phone number button title")
    }

    enum TrackingAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the shipment tracking action sheet")
        static let trackShipment = NSLocalizedString("Track Shipment", comment: "Track shipment button title")
        static let deleteTracking = NSLocalizedString("Delete Tracking", comment: "Delete tracking button title")
    }

    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
        static let productDetailsSegue = "ShowProductListViewController"
        static let orderStatusListSegue = "ShowOrderStatusListViewController"
    }
}

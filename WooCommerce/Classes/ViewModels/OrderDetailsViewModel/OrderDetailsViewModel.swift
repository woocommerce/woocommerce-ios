import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI

final class OrderDetailsViewModel {
    let order: Order
    let orderStatus: OrderStatus?
    //let currencyFormatter = CurrencyFormatter()
    //let couponLines: [OrderCouponLine]?

    init(order: Order, orderStatus: OrderStatus? = nil) {
        self.order = order
        self.orderStatus = orderStatus
        //self.couponLines = order.coupons
    }

    var summaryTitle: String? {
        return dataSource.summaryTitle
    }

    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")

    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

    /// Anything above 999.99 or below -999.99 should display a truncated amount
    ///
    var totalFriendlyString: String? {
        return dataSource.totalFriendlyString
    }


    // MARK: - Results controllers
    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Product ResultsController.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Products from an Order
    ///
    var products: [Product] {
        return productResultsController.fetchedObjects
    }

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) OrderStatuses in sync.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        return dataSource.lookUpOrderStatus(for: order)
    }

    func lookUpProduct(by productID: Int) -> Product? {
        return dataSource.lookUpProduct(by: productID)
    }

    /// Indicates if we consider the shipment tracking plugin as reachable
    /// https://github.com/woocommerce/woocommerce-ios/issues/852#issuecomment-482308373
    ///
    var trackingIsReachable: Bool = false {
        didSet {
            dataSource.trackingIsReachable = trackingIsReachable
        }
    }

    var displaysBillingDetails: Bool {
        set {
            dataSource.displaysBillingDetails = newValue
        }
        get {
            return dataSource.displaysBillingDetails
        }
    }

    lazy var dataSource: OrderDetailsDataSource = {
        return OrderDetailsDataSource(order: self.order)
    }()

    /// Order Notes
    ///
    var orderNotes: [OrderNote] = [] {
        didSet {
            dataSource.orderNotes = orderNotes
            onUIReloadRequired?()
        }
    }

    var onUIReloadRequired: (() -> Void)?

    var onCellAction: ((OrderDetailsDataSource.CellActionType, IndexPath?) -> Void)? {
        didSet {
            dataSource.onCellAction = onCellAction
        }
    }

    private let emailComposer = OrderEmailComposer()

    private let messageComposer = OrderMessgeComposer()
}


extension OrderDetailsViewModel {
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureTrackingResultsController(onReload: onReload)
        configureProductResultsController(onReload: onReload)
        configureStatusResultsController()
    }

    private func configureTrackingResultsController(onReload: @escaping () -> Void) {
        trackingResultsController.onDidChangeContent = { [weak self] in
            self?.dataSource.orderTracking = self?.trackingResultsController.fetchedObjects ?? []
            onReload()
        }

        trackingResultsController.onDidResetContent = { [weak self] in
            self?.dataSource.orderTracking = self?.trackingResultsController.fetchedObjects ?? []
            onReload()
        }

        try? trackingResultsController.performFetch()
    }

    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = { [weak self] in
            self?.dataSource.products = self?.productResultsController.fetchedObjects ?? []
            onReload()
        }

        productResultsController.onDidResetContent = {[weak self] in
            self?.dataSource.products = self?.productResultsController.fetchedObjects ?? []
            onReload()
        }

        try? productResultsController.performFetch()
    }

    private func configureStatusResultsController() {
        statusResultsController.onDidChangeContent = { [weak self] in
            self?.dataSource.currentSiteStatuses = self?.statusResultsController.fetchedObjects ?? []
        }

        statusResultsController.onDidResetContent = { [weak self] in
            self?.dataSource.currentSiteStatuses = self?.statusResultsController.fetchedObjects ?? []
        }

        try? statusResultsController.performFetch()
    }
}


extension OrderDetailsViewModel {
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        let cells = [
            LeftImageTableViewCell.self,
            CustomerNoteTableViewCell.self,
            CustomerInfoTableViewCell.self,
            WooBasicTableViewCell.self,
            OrderNoteTableViewCell.self,
            PaymentTableViewCell.self,
            ProductDetailsTableViewCell.self,
            OrderTrackingTableViewCell.self,
            SummaryTableViewCell.self,
            FulfillButtonTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self,
            ShowHideSectionFooter.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


extension OrderDetailsViewModel {
    func reloadSections() {
        dataSource.reloadSections()
    }
}


extension OrderDetailsViewModel {
    func tableView(_ tableView: UITableView,
                   in viewController: UIViewController,
                   didSelectRowAt indexPath: IndexPath) {
        switch dataSource.sections[indexPath.section].rows[indexPath.row] {

        case .addOrderNote:
            WooAnalytics.shared.track(.orderDetailAddNoteButtonTapped)

            let newNoteViewController = NewNoteViewController()
            newNoteViewController.viewModel = self

            let navController = WooNavigationController(rootViewController: newNoteViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .trackingAdd:
            WooAnalytics.shared.track(.orderDetailAddTrackingButtonTapped)

            let addTrackingViewModel = AddTrackingViewModel(order: order)
            let addTracking = ManualTrackingViewController(viewModel: addTrackingViewModel)
            let navController = WooNavigationController(rootViewController: addTracking)
            viewController.present(navController, animated: true, completion: nil)
        case .orderItem:
            let item = order.items[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: order.siteID)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .details:
            WooAnalytics.shared.track(.orderDetailProductDetailTapped)
            viewController.performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        case .billingEmail:
            WooAnalytics.shared.track(.orderDetailCustomerEmailTapped)
            displayEmailComposerIfPossible(from: viewController)
        case .billingPhone:
            displayContactCustomerAlert(from: viewController)
        default:
            break
        }
    }
}


// MARK: - MFMailComposeViewControllerDelegate Conformance
//
private extension OrderDetailsViewModel {
    func displayEmailComposerIfPossible(from: UIViewController) {
        emailComposer.displayEmailComposerIfPossible(for: order, from: from)
    }

    /// Displays an alert that offers several contact methods to reach the customer: [Phone / Message]
    ///
    func displayContactCustomerAlert(from: UIViewController) {
        guard let sourceView = from.view else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(ContactAction.dismiss)
        actionSheet.addDefaultActionWithTitle(ContactAction.call) { [weak self] _ in
            guard let self = self else {
                return
            }

            guard let phoneURL = self.order.billingAddress?.cleanedPhoneNumberAsActionableURL else {
                return
            }

            WooAnalytics.shared.track(.orderDetailCustomerPhoneOptionTapped)
            self.callCustomerIfPossible(at: phoneURL)
        }

        actionSheet.addDefaultActionWithTitle(ContactAction.message) { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailCustomerSMSOptionTapped)
            self?.displayMessageComposerIfPossible(from: from)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        from.present(actionSheet, animated: true)

        WooAnalytics.shared.track(.orderDetailCustomerPhoneMenuTapped)
    }

    /// Attempts to perform a phone call at the specified URL
    ///
    func callCustomerIfPossible(at phoneURL: URL) {
        guard UIApplication.shared.canOpenURL(phoneURL) else {
            return
        }

        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": order.orderID,
                                                                        "status": self.order.statusKey,
                                                                        "type": "call"])

    }
}

private extension OrderDetailsViewModel {
    func displayMessageComposerIfPossible(from: UIViewController) {
        messageComposer.displayMessageComposerIfPossible(order: order, from: from)
    }
}


// MARK: - Syning data. Yosemite related stuff
extension OrderDetailsViewModel {
    func syncOrder(onCompletion: ((Order?, Error?) -> ())? = nil) {
        let action = OrderAction.retrieveOrder(siteID: order.siteID, orderID: order.orderID) { (order, error) in
            guard let _ = order else {
                DDLogError("⛔️ Error synchronizing Order: \(error.debugDescription)")
                onCompletion?(nil, error)
                return
            }

            onCompletion?(order, nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        let orderID = order.orderID
        let siteID = order.siteID
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: siteID,
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
        let action = OrderNoteAction.retrieveOrderNotes(siteID: order.siteID, orderID: order.orderID) { [weak self] (orderNotes, error) in
            guard let orderNotes = orderNotes else {
                DDLogError("⛔️ Error synchronizing Order Notes: \(error.debugDescription)")
                self?.orderNotes = []
                onCompletion?(error)

                return
            }

            self?.orderNotes = orderNotes
            WooAnalytics.shared.track(.orderNotesLoaded, withProperties: ["id": self?.order.orderID ?? 0])
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.requestMissingProducts(for: order) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing Products: \(error)")
                onCompletion?(error)

                return
            }

            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func deleteTracking(_ tracking: ShipmentTracking, onCompletion: @escaping (Error?) -> Void) {
        let siteID = order.siteID
        let orderID = order.orderID
        let trackingID = tracking.trackingID

        let statusKey = order.statusKey
        let providerName = tracking.trackingProvider ?? ""

        WooAnalytics.shared.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                         "status": statusKey,
                                                                         "carrier": providerName,
                                                                         "source": "order_detail"])

        let deleteTrackingAction = ShipmentAction.deleteTracking(siteID: siteID,
                                                                 orderID: orderID,
                                                                 trackingID: trackingID) { error in
                                                                    if let error = error {
                                                                        DDLogError("⛔️ Order Details - Delete Tracking: orderID \(orderID). Error: \(error)")

                                                                        WooAnalytics.shared.track(.orderTrackingDeleteFailed,
                                                                                                  withError: error)
                                                                        onCompletion(error)
                                                                        return
                                                                    }

                                                                    WooAnalytics.shared.track(.orderTrackingDeleteSuccess)
                                                                    onCompletion(nil)

        }

        StoresManager.shared.dispatch(deleteTrackingAction)
    }
}

private extension OrderDetailsViewModel {
    enum ContactAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let call = NSLocalizedString("Call", comment: "Call phone number button title")
        static let message = NSLocalizedString("Message", comment: "Message phone number button title")
    }

    enum Constants {
        static let productDetailsSegue = "ShowProductListViewController"
        static let orderStatusListSegue = "ShowOrderStatusListViewController"
    }
}



import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI

final class OrderDetailsViewModel {
    private(set) var order: Order
    var orderStatus: OrderStatus? {
        return lookUpOrderStatus(for: order)
    }

    init(order: Order) {
        self.order = order
    }

    func update(order newOrder: Order) {
        self.order = newOrder
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

    /// Products from an Order
    ///
    var products: [Product] {
        return dataSource.products
    }

    /// Refunds
    ///
    var refunds: [Refund] {
        return dataSource.refunds
    }

    /// Indicates if we consider the shipment tracking plugin as reachable
    /// https://github.com/woocommerce/woocommerce-ios/issues/852#issuecomment-482308373
    ///
    var trackingIsReachable: Bool = false {
        didSet {
            dataSource.trackingIsReachable = trackingIsReachable
        }
    }

    /// The datasource that will be used to render the Order Details screen
    ///
    private(set) lazy var dataSource: OrderDetailsDataSource = {
        return OrderDetailsDataSource(order: self.order)
    }()

    /// Order Notes
    ///
    var orderNotes: [OrderNote] = [] {
        didSet {
            dataSource.orderNotes = orderNotes
            dataSource.reloadSections()
            onUIReloadRequired?()
        }
    }

    /// Closure to be executed when the UI needs to be reloaded.
    /// That could happen, for example, when new incoming data is detected
    ///
    var onUIReloadRequired: (() -> Void)? {
        didSet {
            dataSource.onUIReloadRequired = onUIReloadRequired
        }
    }

    /// Closure to be executed when a cell triggers an action
    ///
    var onCellAction: ((OrderDetailsDataSource.CellActionType, IndexPath?) -> Void)? {
        didSet {
            dataSource.onCellAction = onCellAction
        }
    }

    /// Helpers
    ///

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        return dataSource.lookUpOrderStatus(for: order)
    }

    func lookUpProduct(by productID: Int) -> Product? {
        return dataSource.lookUpProduct(by: productID)
    }

    func lookUpRefund(by refundID: Int) -> Refund? {
        return dataSource.lookUpRefund(by: refundID)
    }
}


// MARK: - Configuring results controllers
//
extension OrderDetailsViewModel {
    func configureResultsControllers(onReload: @escaping () -> Void) {
        dataSource.configureResultsControllers(onReload: onReload)
    }

    func updateOrderStatus(order: Order) {
        update(order: order)
        dataSource.update(order: order)
    }
}


// MARK: - Register table view cells
//
extension OrderDetailsViewModel {
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        let cells = [
            TopLeftImageTableViewCell.self,
            LeftImageTableViewCell.self,
            CustomerNoteTableViewCell.self,
            CustomerInfoTableViewCell.self,
            WooBasicTableViewCell.self,
            OrderNoteHeaderTableViewCell.self,
            OrderNoteTableViewCell.self,
            PaymentTableViewCell.self,
            TwoColumnHeadlineFootnoteTableViewCell.self,
            ProductDetailsTableViewCell.self,
            OrderTrackingTableViewCell.self,
            SummaryTableViewCell.self,
            FulfillButtonTableViewCell.self,
            TwoColumnHeadlineAttributedFootnoteTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self
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
            ServiceLocator.analytics.track(.orderDetailAddNoteButtonTapped)

            let newNoteViewController = NewNoteViewController()
            newNoteViewController.viewModel = self

            let navController = WooNavigationController(rootViewController: newNoteViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .trackingAdd:
            ServiceLocator.analytics.track(.orderDetailAddTrackingButtonTapped)

            let addTrackingViewModel = AddTrackingViewModel(order: order)
            let addTracking = ManualTrackingViewController(viewModel: addTrackingViewModel)
            let navController = WooNavigationController(rootViewController: addTracking)
            viewController.present(navController, animated: true, completion: nil)
        case .orderItem:
            let item = order.items[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: order.siteID,
                                                                   currency: order.currency)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .billingDetail:
            ServiceLocator.analytics.track(.orderDetailShowBillingTapped)
            let billingInformationViewController = BillingInformationViewController(order: order)
            viewController.navigationController?.pushViewController(billingInformationViewController, animated: true)
        case .details:
            ServiceLocator.analytics.track(.orderDetailProductDetailTapped)
            viewController.performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        default:
            break
        }
    }
}


// MARK: - Syncing data. Yosemite related stuff
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

        ServiceLocator.stores.dispatch(action)
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

                                                                        ServiceLocator.analytics.track(.orderTrackingLoaded, withProperties: ["id": orderID])

                                                                        onCompletion?(nil)
        }

        ServiceLocator.stores.dispatch(action)
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
            ServiceLocator.analytics.track(.orderNotesLoaded, withProperties: ["id": self?.order.orderID ?? 0])
            onCompletion?(nil)
        }

        ServiceLocator.stores.dispatch(action)
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

        ServiceLocator.stores.dispatch(action)
    }

    func syncRefunds(onCompletion: ((Error?) -> ())? = nil) {
        let refundIDs = order.refunds.map { $0.refundID }
        let action = RefundAction.retrieveRefunds(siteID: order.siteID, orderID: order.orderID, refundIDs: refundIDs) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing detailed Refunds: \(error)")
                onCompletion?(error)

                return
            }

            onCompletion?(nil)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func deleteTracking(_ tracking: ShipmentTracking, onCompletion: @escaping (Error?) -> Void) {
        let siteID = order.siteID
        let orderID = order.orderID
        let trackingID = tracking.trackingID

        let statusKey = order.statusKey
        let providerName = tracking.trackingProvider ?? ""

        ServiceLocator.analytics.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                         "status": statusKey,
                                                                         "carrier": providerName,
                                                                         "source": "order_detail"])

        let deleteTrackingAction = ShipmentAction.deleteTracking(siteID: siteID,
                                                                 orderID: orderID,
                                                                 trackingID: trackingID) { error in
                                                                    if let error = error {
                                                                        DDLogError("⛔️ Order Details - Delete Tracking: orderID \(orderID). Error: \(error)")

                                                                        ServiceLocator.analytics.track(.orderTrackingDeleteFailed,
                                                                                                  withError: error)
                                                                        onCompletion(error)
                                                                        return
                                                                    }

                                                                    ServiceLocator.analytics.track(.orderTrackingDeleteSuccess)
                                                                    onCompletion(nil)

        }

        ServiceLocator.stores.dispatch(deleteTrackingAction)
    }
}

private extension OrderDetailsViewModel {

    enum Constants {
        static let productDetailsSegue = "ShowProductListViewController"
        static let orderStatusListSegue = "ShowOrderStatusListViewController"
    }
}

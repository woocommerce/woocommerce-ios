import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI

final class OrderDetailsViewModel {
    private let currencyFormatter = CurrencyFormatter()

    private(set) var order: Order

    var orderStatus: OrderStatus? {
        return lookUpOrderStatus(for: order)
    }

    init(order: Order) {
        self.order = order
    }

    func update(order newOrder: Order) {
        self.order = newOrder
        dataSource.update(order: order)
    }

    /// The date displayed on the Orders List.
    ///
    /// The value will only include the year if the `createdDate` is not from the current year.
    ///
    var formattedDateCreated: String {
        let isSameYear = order.dateCreated.isSameYear(as: Date())
        let formatter: DateFormatter = isSameYear ? .monthAndDayFormatter : .mediumLengthLocalizedDateFormatter
        return formatter.string(from: order.dateCreated)
    }

    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")

    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

    /// The localized unabbreviated total which includes the currency.
    ///
    /// Example: $48,415,504.20
    ///
    var totalFriendlyString: String? {
        currencyFormatter.formatAmount(order.total, with: order.currency)
    }

    /// Products from an Order
    ///
    var products: [Product] {
        return dataSource.products
    }

    /// Sorted order items
    ///
    private var items: [OrderItem] {
        return dataSource.items
    }

    /// Refunded products from an Order
    ///
    var refundedItems: [OrderItemRefund] {
        let refunds = dataSource.refunds
        var items = [OrderItemRefund]()
        for refund in refunds {
            items.append(contentsOf: refund.items)
        }

        return items
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
        return OrderDetailsDataSource(order: order)
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

    func lookUpProduct(by productID: Int64) -> Product? {
        return dataSource.lookUpProduct(by: productID)
    }

    func lookUpRefund(by refundID: Int64) -> Refund? {
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
            LedgerTableViewCell.self,
            TwoColumnHeadlineFootnoteTableViewCell.self,
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
            let item = items[indexPath.row]
            let loaderViewController = ProductLoaderViewController(productID: item.productOrVariationID,
                                                                   siteID: order.siteID)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .aggregateOrderItem:
            let item = dataSource.aggregateOrderItems[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: order.siteID)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .billingDetail:
            ServiceLocator.analytics.track(.orderDetailShowBillingTapped)
            let billingInformationViewController = BillingInformationViewController(order: order)
            viewController.navigationController?.pushViewController(billingInformationViewController, animated: true)
        case .details:
            ServiceLocator.analytics.track(.orderDetailProductDetailTapped)
            viewController.performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        case .refund:
            ServiceLocator.analytics.track(.orderDetailRefundDetailTapped)
            guard let refund = dataSource.refund(at: indexPath) else {
                DDLogError("No refund details found.")
                return
            }

            let viewModel = RefundDetailsViewModel(order: order, refund: refund)
            let refundDetailsViewController = RefundDetailsViewController(viewModel: viewModel)
            viewController.navigationController?.pushViewController(refundDetailsViewController, animated: true)
        case .refundedProducts:
            ServiceLocator.analytics.track(.refundedProductsDetailTapped)
            guard let refundedProducts = dataSource.refundedProducts else {
                return
            }
            let viewModel = RefundedProductsViewModel(order: order, refundedProducts: refundedProducts)
            let refundedProductsDetailViewController = RefundedProductsViewController(viewModel: viewModel)
            viewController.navigationController?.pushViewController(refundedProductsDetailViewController, animated: true)
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

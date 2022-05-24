import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI
import Combine
import enum Networking.DotcomError

final class OrderDetailsViewModel {
    /// Retains the use-case so it can perform all of its async tasks.
    ///
    private var collectPaymentsUseCase: CollectOrderPaymentUseCase?

    private let stores: StoresManager

    private(set) var order: Order

    private let cardPresentPaymentsOnboardingPresenter = CardPresentPaymentsOnboardingPresenter()

    var orderStatus: OrderStatus? {
        return lookUpOrderStatus(for: order)
    }

    init(order: Order, stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.stores = stores
    }

    func update(order newOrder: Order) {
        self.order = newOrder
        dataSource.update(order: order)
        editNoteViewModel.update(order: order)
    }

    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")

    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

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

    /// Refunds from an order
    ///
    var refunds: [Refund] {
        return dataSource.refunds
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

    /// IPP Configuration loader
    private lazy var configurationLoader = CardPresentConfigurationLoader(stores: stores)

    /// The datasource that will be used to render the Order Details screen
    ///
    private(set) lazy var dataSource: OrderDetailsDataSource = {
        return OrderDetailsDataSource(order: order,
                                      cardPresentPaymentsConfiguration: configurationLoader.configuration)
    }()

    private(set) lazy var editNoteViewModel: EditCustomerNoteViewModel = {
        return EditCustomerNoteViewModel(order: order)
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

    /// Closure to be executed when the more menu on Products section is tapped.
    ///
    var onProductsMoreMenuTapped: ((_ sourceView: UIView) -> Void)? {
        didSet {
            dataSource.onProductsMoreMenuTapped = onProductsMoreMenuTapped
        }
    }

    /// Closure to be executed when the shipping label more menu is tapped.
    ///
    var onShippingLabelMoreMenuTapped: ((_ shippingLabel: ShippingLabel, _ sourceView: UIView) -> Void)? {
        didSet {
            dataSource.onShippingLabelMoreMenuTapped = onShippingLabelMoreMenuTapped
        }
    }

    /// The customer's email address, if available
    ///
    var customerEmail: String? {
        order.billingAddress?.email
    }


    private var cardPresentPaymentGatewayAccounts: [PaymentGatewayAccount] {
        return dataSource.cardPresentPaymentGatewayAccounts()
    }

    private var receipt: CardPresentReceiptParameters? = nil

    /// Defines if the actions menu item should be shown.
    /// Currently the only action should be to share a payment link.
    ///
    var shouldShowActionsMenuItem: Bool {
        needsPayment && paymentLink != nil
    }

    /// This check is temporary, we are working on knowing if an order needs payment directly from the API.
    /// Conditions copied from:
    /// https://github.com/woocommerce/woocommerce/blob/3611d4643791bad87a0d3e6e73e031bb80447417/plugins/woocommerce/includes/class-wc-order.php#L1520-L1523
    ///
    private var needsPayment: Bool {
        guard let total = Double(order.total) else {
            return false
        }
        return total > .zero && (order.status == .pending || order.status == .failed)
    }

    /// Returns the order payment link.
    /// Should exists on `6.4+` stores.
    ///
    var paymentLink: URL? {
        return order.paymentURL
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
}


// MARK: - Register table view cells
//
extension OrderDetailsViewModel {
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        let cells = [
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
            ButtonTableViewCell.self,
            IssueRefundTableViewCell.self,
            ImageAndTitleAndTextTableViewCell.self
        ]

        for cellClass in cells {
            tableView.registerNib(for: cellClass)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self,
            PrimarySectionHeaderView.self
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
        case .aggregateOrderItem:
            let item = dataSource.aggregateOrderItems[indexPath.row]
            let loaderViewController = ProductLoaderViewController(model: .init(aggregateOrderItem: item),
                                                                   siteID: order.siteID,
                                                                   forceReadOnly: true)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        case .shippingLabelCreationInfo:
            let infoViewController = ShippingLabelCreationInfoViewController()
            let navigationController = WooNavigationController(rootViewController: infoViewController)
            viewController.present(navigationController, animated: true, completion: nil)
        case .shippingLabelDetail:
            guard let shippingLabel = dataSource.shippingLabel(at: indexPath) else {
                return
            }
            let shippingLabelDetailsViewController = ShippingLabelDetailsViewController(shippingLabel: shippingLabel)
            viewController.show(shippingLabelDetailsViewController, sender: viewController)
        case .shippingLabelPrintingInfo:
            let printingInstructionsViewController = ShippingLabelPrintingInstructionsViewController()
            let navigationController = WooNavigationController(rootViewController: printingInstructionsViewController)
            viewController.present(navigationController, animated: true, completion: nil)
        case .shippingLabelProducts:
            let shippingLabelItems = dataSource.shippingLabelOrderItems(at: indexPath)
            let productListVC = AggregatedProductListViewController(viewModel: self, items: shippingLabelItems)
            viewController.show(productListVC, sender: nil)
        case .billingDetail:
            ServiceLocator.analytics.track(.orderDetailShowBillingTapped)
            let billingInformationViewController = BillingInformationViewController(order: order, editingEnabled: true)
            viewController.navigationController?.pushViewController(billingInformationViewController, animated: true)
        case .seeReceipt:
            let countryCode = configurationLoader.configuration.countryCode
            ServiceLocator.analytics.track(event: .InPersonPayments.receiptViewTapped(countryCode: countryCode))
            guard let receipt = receipt else {
                return
            }
            let viewModel = ReceiptViewModel(order: order, receipt: receipt, countryCode: countryCode)
            let receiptViewController = ReceiptViewController(viewModel: viewModel)
            viewController.navigationController?.pushViewController(receiptViewController, animated: true)
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
    /// Dispatches a network call in order to update `self.order`'s `status` to `.completed`.
    func markCompleted() -> OrderFulfillmentUseCase.FulfillmentProcess {
        OrderFulfillmentUseCase(order: order, stores: stores).fulfill()
    }

    func syncOrder(onCompletion: ((Order?, Error?) -> ())? = nil) {
        let action = OrderAction.retrieveOrder(siteID: order.siteID, orderID: order.orderID) { (order, error) in
            guard let _ = order else {
                DDLogError("⛔️ Error synchronizing Order: \(error.debugDescription)")
                onCompletion?(nil, error)
                return
            }

            onCompletion?(order, nil)
        }

        stores.dispatch(action)
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

        stores.dispatch(action)
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

        stores.dispatch(action)
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

        stores.dispatch(action)
    }

    func syncProductVariations(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductVariationAction.requestMissingVariations(for: order) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing missing variations in an Order: \(error)")
                onCompletion?(error)
                return
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }

    func syncRefunds(onCompletion: ((Error?) -> ())? = nil) {
        let refundIDs = order.refunds.map { $0.refundID }
        let action = RefundAction.retrieveRefunds(siteID: order.siteID, orderID: order.orderID, refundIDs: refundIDs, deleteStaleRefunds: true) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing detailed Refunds: \(error)")
                onCompletion?(error)

                return
            }

            onCompletion?(nil)
        }

        stores.dispatch(action)
    }

    func syncShippingLabels(onCompletion: ((Error?) -> ())? = nil) {
        let action = ShippingLabelAction.synchronizeShippingLabels(siteID: order.siteID, orderID: order.orderID) { result in
            switch result {
            case .success:
                ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(result: .success))
                onCompletion?(nil)
            case .failure(let error):
                ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(result: .failed(error: error)))
                if error as? DotcomError == .noRestRoute {
                    DDLogError("⚠️ Endpoint for synchronizing shipping labels is unreachable. WC Shipping plugin may be missing.")
                } else {
                    DDLogError("⛔️ Error synchronizing shipping labels: \(error)")
                }
                onCompletion?(error)
            }
        }
        stores.dispatch(action)
    }

    func syncSavedReceipts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ReceiptAction.loadReceipt(order: order) { [weak self] result in
            switch result {
            case .success(let parameters):
                self?.receipt = parameters
                self?.dataSource.shouldShowReceipts = true
            case .failure:
                self?.dataSource.shouldShowReceipts = false
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }

    func checkShippingLabelCreationEligibility(onCompletion: (() -> Void)? = nil) {
        let action = ShippingLabelAction.checkCreationEligibility(siteID: order.siteID,
                                                                  orderID: order.orderID) { [weak self] isEligible in
            self?.dataSource.isEligibleForShippingLabelCreation = isEligible
            if isEligible, let orderStatus = self?.orderStatus?.status.rawValue {
                ServiceLocator.analytics.track(.shippingLabelOrderIsEligible,
                                               withProperties: ["order_status": orderStatus])
            }
            onCompletion?()
        }
        stores.dispatch(action)
    }

    func refreshCardPresentPaymentEligibility() {
        /// No need for a completion here. The VC will be notified of changes to the stored paymentGatewayAccounts
        /// by the viewModel (after passing up through the dataSource and originating in the resultsControllers)
        ///
        let action = CardPresentPaymentAction.loadAccounts(siteID: order.siteID) {_ in}
        ServiceLocator.stores.dispatch(action)
    }

    func refreshCardPresentPaymentOnboarding() {
        cardPresentPaymentsOnboardingPresenter.refresh()
    }

    func checkOrderAddOnFeatureSwitchState(onCompletion: (() -> Void)? = nil) {
        let action = AppSettingsAction.loadOrderAddOnsSwitchState { [weak self] result in
            self?.dataSource.showAddOns = (try? result.get()) ?? false
            onCompletion?()
        }
        ServiceLocator.stores.dispatch(action)
    }

    func deleteTracking(_ tracking: ShipmentTracking, onCompletion: @escaping (Error?) -> Void) {
        let siteID = order.siteID
        let orderID = order.orderID
        let trackingID = tracking.trackingID

        let status = order.status
        let providerName = tracking.trackingProvider ?? ""

        ServiceLocator.analytics.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                              "status": status.rawValue,
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

        stores.dispatch(deleteTrackingAction)
    }

    /// Collects payments for the current order.
    /// Tries to connect to a reader if necessary.
    /// Checks onboarding status before connecting to a reader.
    /// Handles receipt sharing.
    ///
    func collectPayment(rootViewController: UIViewController, onCollect: @escaping (Result<Void, Error>) -> Void) {
        cardPresentPaymentsOnboardingPresenter.showOnboardingIfRequired(from: rootViewController) { [weak self] in
            guard let self = self else { return }
            guard let paymentGateway = self.cardPresentPaymentGatewayAccounts.first else {
                return DDLogError("⛔️ Payment Gateway not found, can't collect payment.")
            }

            let formattedTotal: String = {
                let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
                let currencyCode = ServiceLocator.currencySettings.currencyCode
                let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
                return currencyFormatter.formatAmount(self.order.total, with: unit) ?? ""
            }()

            self.collectPaymentsUseCase = CollectOrderPaymentUseCase(
                siteID: self.order.siteID,
                order: self.order,
                formattedAmount: formattedTotal,
                paymentGatewayAccount: paymentGateway,
                rootViewController: rootViewController,
                alerts: OrderDetailsPaymentAlerts(transactionType: .collectPayment,
                                                  presentingController: rootViewController),
                configuration: self.configurationLoader.configuration)

            self.collectPaymentsUseCase?.collectPayment(
                onCollect: onCollect,
                onCompleted: { [weak self] in
                    // Make sure we free all the resources
                    self?.collectPaymentsUseCase = nil
                })
        }
    }
}

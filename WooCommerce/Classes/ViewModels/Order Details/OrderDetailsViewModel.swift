import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI
import Combine
import Experiments
import WooFoundation
import SwiftUI
import enum Networking.DotcomError
import protocol Storage.StorageManagerType

final class OrderDetailsViewModel {

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter

    private(set) var order: Order

    /// Defines the current sync states of the view model data.
    ///
    private var syncState: SyncState = .notSynced

    var orderStatus: OrderStatus? {
        return lookUpOrderStatus(for: order)
    }

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.order = order
        self.stores = stores
        self.storageManager = storageManager
        self.currencyFormatter = currencyFormatter
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

    /// If the products for all order items have been loaded, checks if all products are virtual to skip shipping related syncs.
    private var orderContainsOnlyVirtualProducts: Bool {
        let productIDs = order.items.map { $0.productID }
        let orderProducts = productIDs.compactMap { productID -> Product? in
            products.first(where: { $0.productID == productID })
        }
        // Early returns `false` when the products haven't been fully loaded for all order items.
        guard orderProducts.count == productIDs.count else {
            return false
        }
        return orderProducts.allSatisfy { $0.virtual == true }
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

    private var receipt: CardPresentReceiptParameters? = nil

    /// Returns edit action availability given the internal state.
    ///
    var editButtonIsEnabled: Bool {
        syncState == .synced
    }

    var paymentMethodsViewModel: PaymentMethodsViewModel {
        let formattedTotal = currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()
        return PaymentMethodsViewModel(siteID: order.siteID,
                                       orderID: order.orderID,
                                       paymentLink: order.paymentURL,
                                       formattedTotal: formattedTotal,
                                       flow: .orderPayment)
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

// MARK: Syncing
extension OrderDetailsViewModel {
    /// Syncs all data related to the current order.
    ///
    func syncEverything(onReloadSections: (() -> ())? = nil, onCompletion: (() -> ())? = nil) {
        let group = DispatchGroup()

        group.enter()
        syncOrder { [weak self] _ in
            defer {
                group.leave()
            }

            // Products require order.items data, so sync them only after the order is loaded
            guard let self = self else { return }

            group.enter()
            self.syncProducts { [weak self] _ in
                defer {
                    group.leave()
                }
                guard let self else { return }
                ServiceLocator.analytics.track(event: .Orders.orderProductsLoaded(order: self.order,
                                                                                  products: self.products,
                                                                                  addOnGroups: self.dataSource.addOnGroups))
            }

            group.enter()
            self.syncProductVariations { _ in
                group.leave()
            }

            // Refunds require order.refunds data, so sync them only after the order is loaded
            group.enter()
            self.syncRefunds() { _ in
                group.leave()
            }

            // Subscriptions require order.renewalSubscriptionID, so sync them only after the order is loaded
            group.enter()
            self.syncSubscriptions { _ in
                group.leave()
            }
        }

        group.enter()
        Task { @MainActor in
            await syncShippingLabels()
            group.leave()
        }

        group.enter()
        syncNotes { _ in
            group.leave()
        }

        group.enter()
        Task { @MainActor in
            defer {
                group.leave()
            }
            trackingIsReachable = await isShipmentTrackingEnabled()
            guard trackingIsReachable else {
                return
            }
            await syncTrackingsWhenShipmentTrackingIsEnabled()
            onReloadSections?()
        }

        group.enter()
        Task { @MainActor in
            let isEligible = await checkShippingLabelCreationEligibility()
            dataSource.isEligibleForShippingLabelCreation = isEligible
            onReloadSections?()
            group.leave()
        }

        group.enter()
        syncSavedReceipts {_ in
            group.leave()
        }

        group.enter()
        checkOrderAddOnFeatureSwitchState {
            onReloadSections?()
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in

            /// Update state to synced
            ///
            self?.syncState = .synced

            onReloadSections?()
            onCompletion?()
        }
    }

    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        syncOrder { [weak self] (order, error) in
            guard let self = self, let order = order else {
                onCompletion?(error)
                return
            }

            self.update(order: order)

            onCompletion?(nil)
        }
    }

    /// Checks if shipment tracking is enabled for the order.
    /// - Returns: Whether shipment tracking is enabled for the user by checking the products and if the Shipment Tracking plugin is active.
    @MainActor
    func isShipmentTrackingEnabled() async -> Bool {
        guard orderContainsOnlyVirtualProducts == false,
              await isPluginActive(SitePlugin.SupportedPlugin.WCTracking) else {
            return false
        }
        return true
    }

    /// Syncs trackings when shipment tracking is enabled.
    @MainActor
    func syncTrackingsWhenShipmentTrackingIsEnabled() async {
        let orderID = order.orderID
        let siteID = order.siteID
        return await withCheckedContinuation { continuation in
            stores.dispatch(
                ShipmentAction.synchronizeShipmentTrackingData(siteID: siteID,
                                                               orderID: orderID) { error in
                                                                   if let error {
                                                                       DDLogError("⛔️ Error synchronizing tracking: \(error.localizedDescription)")
                                                                       continuation.resume(returning: ())
                                                                       return
                                                                   }

                                                                   ServiceLocator.analytics.track(.orderTrackingLoaded, withProperties: ["id": orderID])

                                                                   continuation.resume(returning: ())
                                                               }
            )
        }
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
            ImageAndTitleAndTextTableViewCell.self,
            WCShipInstallTableViewCell.self,
            OrderSubscriptionTableViewCell.self,
            TitleAndValueTableViewCell.self
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
            let newNoteViewModel = NewNoteViewModel(order: order, orderNotes: dataSource.orderNotes)
            let newNoteViewController = NewNoteViewController(viewModel: newNoteViewModel)
            newNoteViewController.viewModel.onDidFinishEditing = { [weak self] orderNote in
                self?.insertNote(orderNote)
            }

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
                                                                   forceReadOnly: false)
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
        case .customFields:
            ServiceLocator.analytics.track(.orderViewCustomFieldsTapped)
            let customFields = order.customFields.map {
                OrderCustomFieldsViewModel(metadata: $0)
            }
            let customFieldsView = UIHostingController(rootView: OrderCustomFieldsDetails(customFields: customFields))
            viewController.present(customFieldsView, animated: true)
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
        case .installWCShip:
            //TODO: add analytics
            let wcShipInstallationFlowVC = Inject.ViewControllerHost(WCShipCTAHostingController())
            viewController.present(wcShipInstallationFlowVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - Syncing data. Yosemite related stuff

extension OrderDetailsViewModel {
    /// Dispatches a network call in order to update `self.order`'s `status` to `.completed`.
    func markCompleted(flow: WooAnalyticsEvent.Orders.Flow) -> OrderFulfillmentUseCase.FulfillmentProcess {
        OrderFulfillmentUseCase(order: order, stores: stores, flow: flow).fulfill()
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

        // If the order has no refunds, there is no need to sync them.
        guard refundIDs.isNotEmpty else {
            onCompletion?(nil)
            return
        }

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

    @MainActor
    func syncShippingLabels() async {
        guard orderContainsOnlyVirtualProducts == false,
              await isPluginActive(SitePlugin.SupportedPlugin.WCShip) else {
            return
        }
        return await withCheckedContinuation { continuation in
            stores.dispatch(ShippingLabelAction.synchronizeShippingLabels(siteID: order.siteID, orderID: order.orderID) { result in
                switch result {
                    case .success:
                        ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(result: .success))
                        continuation.resume(returning: ())
                    case .failure(let error):
                        ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(result: .failed(error: error)))
                        if error as? DotcomError == .noRestRoute {
                            DDLogError("⚠️ Endpoint for synchronizing shipping labels is unreachable. WC Shipping plugin may be missing.")
                        } else {
                            DDLogError("⛔️ Error synchronizing shipping labels: \(error)")
                        }
                        continuation.resume(returning: ())
                }
            })
        }
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

    func syncSubscriptions(isFeatureFlagEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.readOnlySubscriptions),
                           onCompletion: ((Error?) -> ())? = nil) {
        // Only sync subscriptions if the feature flag is enabled.
        guard isFeatureFlagEnabled else {
            onCompletion?(nil)
            return
        }

        // If the plugin is not active, there is no point in continuing with a request that will fail.
        isPluginActive(SitePlugin.SupportedPlugin.WCSubscriptions) { [weak self] isActive in

            guard let self, isActive else {
                onCompletion?(nil)
                return
            }

            let action = SubscriptionAction.loadSubscriptions(for: self.order) { [weak self] result in
                switch result {
                case .success(let subscriptions):
                    self?.dataSource.orderSubscriptions = subscriptions
                    if subscriptions.isNotEmpty {
                        ServiceLocator.analytics.track(event: .Orders.subscriptionsShown())
                    }
                case .failure(let error):
                    DDLogError("⛔️ Error synchronizing subscriptions: \(error)")
                }
                onCompletion?(nil)
            }
            self.stores.dispatch(action)
        }
    }

    @MainActor
    func checkShippingLabelCreationEligibility() async -> Bool {
        guard orderContainsOnlyVirtualProducts == false,
              await isPluginActive(SitePlugin.SupportedPlugin.WCShip) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            stores.dispatch(ShippingLabelAction.checkCreationEligibility(siteID: order.siteID,
                                                                         orderID: order.orderID) { [weak self] isEligible in
                if isEligible, let orderStatus = self?.orderStatus?.status.rawValue {
                    ServiceLocator.analytics.track(.shippingLabelOrderIsEligible,
                                                   withProperties: ["order_status": orderStatus])
                }
                continuation.resume(returning: isEligible)
            })
        }
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

    /// Helper function that returns `true` in its callback if the provided plugin name is active on the order's store.
    /// Additionally it logs to tracks if the plugin store is accessed without it being in sync so we can handle that edge-case if it happens recurrently.
    ///
    private func isPluginActive(_ plugin: String, completion: @escaping (Bool) -> (Void)) {
        isPluginActive([plugin], completion: completion)
    }

    /// Helper function that returns `true` in its callback if any of the the provided plugin names are active on the order's store.
    /// Additionally it logs to tracks if the plugin store is accessed without it being in sync so we can handle that edge-case if it happens recurrently.
    /// Useful for when a plugin has had many names.
    ///
    private func isPluginActive(_ plugins: [String], completion: @escaping (Bool) -> (Void)) {
        guard arePluginsSynced() else {
            DDLogError("⚠️ SystemPlugins acceded without being in sync.")
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.pluginsNotSyncedYet())
            return completion(false)
        }

        let action = SystemStatusAction.fetchSystemPluginListWithNameList(siteID: order.siteID, systemPluginNameList: plugins) { plugin in
            completion(plugin?.active == true)
        }
        stores.dispatch(action)
    }

    /// Function that checks for any existing system plugin in the order's store.
    /// If there is none, we assume plugins are not synced because at least the`WooCommerce` plugin should be present.
    ///
    private func arePluginsSynced() -> Bool {
        let predicate = NSPredicate(format: "siteID == %lld", order.siteID)
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storageManager, matching: predicate, sortedBy: [])
        try? resultsController.performFetch()
        return !resultsController.isEmpty
    }

    /// Inserts a new note at the top of the collection of existing notes
    ///
    private func insertNote(_ orderNote: OrderNote) {
        orderNotes.insert(orderNote, at: 0)
    }
}

private extension OrderDetailsViewModel {
    @MainActor
    func isPluginActive(_ plugin: String) async -> Bool {
        await withCheckedContinuation { continuation in
            isPluginActive(plugin) { isActive in
                continuation.resume(returning: isActive)
            }
        }
    }
}

// MARK: Definitions
private extension OrderDetailsViewModel {
    /// Defines the possible sync states of the view model data.
    ///
    enum SyncState {
        case notSynced
        case synced
    }
}

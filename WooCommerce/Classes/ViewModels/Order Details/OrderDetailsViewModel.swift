import Foundation
import UIKit
import Gridicons
import Yosemite
import MessageUI
import Combine
import Experiments
import WooFoundation
import WooFoundationCore
import SwiftUI
import enum Networking.DotcomError
import protocol Storage.StorageManagerType

final class OrderDetailsViewModel {

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let pluginsService: PluginsServiceProtocol
    let featureFlagService: FeatureFlagService
    private let ciabEligibilityChecker: CIABEligibilityCheckerProtocol

    private(set) var order: Order

    /// Defines the current sync states of the view model data.
    ///
    private var syncStateController: OrderDetailsSyncStateControlling

    private let receiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol

    var orderStatus: OrderStatus? {
        return lookUpOrderStatus(for: order)
    }

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         syncStateController: OrderDetailsSyncStateControlling = OrderDetailsSyncStateController(syncState: .notSynced),
         receiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol = ReceiptEligibilityUseCase(),
         pluginsService: PluginsServiceProtocol? = nil,
         ciabEligibilityChecker: CIABEligibilityCheckerProtocol = ServiceLocator.ciabEligibilityChecker) {
        self.order = order
        self.stores = stores
        self.storageManager = storageManager
        self.currencyFormatter = currencyFormatter
        self.featureFlagService = featureFlagService
        self.syncStateController = syncStateController
        self.configurationLoader = CardPresentConfigurationLoader(stores: stores)
        self.dataSource = OrderDetailsDataSource(order: order,
                                                 cardPresentPaymentsConfiguration: configurationLoader.configuration)
        self.receiptEligibilityUseCase = receiptEligibilityUseCase
        self.pluginsService = pluginsService ?? PluginsService(storageManager: storageManager)
        self.ciabEligibilityChecker = ciabEligibilityChecker
    }

    func update(order newOrder: Order) {
        self.order = newOrder
        dataSource.update(order: order)
        editNoteViewModel.update(order: order)
    }

    @MainActor
    func refreshReceiptEligibility() async {
        dataSource.isEligibleForBackendReceipt = await isEligibleForBackendReceipt()
    }

    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")

    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

    /// Products from an Order
    ///
    var products: [OrderDetailsProduct] {
        return dataSource.products
    }

    /// If the products for all order items have been loaded, checks if all products are virtual to skip shipping related syncs.
    private var orderContainsOnlyVirtualProducts: Bool {
        let productIDs = order.items.map { $0.productID }
        let orderProducts = productIDs.compactMap { productID -> OrderDetailsProduct? in
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
    private let configurationLoader: CardPresentConfigurationLoader

    /// The datasource that will be used to render the Order Details screen
    ///
    let dataSource: OrderDetailsDataSource

    /// The eligibility check for Woo Shipping can be updated late due to being async
    /// So the additional check for shipments determines if the new form should be displayed.
    var shouldNavigateToNewShippingLabelFlow: Bool {
        dataSource.isEligibleForWooShipping
    }

    private(set) lazy var editNoteViewModel: EditCustomerNoteViewModel = {
        return EditCustomerNoteViewModel(order: order)
    }()

    /// Order Notes
    ///
    var orderNotes: [OrderNote] = [] {
        didSet {
            dataSource.orderNotes = orderNotes
            dataSource.reloadSections()
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
    var editButtonBehaviour: EditButtonBehaviour {
        guard syncStateController.syncState == .synced else {
            return .disabledForSyncing
        }

        guard let orderCurrency = CurrencyCode(caseInsensitiveRawValue: order.currency),
              orderCurrency == ServiceLocator.currencySettings.currencyCode else {
            return .showNoticeForCurrencyConflict
        }

        return .enabled
    }

    enum EditButtonBehaviour {
        case enabled
        case disabledForSyncing
        case showNoticeForCurrencyConflict
    }

    var paymentMethodsViewModel: PaymentMethodsViewModel {
        let formattedTotal = currencyFormatter.formatAmount(order.total, with: order.currency) ?? String()
        let viewModel = PaymentMethodsViewModel(siteID: order.siteID,
                                                orderID: order.orderID,
                                                paymentLink: order.paymentURL,
                                                total: order.total,
                                                formattedTotal: formattedTotal,
                                                flow: .orderPayment,
                                                channel: .storeManagement)
        viewModel.onNoteAdded = { [weak self] note in
            self?.insertNote(note)
        }
        return viewModel
    }

    /// Helpers
    ///
    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        return dataSource.lookUpOrderStatus(for: order)
    }

    func lookUpProduct(by productID: Int64) -> OrderDetailsProduct? {
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
    @MainActor
    func syncEverything(onReloadSections: (() -> ())? = nil, onCompletion: (() -> ())? = nil) {
        let group = DispatchGroup()

        group.enter()
        syncOrder { [weak self] _ in
            defer {
                group.leave()
            }

            // Products require order.items data, so sync them only after the order is loaded
            guard let self else { return }

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

            // Shipping labels need to be synced after the order but before we complete
            // the order sync group to ensure the UI shows the latest data
            group.enter()
            Task { @MainActor [weak self] in
                guard let self else { return}

                // Check Woo Shipping support first, to ensure correct flows are enabled for shipping labels.
                dataSource.isEligibleForWooShipping = await isWooShippingSupported()

                await withTaskGroup(of: Void.self) { taskGroup in

                    taskGroup.addTask { [weak self] in
                        guard let self else { return }
                        // Check creation eligibility
                        let isEligible = await checkShippingLabelCreationEligibility()
                        dataSource.isEligibleForShippingLabelCreation = isEligible
                    }

                    taskGroup.addTask { [weak self] in
                        guard let self else { return }
                        // Sync shipping labels or shipments and update order with the result if available
                        await syncShippingLabelsOrShipments()
                    }
                }

                // Reload UI after shipping labels are synced
                onReloadSections?()
                group.leave()
            }
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
            trackingIsReachable = isShipmentTrackingEnabled()
            guard trackingIsReachable else {
                return
            }
            await syncTrackingsWhenShipmentTrackingIsEnabled()
            onReloadSections?()
        }

        /// Temporary `ciabEligibilityChecker.isCurrentSiteCIAB`
        // TODO: Rework CIAB gating in favour of new approach.
        if ciabEligibilityChecker.isCurrentSiteCIAB {
            group.enter()
            Task { @MainActor in
                defer {
                    group.leave()
                }
                await syncOrderFulfillments()
            }
        }

        group.enter()
        syncSavedReceipts {_ in
            group.leave()
        }

        // Receipt eligibility need to be synced after the order but before we complete the order sync group,
        // otherwise we risk to crash due out of bounds when rendering the rest of the rows that require reloading sections.
        group.enter()
        Task { @MainActor in
            defer {
                group.leave()
            }
            dataSource.isEligibleForBackendReceipt = await isEligibleForBackendReceipt()
        }

        group.enter()
        checkOrderAddOnFeatureSwitchState {
            onReloadSections?()
            group.leave()
        }

        group.enter()
        syncShippingMethods { _ in
            onReloadSections?()
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in

            /// Update state to synced
            ///
            self?.syncStateController.syncState = .synced

            onReloadSections?()
            onCompletion?()
        }
    }

    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        syncOrder { [weak self] (order, error) in
            guard let self, let order else {
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
    func isShipmentTrackingEnabled() -> Bool {
        guard orderContainsOnlyVirtualProducts == false,
              isPluginActive(.wooShipmentTracking) else {
            return false
        }
        return true
    }

    /// Syncs trackings when shipment tracking is enabled.
    @MainActor
    func syncTrackingsWhenShipmentTrackingIsEnabled() async {
        let orderID = order.orderID
        let siteID = order.siteID
        // swiftlint:disable:next return_value_from_void_function
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

    /// Syncs order fulfillments from the fulfillments endpoint.
    @MainActor
    func syncOrderFulfillments() async {
        let orderID = order.orderID
        let siteID = order.siteID
        // swiftlint:disable:next return_value_from_void_function
        return await withCheckedContinuation { continuation in
            stores.dispatch(
                OrderFulfillmentAction.synchronizeOrderFulfillments(
                    siteID: siteID,
                    orderID: orderID
                ) { error in
                    if let error {
                        DDLogError("⛔️ Error synchronizing order fulfillments: \(error.localizedDescription)")
                    }
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
        let cellsWithNib = [
            LargeHeightLeftImageTableViewCell.self,
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
            OrderSubscriptionTableViewCell.self,
            TitleAndValueTableViewCell.self
        ]

        let cellsWithoutNib = [
            HostingConfigurationTableViewCell<ShippingLineRowView>.self,
            HostingConfigurationTableViewCell<OrderDetailsShipmentDetailsView>.self,
        ]

        for cellClass in cellsWithNib {
            tableView.registerNib(for: cellClass)
        }

        for cellClass in cellsWithoutNib {
            tableView.register(cellClass)
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
        case .shippingLabelDetail:
            guard let shippingLabel = dataSource.shippingLabel(at: indexPath) else {
                return
            }
            if dataSource.isEligibleForWooShipping {
                onCellAction?(.openShippingLabelForm(shippingLabel: shippingLabel), indexPath)
            } else {
                let shippingLabelDetailsViewController = ShippingLabelDetailsViewController(shippingLabel: shippingLabel)
                viewController.show(shippingLabelDetailsViewController, sender: viewController)
            }
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
                CustomFieldViewModel(metadata: $0)
            }

            let viewModel = CustomFieldsListViewModel(customFields: customFields, siteID: order.siteID, parentItemID: order.orderID, customFieldType: .order)

            let customFieldsListViewController = CustomFieldsListHostingController(viewModel: viewModel)

            viewController.navigationController?.pushViewController(customFieldsListViewController, animated: true)

        case .seeReceipt:
            let countryCode = configurationLoader.configuration.countryCode
            ServiceLocator.analytics.track(event: .InPersonPayments.receiptViewTapped(countryCode: countryCode, source: .backend))

            guard let cell = tableView.cellForRow(at: indexPath) as? TwoColumnHeadlineFootnoteTableViewCell else {
                return
            }
            cell.startLoading()

            let action = ReceiptAction.retrieveReceipt(order: order) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(receipt):
                    let orderID = self.order.orderID
                    let siteName = stores.sessionManager.defaultSite?.name
                    let receiptViewModel = ReceiptViewModel(receipt: receipt,
                                                            orderID: orderID,
                                                            siteName: siteName)
                    let receiptViewController = ReceiptViewController(viewModel: receiptViewModel)
                    viewController.navigationController?.pushViewController(receiptViewController, animated: true)
                    cell.stopLoading()
                case let .failure(error):
                    ServiceLocator.analytics.track(event: .InPersonPayments.receiptFetchFailed(error: error))
                    self.displayReceiptRetrievalErrorNotice(for: order, with: error, in: viewController)
                    cell.stopLoading()
                }
            }
            ServiceLocator.stores.dispatch(action)
        case .seeLegacyReceipt:
            let countryCode = configurationLoader.configuration.countryCode
            ServiceLocator.analytics.track(event: .InPersonPayments.receiptViewTapped(countryCode: countryCode, source: .local))
            guard let receipt else {
                return
            }
            let viewModel = LegacyReceiptViewModel(order: order, receipt: receipt, countryCode: countryCode)
            let receiptViewController = LegacyReceiptViewController(viewModel: viewModel)
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
        case .trashOrder:
            onCellAction?(.trashOrder, indexPath)
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
            guard let orderNotes else {
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
            if let error {
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
            if let error {
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
            if let error {
                DDLogError("⛔️ Error synchronizing detailed Refunds: \(error)")
                onCompletion?(error)

                return
            }

            onCompletion?(nil)
        }

        stores.dispatch(action)
    }

    @MainActor func syncShippingLabelsOrShipments() async {
        let isRevampedFlow = featureFlagService.isFeatureFlagEnabled(.revampedShippingLabelCreation)
        guard isRevampedFlow else {
            /// old logic for syncing labels
            let shippingLabels: [ShippingLabel] = await {
                if await localRequirementsForShippingLabelsAreFulfilled() {
                    return await syncShippingLabelsForLegacyPlugin(isRevampedFlow: isRevampedFlow)
                }
                return []
            }()
            // Update the order with the newly synced shipping labels
            let updatedOrder = order.copy(shippingLabels: shippingLabels)
            update(order: updatedOrder)
            return
        }

        guard !orderContainsOnlyVirtualProducts else {
            return
        }

        if await isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.WooShipping) {
            syncShipmentsForWooShipping()
        } else if await isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.LegacyWCShip) {
            let shippingLabels =  await syncShippingLabelsForLegacyPlugin(isRevampedFlow: isRevampedFlow)
            // Update the order with the newly synced shipping labels
            let updatedOrder = order.copy(shippingLabels: shippingLabels)
            update(order: updatedOrder)
        }
    }

    func syncSavedReceipts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ReceiptAction.loadReceipt(order: order) { [weak self] result in
            switch result {
            case .success(let parameters):
                self?.receipt = parameters
                self?.dataSource.orderHasLocalReceipt = true
            case .failure:
                self?.dataSource.orderHasLocalReceipt = false
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }

    @MainActor
    func syncSubscriptions(onCompletion: ((Error?) -> ())? = nil) {
        // If the plugin is not active, there is no point in continuing with a request that will fail.
        isPluginActive(.wooSubscriptions) { [weak self] isActive in

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

    func syncShippingMethods(onCompletion: ((Error?) -> ())? = nil) {
        let action = ShippingMethodAction.synchronizeShippingMethods(siteID: order.siteID) { result in
            switch result {
            case .success:
                onCompletion?(nil)
            case let .failure(error):
                DDLogError("⛔️ Error synchronizing shipping methods: \(error)")
                onCompletion?(error)
            }
        }
        stores.dispatch(action)
    }

    @MainActor
    func checkShippingLabelCreationEligibility() async -> Bool {
        let isRevampedFlow = featureFlagService.isFeatureFlagEnabled(.revampedShippingLabelCreation)
        guard isRevampedFlow else {
            if await localRequirementsForShippingLabelsAreFulfilled() {
                return await checkShippingLabelCreationEligibilityForLegacyPlugin(isRevampedFlow: isRevampedFlow)
            }
            return false
        }

        guard !orderContainsOnlyVirtualProducts else {
            return false
        }

        if await isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.WooShipping) {
            return await checkShippingLabelCreationEligibilityForWooShipping()
        } else if await isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.LegacyWCShip) {
            return await checkShippingLabelCreationEligibilityForLegacyPlugin(isRevampedFlow: isRevampedFlow)
        } else {
            return false
        }
    }

    @MainActor
    func localRequirementsForShippingLabelsAreFulfilled() async -> Bool {
        guard !orderContainsOnlyVirtualProducts else {
            return false
        }

        guard await !isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.LegacyWCShip) else {
            return true
        }

        return await isPluginActive(pluginPath: SitePlugin.SupportedPluginPath.WooShipping)
    }

    /// Checks if the Woo Shipping extension is active, with the minimum version required for its shipping label flow.
    ///
    @MainActor
    func isWooShippingSupported() async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.revampedShippingLabelCreation),
              let plugin = await fetchPluginByPath(SitePlugin.SupportedPluginPath.WooShipping) else {
            return false
        }

        let isVersionSupported = VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: Constants.wooShippingMinimumVersion)

        return plugin.active && isVersionSupported
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
                                                                    if let error {
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

    /// Put an order in the trash, without deleting it permanently.
    ///
    func trashOrder(_ onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let action = OrderAction.deleteOrder(siteID: order.siteID, order: order, deletePermanently: false) { result in
            switch result {
            case .success(let order):
                onCompletion(.success(order))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
        stores.dispatch(action)
    }

    /// Helper function that returns `true` in its callback if the provided plugin is active on the order's store.
    /// Additionally it logs to tracks if the plugin store is accessed without it being in sync so we can handle that edge-case if it happens recurrently.
    ///
    @MainActor
    private func isPluginActive(_ plugin: Plugin) -> Bool {
        let plugin = fetchPlugin(plugin, isActive: true)
        return plugin != nil && plugin?.active == true
    }

    /// Legacy helper function that returns plugin active value in a completion closure.
    @MainActor
    private func isPluginActive(_ plugin: Plugin, completion: @escaping (Bool) -> (Void)) {
        completion(isPluginActive(plugin))
    }

    /// Fetches a plugin from storage, based on the provided list of plugin names.
    /// Additionally it logs to tracks if the plugin store is accessed without it being in sync so we can handle that edge-case if it happens recurrently.
    ///
    @MainActor
    private func fetchPlugin(_ plugin: Plugin, isActive: Bool? = nil) -> SystemPlugin? {
        guard arePluginsSynced() else {
            DDLogError("⚠️ SystemPlugins accessed without being in sync.")
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.pluginsNotSyncedYet())
            return nil
        }

        return pluginsService.loadPluginInStorage(siteID: order.siteID, plugin: plugin, isActive: isActive)
    }

    /// Fetches a plugin from storage, based on the provided plugin path.
    /// Additionally it logs to tracks if the plugin store is accessed without it being in sync so we can handle that edge-case if it happens recurrently.
    ///
    @MainActor
    private func fetchPluginByPath(_ path: String) async -> SystemPlugin? {
        guard arePluginsSynced() else {
            DDLogError("⚠️ SystemPlugins accessed without being in sync.")
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.pluginsNotSyncedYet())
            return nil
        }

        return await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.fetchSystemPluginWithPath(siteID: order.siteID, pluginPath: path, onCompletion: { plugin in
                continuation.resume(returning: plugin)
            }))
        }
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

    @MainActor func checkShippingLabelCreationEligibilityForWooShipping() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(WooShippingAction.checkCreationEligibility(siteID: order.siteID,
                                                                         orderID: order.orderID) { [weak self] isEligible in
                self?.handleShippingLabelCreationEligibilityResult(isEligible: isEligible, isRevampedFlow: true)
                continuation.resume(returning: isEligible)
            })
        }
    }

    @MainActor func checkShippingLabelCreationEligibilityForLegacyPlugin(isRevampedFlow: Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(ShippingLabelAction.checkCreationEligibility(siteID: order.siteID,
                                                                         orderID: order.orderID) { [weak self] isEligible in
                self?.handleShippingLabelCreationEligibilityResult(isEligible: isEligible, isRevampedFlow: isRevampedFlow)
                continuation.resume(returning: isEligible)
            })
        }
    }

    func handleShippingLabelCreationEligibilityResult(isEligible: Bool, isRevampedFlow: Bool) {
        if isEligible, let orderStatus = orderStatus?.status.rawValue {
            ServiceLocator.analytics.track(.shippingLabelOrderIsEligible,
                                           withProperties: ["order_status": orderStatus,
                                                            "is_revamped_flow": isRevampedFlow])
        }
    }

    func syncShipmentsForWooShipping() {
        stores.dispatch(WooShippingAction.syncShipments(siteID: order.siteID, orderID: order.orderID) { result in
            switch result {
            case .success:
                ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(
                    result: .success,
                    isRevampedFlow: true
                ))
            case .failure(let error):
                ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(
                    result: .failed(error: error),
                    isRevampedFlow: true
                ))
                DDLogError("⛔️ Error synchronizing shipping labels: \(error)")
            }
        })
    }

    @MainActor func syncShippingLabelsForLegacyPlugin(isRevampedFlow: Bool) async -> [ShippingLabel] {
        await withCheckedContinuation { continuation in
            stores.dispatch(ShippingLabelAction.synchronizeShippingLabels(siteID: order.siteID, orderID: order.orderID) { result in
                switch result {
                case .success(let shippingLabels):
                    ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(
                        result: .success,
                        isRevampedFlow: isRevampedFlow
                    ))
                    continuation.resume(returning: shippingLabels)
                case .failure(let error):
                    ServiceLocator.analytics.track(event: .shippingLabelsAPIRequest(
                        result: .failed(error: error),
                        isRevampedFlow: isRevampedFlow
                    ))
                    DDLogError("⛔️ Error synchronizing shipping labels: \(error)")
                    continuation.resume(returning: [])
                }
            })
        }
    }

    @MainActor
    func isPluginActive(pluginPath: String) async -> Bool {
        let plugin = await fetchPluginByPath(pluginPath)
        return plugin?.active == true
    }
}

extension OrderDetailsViewModel {
    /// Marks the order as pending if the WooCommerce version is eligible to send a receipt after payment.
    /// Orders can be set to failed when payment fails.
    /// We need to set it back to pending order when collecting payment to trigger all the related notifications when payment turns to failed again.
    ///
    func markOrderPaymentPending() {
        guard order.status != .pending else {
            return
        }

        let action = OrderAction.updateOrderStatus(siteID: order.siteID,
                                                   orderID: order.orderID,
                                                   status: .pending, onCompletion: { _ in })
        stores.dispatch(action)
    }

    @MainActor
    private func isEligibleForBackendReceipt() async -> Bool {
        return await withCheckedContinuation { continuation in
            receiptEligibilityUseCase.isEligibleForReceipt(order.status, datePaid: order.datePaid) { isEligible in
                continuation.resume(returning: isEligible)
            }
        }
    }
}

// MARK: - Notices
extension OrderDetailsViewModel {
    private func displayReceiptRetrievalErrorNotice(for order: Order,
                                                    with error: Error?,
                                                    in viewController: UIViewController) {
        let noticePresenter = DefaultNoticePresenter()
        let notice = Notice(title: Localization.failedReceiptRetrievalNoticeText,
                            feedbackType: .error)
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)

        DDLogError("Failed to retrieve receipt for order: \(order.orderID). Site \(order.siteID). Error: \(String(describing: error))")
    }

    func showNoticeForEditingWithCurrencyConflict(in viewController: UIViewController) {
        let siteCurrency = ServiceLocator.currencySettings.currencyCode.rawValue
        let noticePresenter = DefaultNoticePresenter()
        let title = String(format: Localization.editingOrderWithCurrencyConflictNoticeTitle, order.currency, siteCurrency)
        let notice = Notice(title: title,
                            feedbackType: .error)
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)

        DDLogError("Attempt to edit order \(order.orderID) with currency \(order.currency), but did not match site's currency \(siteCurrency).")
    }

    enum Localization {
        static let failedReceiptRetrievalNoticeText = NSLocalizedString(
            "OrderDetailsViewModel.displayReceiptRetrievalErrorNotice.notice",
            value: "Unable to retrieve receipt.",
            comment: "Notice that appears when no receipt can be retrieved upon tapping on 'See receipt' in the Order Details view.")

        static let editingOrderWithCurrencyConflictNoticeTitle = NSLocalizedString(
            "OrderDetailsViewModel.editingOrderWithCurrencyConflictNotice.title",
            value: "Sorry, you can only edit this order on the web, as it uses %1$@, and your site's currency is %2$@.",
            comment: "Title for notice that's shown when trying to edit an order that's in a different currency. " +
            "This action isn't supported in the app. Placeholders: %1$@ is the order currency code (e.g. USD), " +
            "%2$@ is the site currency code (e.g. GBP.)"
        )
    }
}

// MARK: - Constants
private extension OrderDetailsViewModel {
    enum Constants {
        /// Minimum version of Woo Shipping extension required for app support.
        /// This should be updated to 1.0.6 once that version is released.
        static let wooShippingMinimumVersion = "1.0.5"
    }
}
